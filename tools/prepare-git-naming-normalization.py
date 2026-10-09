"""Prepare normalized Codex snapshot objects without writing Git metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zlib

parser = argparse.ArgumentParser()
parser.add_argument('--root', required=True)
parser.add_argument('--forbid-token', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()
root = Path(args.root).resolve(strict=True)
output = Path(args.output).resolve(strict=True)
if not output.is_relative_to(root) or output.is_relative_to(root / '.git'):
    raise RuntimeError('Preparation output must be outside Git metadata and inside workspace')
git_dir = root / '.git'
token = args.forbid_token
pattern = re.compile(re.escape(token), re.IGNORECASE)
objects = {}
for directory in (git_dir / 'objects').iterdir():
    if not directory.is_dir() or len(directory.name) != 2:
        continue
    for item in directory.iterdir():
        if not item.is_file() or len(item.name) != 38:
            continue
        raw = zlib.decompress(item.read_bytes())
        header, data = raw.split(b'\x00', 1)
        kind, length = header.decode('ascii').split(' ')
        object_id = directory.name + item.name
        if int(length) != len(data) or hashlib.sha1(raw).hexdigest() != object_id:
            raise RuntimeError('Invalid loose object')
        objects[object_id] = (kind, data)


def normalize(value):
    replacements = [
        (f'{token.upper()}_AGENT_ARCHITECTURE', 'HARMONY_AGENT_ARCHITECTURE'),
        (f'{token.upper()}_DEVELOPMENT_MODULES', 'HARMONY_AGENT_DEVELOPMENT_MODULES'),
        (f'com.{token}.mcpclient.test', 'com.harmony.agent'),
        (f'com.{token}.agent.testhost', 'com.harmony.agent'),
        (f'{token}_agent_', 'harmony_agent_'),
        (f'{token}BenchResultsJson', 'harmonyAgentBenchResultsJson'),
        (f'{token}Bench', 'harmony_agent Bench'),
        (f'{token}bench', 'harmony_agent_bench'),
    ]
    for before, after in replacements:
        value = re.sub(re.escape(before), lambda _: after, value, flags=re.IGNORECASE)
    return pattern.sub('harmony_agent', value)


mapping = {}
new_objects = {}
binary_matches = []


def visit(object_id):
    if object_id in mapping:
        return mapping[object_id]
    if object_id not in objects:
        return object_id
    kind, data = objects[object_id]
    updated = data
    if kind == 'blob':
        try:
            text = data.decode('utf-8')
        except UnicodeError:
            if re.search(re.escape(token.encode()), data, re.IGNORECASE):
                binary_matches.append(object_id)
            mapping[object_id] = object_id
            return object_id
        updated = normalize(text).encode('utf-8')
    elif kind == 'tree':
        cursor = 0
        parts = []
        seen_names = set()
        while cursor < len(data):
            terminator = data.index(b'\x00', cursor)
            mode, name = data[cursor:terminator].split(b' ', 1)
            child_id = data[terminator + 1:terminator + 21].hex()
            new_name = normalize(name.decode('utf-8')).encode('utf-8')
            if new_name in seen_names:
                raise RuntimeError('Tree rename collision')
            seen_names.add(new_name)
            new_child = visit(child_id)
            parts.append((mode, new_name, bytes.fromhex(new_child)))
            cursor = terminator + 21
        parts.sort(key=lambda part: part[1] + (b'/' if part[0] == b'40000' else b''))
        updated = b''.join(mode + b' ' + name + b'\x00' + child for mode, name, child in parts)
    else:
        raise RuntimeError('Source commit/tag object exists; requires separate history treatment')
    raw = f'{kind} {len(updated)}'.encode('ascii') + b'\x00' + updated
    new_id = hashlib.sha1(raw).hexdigest()
    mapping[object_id] = new_id
    if new_id != object_id:
        if re.search(re.escape(token.encode()), updated, re.IGNORECASE):
            raise RuntimeError('Legacy value remained in prepared object')
        new_objects[new_id] = raw
    return new_id


for object_id in objects:
    visit(object_id)
ref_updates = []
for item in (git_dir / 'refs').rglob('*'):
    if not item.is_file():
        continue
    value = item.read_text(encoding='utf-8').strip()
    if value not in mapping or mapping[value] == value:
        continue
    relative = item.relative_to(git_dir).as_posix()
    if not relative.startswith('refs/codex/turn-diffs/'):
        raise RuntimeError('Non-Codex reference would change')
    ref_updates.append({'ref': relative, 'before': value, 'after': mapping[value]})
if binary_matches:
    raise RuntimeError('A binary Git snapshot requires a separate normalization strategy')
for object_id, raw in new_objects.items():
    item = output / 'objects' / object_id[:2] / object_id[2:]
    item.parent.mkdir(parents=True, exist_ok=True)
    item.write_bytes(zlib.compress(raw))
changed = [{'before': before, 'after': after, 'kind': objects[before][0]}
           for before, after in mapping.items() if before != after]
summary = {
    'workspace': str(root), 'mode': 'prepared_without_git_write',
    'examinedLooseObjects': len(objects), 'objectsToReplace': len(changed),
    'preparedUniqueObjects': len(new_objects), 'referenceUpdates': ref_updates,
    'changedObjects': changed, 'sourceCommitOrTagObjects': 0,
    'workingTreeModification': False, 'headModification': False,
    'repositoryConfigModification': False,
    'impact': 'Codex historical diffs and rollback snapshots will use normalized names; old naming cannot be restored from them.'
}
(output / 'plan.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'examinedLooseObjects': len(objects), 'objectsToReplace': len(changed),
                  'preparedUniqueObjects': len(new_objects), 'codexRefsToUpdate': len(ref_updates),
                  'sourceCommitOrTagObjects': 0, 'gitMetadataWritten': False}))
