"""Prepare, without applying, a sanitized replacement for one Codex snapshot."""
import hashlib
import json
from pathlib import Path
import re
import zlib

ROOT = Path(r'D:\Harmony_agent').resolve(strict=True)
GIT = ROOT / '.git'
OUTPUT = ROOT / 'artifacts' / 't08-signed-device-acceptance' / '20261002-195000' / 'git-sanitization'
SENSITIVE_BLOB = '324af348f24ed44573abd29a61d8ae98c964bac3'
TARGET_REF = 'refs/codex/turn-diffs/captures/1790941998638/a441b3b6-3ea3-4e37-9d6b-00507883be2b/base'
OID = re.compile(r'^[0-9a-f]{40}$')


def object_path(base: Path, object_id: str) -> Path:
    if not OID.fullmatch(object_id):
        raise RuntimeError('Invalid object identifier')
    return base / 'objects' / object_id[:2] / object_id[2:]


def read_object(object_id: str) -> tuple[str, bytes]:
    raw = zlib.decompress(object_path(GIT, object_id).read_bytes())
    header, data = raw.split(b'\x00', 1)
    kind, size = header.decode('ascii').split(' ')
    if len(data) != int(size) or hashlib.sha1(raw).hexdigest() != object_id:
        raise RuntimeError('Invalid Git object')
    return kind, data


def encode_object(kind: str, data: bytes) -> tuple[str, bytes]:
    raw = f'{kind} {len(data)}'.encode('ascii') + b'\x00' + data
    return hashlib.sha1(raw).hexdigest(), zlib.compress(raw)


def parse_tree(data: bytes) -> list[tuple[bytes, bytes, bytes]]:
    entries = []
    offset = 0
    while offset < len(data):
        space = data.index(b' ', offset)
        zero = data.index(b'\x00', space)
        mode = data[offset:space]
        name = data[space + 1:zero]
        object_id = data[zero + 1:zero + 21]
        if len(object_id) != 20:
            raise RuntimeError('Malformed tree')
        entries.append((mode, name, object_id))
        offset = zero + 21
    return entries


profile = json.loads((ROOT / 'build-profile.json5').read_text(encoding='utf-8'))
if profile['app']['signingConfigs'] or any('signingConfig' in item for item in profile['app']['products']):
    raise RuntimeError('Current profile is not sanitized')
profile_bytes = (ROOT / 'build-profile.json5').read_bytes()
new_blob_id, new_blob_compressed = encode_object('blob', profile_bytes)

old_root_id = (GIT / TARGET_REF).read_text(encoding='utf-8').strip()
kind, root_data = read_object(old_root_id)
if kind != 'tree':
    raise RuntimeError('Codex base ref is not a tree')
entries = parse_tree(root_data)
matched = 0
new_entries = []
for mode, name, object_id in entries:
    if name == b'build-profile.json5':
        if object_id.hex() != SENSITIVE_BLOB:
            raise RuntimeError('Prepared sensitive blob no longer matches the snapshot')
        object_id = bytes.fromhex(new_blob_id)
        matched += 1
    new_entries.append(mode + b' ' + name + b'\x00' + object_id)
if matched != 1:
    raise RuntimeError('Expected exactly one root profile entry')
new_root_id, new_root_compressed = encode_object('tree', b''.join(new_entries))

tree_references = []
for prefix in (GIT / 'objects').iterdir():
    if not prefix.is_dir() or not re.fullmatch(r'[0-9a-f]{2}', prefix.name):
        continue
    for item in prefix.iterdir():
        candidate = prefix.name + item.name
        try:
            candidate_kind, candidate_data = read_object(candidate)
        except (OSError, ValueError, zlib.error, RuntimeError):
            continue
        if candidate_kind == 'tree' and bytes.fromhex(SENSITIVE_BLOB) in candidate_data:
            tree_references.append(candidate)
if tree_references != [old_root_id]:
    raise RuntimeError('Sensitive blob has an unexpected tree reference')

for object_id, compressed in ((new_blob_id, new_blob_compressed), (new_root_id, new_root_compressed)):
    destination = object_path(OUTPUT, object_id)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(compressed)

plan = {
    'workspace': str(ROOT),
    'targetRef': TARGET_REF,
    'before': old_root_id,
    'after': new_root_id,
    'sensitiveBlob': SENSITIVE_BLOB,
    'replacementBlob': new_blob_id,
    'newObjects': [new_blob_id, new_root_id],
    'retireObjects': [SENSITIVE_BLOB, old_root_id],
    'affectedCodexSnapshotRefs': 1,
    'sourceCommitOrTagObjects': 0,
    'workingTreeModifiedByApply': False,
    'headModifiedByApply': False,
    'repositoryConfigModifiedByApply': False,
    'sensitiveValuesPrinted': False
}
(OUTPUT / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: plan[key] for key in (
    'targetRef', 'before', 'after', 'newObjects', 'retireObjects',
    'affectedCodexSnapshotRefs', 'sourceCommitOrTagObjects',
    'sensitiveValuesPrinted')}))
