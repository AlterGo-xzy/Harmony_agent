import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const root = path.resolve(process.argv[2] ?? '.');
const profilePath = path.join(root, 'build-profile.json5');
const profile = JSON.parse(fs.readFileSync(profilePath, 'utf8'));
const signingConfigs = Array.isArray(profile.app?.signingConfigs)
  ? profile.app.signingConfigs
  : [];

const sensitiveValues = [];
function collectSensitive(value, key = '') {
  if (value == null) return;
  if (typeof value === 'string') {
    if (/(?:password|pwd)$/i.test(key) && value.length > 0) sensitiveValues.push(value);
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectSensitive(item, key);
    return;
  }
  if (typeof value === 'object') {
    for (const [childKey, childValue] of Object.entries(value)) {
      collectSensitive(childValue, childKey);
    }
  }
}
collectSensitive(signingConfigs);

profile.app.signingConfigs = [];
let removedProductReferences = 0;
for (const product of profile.app.products ?? []) {
  if (Object.hasOwn(product, 'signingConfig')) {
    delete product.signingConfig;
    removedProductReferences++;
  }
}
fs.writeFileSync(profilePath, JSON.stringify(profile, null, 2) + '\n');

const syncOutputPath = path.join(root, '.hvigor', 'outputs', 'sync', 'output.json');
let sanitizedHvigorSync = false;
if (fs.existsSync(syncOutputPath)) {
  const syncOutput = JSON.parse(fs.readFileSync(syncOutputPath, 'utf8'));
  const cachedConfigs = syncOutput?.['ohos-project']?.PROFILE_OPT?.app?.signingConfigs;
  if (Array.isArray(cachedConfigs) && cachedConfigs.length > 0) {
    syncOutput['ohos-project'].PROFILE_OPT.app.signingConfigs = [];
    fs.writeFileSync(syncOutputPath, JSON.stringify(syncOutput));
    sanitizedHvigorSync = true;
  }
}

const residualPaths = [];
function containsSensitive(data) {
  return sensitiveValues.some((value) => data.includes(Buffer.from(value, 'utf8')));
}
function inspectFile(filename) {
  let data = fs.readFileSync(filename);
  const relative = path.relative(root, filename).replaceAll('\\', '/');
  if (/^\.git\/objects\/[0-9a-f]{2}\/[0-9a-f]{38}$/i.test(relative)) {
    try {
      data = zlib.inflateSync(data);
    } catch {
      return;
    }
  }
  if (containsSensitive(data)) residualPaths.push(relative);
}
function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const filename = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) walk(filename);
    else if (entry.isFile()) inspectFile(filename);
  }
}
walk(root);

console.log(JSON.stringify({
  removedSigningConfigs: signingConfigs.length,
  removedProductReferences,
  sanitizedHvigorSync,
  sensitiveValueCount: new Set(sensitiveValues).size,
  residualSensitivePaths: residualPaths,
  sensitiveValuesPrinted: false
}));
if (residualPaths.length > 0) process.exitCode = 2;
