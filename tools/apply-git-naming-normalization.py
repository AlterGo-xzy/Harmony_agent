"""Apply an explicitly approved, prepared Codex snapshot naming plan.

Only loose objects and the plan's six Codex refs are changed. This script must
never be run without approval for Git metadata writes and historical snapshots.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import stat
import subprocess
import zlib

parser = argparse.ArgumentParser()
parser.add_argument('--root', required=True)
parser.add_argument('--preparation', required=True)
parser.add_argument('--approved-codex-snapshots', action='store_true', required=True)
args = parser.parse_args()
root = Path(args.root).resolve(strict=True)
preparation = Path(args.preparation).resolve(strict=True)
git_dir = (root / '.git').resolve(strict=True)
if not git_dir.is_relative_to(root) or not preparation.is_relative_to(root):
    raise RuntimeError('Paths must resolve inside the workspace')
plan = json.loads((preparation / 'plan.json').read_text(encoding='utf-8'))
if plan['workspace'].lower() != str(root).lower() or len(plan['referenceUpdates']) != 6 or len(plan['changedObjects']) != 427:
    raise RuntimeError('Prepared scope changed; approval must be refreshed')
if plan['sourceCommitOrTagObjects'] != 0:
    raise RuntimeError('Source commits/tags are outside this approval')
oid_pattern = re.compile(r'^[0-9a-f]{40}$')


def object_path(base, object_id):
    if not oid_pattern.fullmatch(object_id):
        raise RuntimeError('Invalid object identifier')
    result = base / 'objects' / object_id[:2] / object_id[2:]
    if not result.parent.resolve().is_relative_to(base.resolve()) or result.is_symlink():
        raise RuntimeError('Object path escaped approved scope')
    return result


def verified_object(path, expected):
    raw = zlib.decompress(path.read_bytes())
    header, data = raw.split(b'\x00', 1)
    kind, size = header.decode('ascii').split(' ')
    if kind not in {'blob', 'tree'} or len(data) != int(size) or hashlib.sha1(raw).hexdigest() != expected:
        raise RuntimeError('Invalid snapshot object')
    return raw


for update in plan['referenceUpdates']:
    relative = update['ref']
    if not relative.startswith('refs/codex/turn-diffs/') or '..' in Path(relative).parts:
        raise RuntimeError('Reference outside approved Codex snapshot scope')
    reference = git_dir / relative
    if reference.is_symlink() or not reference.resolve().is_relative_to(git_dir):
        raise RuntimeError('Invalid snapshot reference path')
    if reference.read_text(encoding='utf-8').strip() != update['before']:
        raise RuntimeError('Snapshot reference changed since preparation')
for change in plan['changedObjects']:
    verified_object(object_path(git_dir, change['before']), change['before'])
    verified_object(object_path(preparation, change['after']), change['after'])

installed = set()
for change in plan['changedObjects']:
    object_id = change['after']
    if object_id in installed:
        continue
    source = object_path(preparation, object_id)
    destination = object_path(git_dir, object_id)
    expected_raw = verified_object(source, object_id)
    if destination.exists():
        if verified_object(destination, object_id) != expected_raw:
            raise RuntimeError('Existing object contents differ')
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open('xb') as stream:
            stream.write(source.read_bytes())
    installed.add(object_id)

transaction = ['start']
transaction += [f"update {item['ref']} {item['after']} {item['before']}" for item in plan['referenceUpdates']]
transaction += ['prepare', 'commit', '']
result = subprocess.run(['git', '-C', str(root), 'update-ref', '--stdin'],
                        input='\n'.join(transaction).encode('utf-8'), capture_output=True)
if result.returncode != 0:
    raise RuntimeError('Atomic Codex ref update failed; original objects retained: ' +
                       result.stderr.decode('utf-8', errors='replace').strip())
for update in plan['referenceUpdates']:
    if (git_dir / update['ref']).read_text(encoding='utf-8').strip() != update['after']:
        raise RuntimeError('Updated ref verification failed; original objects retained')

# Reject deletion if any additional ref now points at an old changed object.
retired_ids = {change['before'] for change in plan['changedObjects']}
for reference in (git_dir / 'refs').rglob('*'):
    if reference.is_file() and reference.read_text(encoding='utf-8').strip() in retired_ids:
        raise RuntimeError('Another ref uses an old object; original objects retained')
for change in plan['changedObjects']:
    path = object_path(git_dir, change['before'])
    verified_object(path, change['before'])
    # Git loose objects carry the Windows read-only attribute. Clear it only
    # on this approved, validated obsolete object before removing that file.
    path.chmod(path.stat().st_mode | stat.S_IWRITE)
    path.unlink()

report = {'workspace': str(root), 'installedUniqueObjects': len(installed),
          'normalizedCodexRefs': len(plan['referenceUpdates']), 'retiredLooseObjects': len(retired_ids),
          'workingTreeModified': False, 'headModified': False, 'repositoryConfigModified': False,
          'oldNamingCannotBeRestoredFromNormalizedSnapshots': True}
(preparation / 'applied.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report))
