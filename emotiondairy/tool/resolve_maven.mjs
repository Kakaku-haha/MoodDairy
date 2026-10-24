#!/usr/bin/env node
/**
 * Resolve Android Maven dependencies through a running Chrome DevTools instance.
 *
 * The harness shell cannot negotiate TLS on this machine, but Chrome can. This
 * script asks Chrome to download POM/artifact pairs into the local Maven
 * repository so Gradle can later build offline.
 *
 * Usage:
 *   node resolve_maven.mjs <chrome-debug-port> <seed-json> [download-dir]
 */
import fs from 'node:fs';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

const port = process.argv[2] || '9229';
const seedArg = process.argv[3] || '[]';
const seeds = JSON.parse(
  seedArg.startsWith('[') ? seedArg : fs.readFileSync(seedArg, 'utf8'),
);
const downloadDir =
  process.argv[4] ||
  path.join(process.env.TEMP || process.env.TMP || '.', 'warmtrace-cdp-downloads');
const m2 =
  process.env.M2_REPO ||
  path.join(process.env.USERPROFILE || process.env.HOME || '.', '.m2', 'repository');

fs.mkdirSync(downloadDir, { recursive: true });
fs.mkdirSync(m2, { recursive: true });

const sleep = (ms) => delay(ms);

async function getJson(url, attempts = 40) {
  for (let i = 0; i < attempts; i++) {
    try {
      const response = await fetch(url);
      if (response.ok) return await response.json();
    } catch (_) {
      // Chrome may still be starting.
    }
    await sleep(250);
  }
  throw new Error(`Could not connect to Chrome at ${url}`);
}

const versionInfo = await getJson(`http://127.0.0.1:${port}/json/version`);
const ws = new WebSocket(versionInfo.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', reject, { once: true });
});

let nextId = 1;
const pending = new Map();
ws.addEventListener('message', (event) => {
  let message;
  try {
    message = JSON.parse(event.data);
  } catch (_) {
    return;
  }
  if (message.id && pending.has(message.id)) {
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(message.error.message));
    else resolve(message.result);
  }
});

function send(method, params = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });
}

await send('Browser.setDownloadBehavior', {
  behavior: 'allow',
  downloadPath: downloadDir,
  eventsEnabled: true,
});

const queue = [];
const visited = new Set();
const failures = [];
const warnings = [];

function enqueue(groupId, artifactId, version) {
  if (!groupId || !artifactId || !version) return;
  if (version.includes('${') || version.includes('[') || version.includes('(')) {
    warnings.push(`unsupported version ${groupId}:${artifactId}:${version}`);
    return;
  }
  const key = `${groupId}:${artifactId}:${version}`;
  if (visited.has(key)) return;
  visited.add(key);
  queue.push({ groupId, artifactId, version });
}

for (const seed of seeds) {
  enqueue(seed.groupId, seed.artifactId, seed.version);
}

function repositoryOrder(groupId) {
  if (groupId === 'io.flutter') {
    return ['https://storage.googleapis.com/download.flutter.io'];
  }
  if (
    groupId.startsWith('androidx.') ||
    groupId.startsWith('com.android.') ||
    groupId.startsWith('com.google.android.')
  ) {
    return [
      'https://dl.google.com/dl/android/maven2',
      'https://repo1.maven.org/maven2',
    ];
  }
  return [
    'https://repo1.maven.org/maven2',
    'https://dl.google.com/dl/android/maven2',
  ];
}

function mavenPath(groupId, artifactId, version, extension) {
  const groupPath = groupId.split('.').join('/');
  return `${groupPath}/${artifactId}/${version}/${artifactId}-${version}.${extension}`;
}

async function downloadUrl(url, expectedName) {
  const source = path.join(downloadDir, expectedName);
  if (fs.existsSync(source)) {
    fs.rmSync(source, { force: true });
  }
  let targetId;
  try {
    const target = await send('Target.createTarget', { url });
    targetId = target.targetId;
    let lastSize = -1;
    for (let i = 0; i < 80; i++) {
      await sleep(250);
      if (fs.existsSync(source)) {
        const size = fs.statSync(source).size;
        if (size > 0 && size === lastSize) return source;
        lastSize = size;
      }
    }
    return null;
  } finally {
    if (targetId) {
      try {
        await send('Target.closeTarget', { targetId });
      } catch (_) {}
    }
  }
}

async function fetchArtifact(groupId, artifactId, version, extension) {
  const relative = mavenPath(groupId, artifactId, version, extension);
  const destination = path.join(m2, relative);
  if (fs.existsSync(destination) && fs.statSync(destination).size > 0) {
    return true;
  }
  const expectedName = path.basename(relative);
  for (const base of repositoryOrder(groupId)) {
    const url = `${base}/${relative}`;
    const downloaded = await downloadUrl(url, expectedName);
    if (downloaded) {
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      try {
        fs.renameSync(downloaded, destination);
      } catch (_) {
        fs.copyFileSync(downloaded, destination);
        fs.rmSync(downloaded, { force: true });
      }
      return true;
    }
  }
  failures.push(`${groupId}:${artifactId}:${version} (${extension})`);
  return false;
}

function readTag(xml, tag) {
  const match = xml.match(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`));
  return match ? match[1].trim() : '';
}

function propertyMap(pom) {
  const map = {};
  const propertiesMatch = pom.match(/<properties>([\s\S]*?)<\/properties>/);
  if (!propertiesMatch) return map;
  const body = propertiesMatch[1];
  const regex = /<([A-Za-z0-9_.-]+)>([^<]*)<\/\1>/g;
  let match;
  while ((match = regex.exec(body))) {
    map[match[1]] = match[2].trim();
  }
  return map;
}

function resolveVersion(value, pom, groupId, artifactId, version) {
  let result = value
    .replaceAll('${project.version}', version)
    .replaceAll('${project.groupId}', groupId)
    .replaceAll('${project.artifactId}', artifactId);
  const props = propertyMap(pom);
  for (const [key, replacement] of Object.entries(props)) {
    result = result.replaceAll(`\${${key}}`, replacement);
  }
  return result;
}

function stripDependencyManagement(pom) {
  return pom.replace(
    /<dependencyManagement>[\s\S]*?<\/dependencyManagement>/g,
    '',
  );
}

function parseDependencies(pom) {
  const body = stripDependencyManagement(pom);
  const dependencies = [];
  const regex = /<dependency>([\s\S]*?)<\/dependency>/g;
  let match;
  while ((match = regex.exec(body))) {
    const block = match[1];
    const groupId = readTag(block, 'groupId');
    const artifactId = readTag(block, 'artifactId');
    const version = readTag(block, 'version');
    const scope = readTag(block, 'scope');
    const type = readTag(block, 'type');
    const optional = readTag(block, 'optional');
    if (!groupId || !artifactId) continue;
    if (['test', 'provided', 'system'].includes(scope)) continue;
    if (optional === 'true') continue;
    if (type === 'pom') continue;
    dependencies.push({ groupId, artifactId, version, type });
  }
  return dependencies;
}

let index = 0;
while (index < queue.length) {
  const { groupId, artifactId, version } = queue[index++];
  process.stdout.write(
    `[${index}/${queue.length}] ${groupId}:${artifactId}:${version} ... `,
  );

  const pomDownloaded = await fetchArtifact(groupId, artifactId, version, 'pom');
  if (!pomDownloaded) {
    console.log('POM failed');
    continue;
  }

  const pomPath = path.join(
    m2,
    mavenPath(groupId, artifactId, version, 'pom'),
  );
  let pom = '';
  try {
    pom = fs.readFileSync(pomPath, 'utf8');
  } catch (error) {
    console.log(`POM unreadable: ${error.message}`);
    continue;
  }

  const packaging = (readTag(pom, 'packaging') || 'jar').toLowerCase();
  if (packaging !== 'pom') {
    const extension = packaging === 'aar' ? 'aar' : 'jar';
    await fetchArtifact(groupId, artifactId, version, extension);
  }

  const parentBlock = pom.match(/<parent>([\s\S]*?)<\/parent>/)?.[1];
  if (parentBlock) {
    const parentGroup = readTag(parentBlock, 'groupId');
    const parentArtifact = readTag(parentBlock, 'artifactId');
    const parentVersion = readTag(parentBlock, 'version');
    if (parentGroup && parentArtifact && parentVersion) {
      enqueue(parentGroup, parentArtifact, parentVersion);
    }
  }

  for (const dependency of parseDependencies(pom)) {
    const dependencyVersion = resolveVersion(
      dependency.version,
      pom,
      groupId,
      artifactId,
      version,
    );
    if (!dependencyVersion) {
      warnings.push(
        `unversioned dependency ${dependency.groupId}:${dependency.artifactId} from ${groupId}:${artifactId}:${version}`,
      );
      continue;
    }
    enqueue(dependency.groupId, dependency.artifactId, dependencyVersion);
  }

  console.log('ok');
}

fs.writeFileSync(
  path.join(downloadDir, 'resolution-report.json'),
  JSON.stringify({ visited: [...visited], failures, warnings }, null, 2),
);

console.log(`\nVisited ${visited.size} coordinates.`);
if (warnings.length) {
  console.log(`Warnings (${warnings.length}):`);
  for (const warning of warnings.slice(0, 40)) console.log(`  - ${warning}`);
}
if (failures.length) {
  console.log(`Failures (${failures.length}):`);
  for (const failure of failures) console.log(`  - ${failure}`);
  process.exitCode = 1;
}
ws.close();
