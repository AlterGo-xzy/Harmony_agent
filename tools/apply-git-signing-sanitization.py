"""Apply the explicitly approved one-ref Codex snapshot sanitization plan."""
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import zlib

ROOT = Path(r'D:\Harmony_agent').resolve(strict=True)
GIT = ROOT / '.git'
PREPARATION = ROOT / 'artifacts' / 't08-signed-device-acceptance' / '20261002-195000' / 'git-sanitization'
PLAN = json.loads((PREPARATION / 'plan.json').read_text(encoding='utf-8'))

if PLAN['affectedCodexSnapshotRefs'] != 1 or PLAN['sourceCommitOrTagObjects'] != 0:
    raise RuntimeError('Approved scope changed')
if not PLAN['targetRef'].startswith('refs/codex/turn-diffs/captures/'):
    raise RuntimeError('Target is outside the approved Codex snapshot scope')


def object_path(base: Path, object_id: str) -> Path:
    return base / 'objects' / object_id[:2] / object_id[2:]


def verify_object(path: Path, expected: str) -> bytes:
    raw = zlib.decompress(path.read_bytes())
    if hashlib.sha1(raw).hexdigest() != expected:
        raise RuntimeError('Git object hash mismatch')
    return raw


reference = GIT / PLAN['targetRef']
reference_exists = reference.exists()
if reference_exists and reference.read_text(encoding='utf-8').strip() != PLAN['before']:
    raise RuntimeError('Codex snapshot changed since preparation')
sensitive_raw = verify_object(object_path(GIT, PLAN['sensitiveBlob']), PLAN['sensitiveBlob'])
sensitive_profile = json.loads(sensitive_raw.split(b'\x00', 1)[1].decode('utf-8'))
sensitive_values = []


def collect_sensitive(value, key=''):
    if isinstance(value, str):
        if (key.lower().endswith('password') or key.lower().endswith('pwd')) and value:
            sensitive_values.append(value.encode('utf-8'))
    elif isinstance(value, list):
        for item in value:
            collect_sensitive(item, key)
    elif isinstance(value, dict):
        for child_key, child_value in value.items():
            collect_sensitive(child_value, child_key)


collect_sensitive(sensitive_profile['app']['signingConfigs'])
if not sensitive_values:
    raise RuntimeError('No signing secrets found in the approved sensitive blob')

installed_objects = 0
normalized_refs = 0
if reference_exists:
    for object_id in PLAN['newObjects']:
        source = object_path(PREPARATION, object_id)
        verify_object(source, object_id)
        destination = object_path(GIT, object_id)
        if destination.exists():
            verify_object(destination, object_id)
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(source.read_bytes())
        installed_objects += 1

    transaction = ('start\nupdate {ref} {after} {before}\nprepare\ncommit\n'.format(
        ref=PLAN['targetRef'], after=PLAN['after'], before=PLAN['before'])).encode('utf-8')
    result = subprocess.run(['git', '-C', str(ROOT), 'update-ref', '--stdin'],
                            input=transaction, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError('Atomic ref update failed: ' +
                           result.stderr.decode('utf-8', errors='replace').strip())
    if reference.read_text(encoding='utf-8').strip() != PLAN['after']:
        raise RuntimeError('Updated reference verification failed')
    normalized_refs = 1
else:
    fsck = subprocess.run(['git', '-C', str(ROOT), 'fsck', '--full', '--no-reflogs', '--unreachable'],
                          capture_output=True, text=True)
    unreachable = fsck.stdout + fsck.stderr
    if ('unreachable blob ' + PLAN['sensitiveBlob'] not in unreachable or
            'unreachable tree ' + PLAN['before'] not in unreachable):
        raise RuntimeError('Removed snapshot objects are not both unreachable')
    sensitive_parents = []
    old_root_parents = []
    for prefix in (GIT / 'objects').iterdir():
        if not prefix.is_dir() or len(prefix.name) != 2:
            continue
        for item in prefix.iterdir():
            object_id = prefix.name + item.name
            if len(object_id) != 40:
                continue
            try:
                raw = zlib.decompress(item.read_bytes())
            except (OSError, zlib.error):
                continue
            header, data = raw.split(b'\x00', 1)
            if header.startswith(b'tree '):
                if bytes.fromhex(PLAN['sensitiveBlob']) in data:
                    sensitive_parents.append(object_id)
                if bytes.fromhex(PLAN['before']) in data:
                    old_root_parents.append(object_id)
    if sensitive_parents != [PLAN['before']] or old_root_parents:
        raise RuntimeError('Unexpected unreachable tree relationship')

for old_id in PLAN['retireObjects']:
    old_path = object_path(GIT, old_id)
    verify_object(old_path, old_id)
    old_path.chmod(old_path.stat().st_mode | stat.S_IWRITE)
    old_path.unlink()

residual_paths = []
for directory, names, files in os.walk(ROOT, followlinks=False):
    names[:] = [name for name in names
                if not (Path(directory) / name).is_symlink()]
    for name in files:
        filename = Path(directory) / name
        if filename.is_symlink():
            continue
        data = filename.read_bytes()
        relative = filename.relative_to(ROOT).as_posix()
        if (relative.startswith('.git/objects/') and
                len(filename.parent.name) == 2 and len(filename.name) == 38):
            try:
                data = zlib.decompress(data)
            except zlib.error:
                pass
        if any(secret in data for secret in sensitive_values):
            residual_paths.append(relative)
if residual_paths:
    raise RuntimeError('Signing secret remains in: ' + ', '.join(residual_paths))

report = {
    'normalizedCodexSnapshotRefs': normalized_refs,
    'snapshotRefAlreadyRemovedByCodex': not reference_exists,
    'installedObjects': installed_objects,
    'retiredSensitiveObjects': len(PLAN['retireObjects']),
    'workingTreeModified': False,
    'headModified': False,
    'repositoryConfigModified': False,
    'residualSensitivePaths': residual_paths,
    'sensitiveValuesPrinted': False
}
(PREPARATION / 'applied.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report))
