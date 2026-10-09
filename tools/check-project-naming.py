"""Inspect or normalize a workspace's names without following directory links.

Text can be normalized. Binary artifacts are retired with hash-only provenance;
they are never edited into an apparently valid executable or signed package.
"""
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import tarfile
import zipfile
import zlib

parser = argparse.ArgumentParser()
parser.add_argument('--root', required=True)
parser.add_argument('--forbid-token', required=True)
parser.add_argument('--replacement', default='harmony_agent')
parser.add_argument('--report', required=True)
parser.add_argument('--apply', action='store_true')
args = parser.parse_args()
root = Path(args.root).resolve(strict=True)
report_path = Path(args.report).absolute()
token = args.forbid_token
pattern = re.compile(re.escape(token), re.IGNORECASE)
byte_patterns = [re.compile(re.escape(token.encode(encoding)), re.IGNORECASE)
                 for encoding in ('utf-8', 'utf-16-le', 'utf-16-be')]
replacement = args.replacement
protected = {'.git', '.agents', '.local'}
archive_containers = 0
archive_entries = 0


def checked(path):
    absolute = Path(path).absolute()
    resolved_parent = absolute.parent.resolve(strict=True)
    if not resolved_parent.is_relative_to(root) or absolute == root:
        raise RuntimeError('Operation outside workspace')
    if absolute.exists() and absolute.is_symlink():
        raise RuntimeError('Refusing to modify a link')
    return absolute


def has_bytes(data):
    return any(regex.search(data) for regex in byte_patterns)


def archive_matches(data, depth=0):
    global archive_containers, archive_entries
    if depth > 8:
        raise RuntimeError('Archive nesting limit reached')
    if has_bytes(data):
        return True
    if data.startswith(b'PK\x03\x04'):
        archive_containers += 1
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for item in archive.infolist():
                archive_entries += 1
                if pattern.search(item.filename):
                    return True
                if not item.is_dir() and archive_matches(archive.read(item), depth + 1):
                    return True
    elif data.startswith(b'\x1f\x8b'):
        archive_containers += 1
        plain = gzip.decompress(data)
        if has_bytes(plain):
            return True
        try:
            with tarfile.open(fileobj=io.BytesIO(plain)) as archive:
                for item in archive:
                    archive_entries += 1
                    if pattern.search(item.name):
                        return True
                    if item.isfile():
                        if archive_matches(archive.extractfile(item).read(), depth + 1):
                            return True
        except tarfile.ReadError:
            return False
    elif len(data) > 265 and data[257:262] == b'ustar':
        archive_containers += 1
        with tarfile.open(fileobj=io.BytesIO(data)) as archive:
            for item in archive:
                archive_entries += 1
                if pattern.search(item.name):
                    return True
                if item.isfile() and archive_matches(archive.extractfile(item).read(), depth + 1):
                    return True
    elif len(data) >= 2 and data[0] & 15 == 8 and data[0] >> 4 <= 7 and ((data[0] << 8) + data[1]) % 31 == 0:
        try:
            plain = zlib.decompress(data)
        except zlib.error:
            return False
        archive_containers += 1
        return archive_matches(plain, depth + 1)
    return False


def text_content(data):
    for encoding, marker in [('utf-8-sig', b'\xef\xbb\xbf'),
                             ('utf-16', b'\xff\xfe'), ('utf-16', b'\xfe\xff')]:
        if data.startswith(marker):
            try:
                return data.decode(encoding), encoding
            except UnicodeError:
                return None
    try:
        text = data.decode('utf-8')
    except UnicodeError:
        return None
    if '\x00' in text:
        return None
    return text, 'utf-8'


def normalize(text):
    exact = [
        (f'{token.upper()}_AGENT_ARCHITECTURE', 'HARMONY_AGENT_ARCHITECTURE'),
        (f'{token.upper()}_DEVELOPMENT_MODULES', 'HARMONY_AGENT_DEVELOPMENT_MODULES'),
        (f'com.{token}.mcpclient.test', 'com.harmony.agent'),
        (f'com.{token}.agent.testhost', 'com.harmony.agent'),
        (f'{token}_agent_', 'harmony_agent_'),
        (f'{token}BenchResultsJson', 'harmonyAgentBenchResultsJson'),
        (f'{token}BenchResults', 'HarmonyAgentBenchResults'),
        (f'{token}Bench', 'harmony_agent Bench'),
        (f'{token}bench', 'harmony_agent_bench'),
    ]
    for before, after in exact:
        text = re.sub(re.escape(before), lambda _: after, text, flags=re.IGNORECASE)
    return pattern.sub(replacement, text)


files = []
directories = []
links = []
visited = 0


def walk(directory):
    global visited
    with os.scandir(directory) as entries:
        for entry in entries:
            item = Path(entry.path)
            info = entry.stat(follow_symlinks=False)
            attributes = getattr(info, 'st_file_attributes', 0)
            is_link = entry.is_symlink() or attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT
            if is_link:
                links.append(item)
            elif entry.is_dir(follow_symlinks=False):
                directories.append(item)
                walk(item)
            elif entry.is_file(follow_symlinks=False):
                visited += 1
                data = item.read_bytes()
                found = archive_matches(data)
                if found or pattern.search(item.name):
                    files.append((item, data, found))
                if visited % 3000 == 0:
                    print(json.dumps({'scannedFiles': visited, 'matchedFiles': len(files)}), flush=True)


walk(root)
records = []
protected_matches = []
for item, data, content_match in files:
    relative = item.relative_to(root)
    clean_relative = normalize(str(relative))
    in_protected = relative.parts[0] in protected
    if in_protected:
        protected_matches.append(clean_relative)
        continue
    record = {'path': clean_relative, 'originalSha256': hashlib.sha256(data).hexdigest(),
              'bytes': len(data), 'contentMatch': content_match}
    decoded = text_content(data) if content_match else None
    if content_match and decoded is None:
        # Retire only derived or historical binary artifacts, never project inputs.
        if not any(part in {'artifacts', 'build', '.test', '.hvigor'} for part in relative.parts):
            raise RuntimeError('Binary input needs a specific treatment: ' + clean_relative)
        record['action'] = 'retire_binary_with_provenance'
        if args.apply:
            tombstone = checked(item.with_name(normalize(item.name) + '.retired.json'))
            if tombstone.exists():
                raise RuntimeError('Retirement manifest already exists')
            tombstone.write_text(json.dumps({
                'status': 'RETIRED_NOT_INSTALLABLE',
                'originalSha256': record['originalSha256'],
                'originalBytes': len(data),
                'reason': 'Historical binary retained a previous project name; removed on owner request.',
                'originalBinaryPreserved': False,
                'currentNaming': replacement,
                'deviceAcceptanceEvidence': False
            }, indent=2) + '\n', encoding='utf-8')
            checked(item).unlink()
            record['resultPath'] = normalize(str(tombstone.relative_to(root)))
    else:
        record['action'] = 'normalize_text' if content_match else 'rename_file'
        if args.apply:
            if content_match:
                text, encoding = decoded
                updated = normalize(text).encode(encoding)
                checked(item).write_bytes(updated)
                record['normalizedSha256'] = hashlib.sha256(updated).hexdigest()
            destination = checked(item.with_name(normalize(item.name)))
            if destination != item:
                if destination.exists():
                    raise RuntimeError('Rename destination already exists')
                checked(item).rename(destination)
    records.append(record)

renamed_directories = []
for item in sorted(directories, key=lambda value: len(value.parts), reverse=True):
    if pattern.search(item.name):
        relative = item.relative_to(root)
        if relative.parts[0] in protected:
            protected_matches.append(normalize(str(relative)))
            continue
        destination = checked(item.with_name(normalize(item.name)))
        if args.apply:
            if destination.exists():
                raise RuntimeError('Directory rename destination already exists')
            checked(item).rename(destination)
        renamed_directories.append(normalize(str(relative)))

link_name_matches = [normalize(str(item.relative_to(root))) for item in links
                     if pattern.search(str(item.relative_to(root)))]
link_target_matches = []
for item in links:
    target = os.readlink(item)
    if pattern.search(target):
        link_target_matches.append(normalize(str(item.relative_to(root))))
summary = {'workspace': str(root), 'mode': 'apply' if args.apply else 'inspect',
           'scannedPhysicalFiles': visited, 'matchedPhysicalFiles': len(files),
           'contentMatches': sum(found for _, _, found in files),
           'matchedPhysicalDirectories': len(renamed_directories),
           'protectedMatches': protected_matches, 'linkNameMatches': link_name_matches,
           'linkTargetMatches': link_target_matches,
           'inspectedArchiveContainers': archive_containers,
           'inspectedArchiveEntries': archive_entries,
           'notFollowingLinks': len(links), 'records': records,
           'renamedDirectories': renamed_directories,
           'thisRunModifiedFileBytes': args.apply,
           'normalizationNeverPreservesRetiredBinaryBytes': True,
           'historicalNormalizedFilesAreDeviceEvidence': False}
checked(report_path).parent.mkdir(parents=True, exist_ok=True)
checked(report_path).write_text(json.dumps(summary, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(json.dumps({key: summary[key] for key in ['mode', 'scannedPhysicalFiles', 'matchedPhysicalFiles',
       'contentMatches', 'matchedPhysicalDirectories', 'protectedMatches', 'linkNameMatches',
       'linkTargetMatches', 'notFollowingLinks', 'inspectedArchiveContainers', 'inspectedArchiveEntries']}, ensure_ascii=False), flush=True)
if protected_matches or link_name_matches or link_target_matches:
    raise SystemExit(2)
if not args.apply and (files or renamed_directories):
    raise SystemExit(1)
