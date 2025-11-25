#!/usr/bin/env node
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const toPosixPath = (p) => p.replace(/\\/g, '/');

const repoRoot = path.resolve(__dirname, '..');
const cliDir = (() => {
  const explicit = process.env.HBX_PLUGIN_DIR || process.env.UNI_CLI_CONTEXT;
  if (explicit) {
    return path.resolve(explicit);
  }
  return path.join(repoRoot, 'core', 'plugins', 'uniapp-cli-vite');
})();

if (!fs.existsSync(cliDir)) {
  console.error(`Cannot find uniapp-cli-vite directory at ${cliDir}. Set HBX_PLUGIN_DIR to a valid location.`);
  process.exit(1);
}

const cliBin = path.join(cliDir, 'node_modules', '@dcloudio', 'vite-plugin-uni', 'bin', 'uni.js');
if (!fs.existsSync(cliBin)) {
  console.error(
    `cli binary not found at ${cliBin}. Install dependencies by running CORE_ROOT=<path-to-core> ./core-install.sh or npm run setup before building.`
  );
  process.exit(1);
}

const rawInputDir = process.env.UNI_INPUT_DIR;
if (!rawInputDir) {
  console.error('UNI_INPUT_DIR is not set. Export it to point to the UniApp project you want to build.');
  process.exit(1);
}

const uniInputDir = path.resolve(rawInputDir);
if (!fs.existsSync(uniInputDir)) {
  console.error(`UNI_INPUT_DIR points to ${uniInputDir}, but the directory does not exist.`);
  process.exit(1);
}

const initCwd = process.env.INIT_CWD ? path.resolve(process.env.INIT_CWD) : repoRoot;
const uniOutputDir = path.resolve(process.env.UNI_OUTPUT_DIR || path.join(initCwd, 'result'));
fs.mkdirSync(uniOutputDir, { recursive: true });

const uniNodeEnv = process.env.UNI_NODE_ENV || 'production';
const extraArgs = process.argv.slice(2);

const childEnv = {
  ...process.env,
  UNI_INPUT_DIR: toPosixPath(uniInputDir),
  UNI_OUTPUT_DIR: toPosixPath(uniOutputDir),
  UNI_NODE_ENV: uniNodeEnv,
};

const child = spawn(
  'node',
  [cliBin, 'build', '-p', 'app', ...extraArgs],
  {
    cwd: cliDir,
    env: childEnv,
    stdio: 'inherit',
  }
);

child.on('exit', (code) => {
  process.exit(code);
});
