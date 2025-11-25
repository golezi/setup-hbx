#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ROOT=${CORE_ROOT:-/opt/core}

if [ ! -d "$CORE_ROOT" ]; then
    ALT_CORE_ROOT="$SCRIPT_DIR/core"
    if [ -d "$ALT_CORE_ROOT" ]; then
        CORE_ROOT="$ALT_CORE_ROOT"
    else
        echo "Unable to locate core directory. Checked '$CORE_ROOT' and '$ALT_CORE_ROOT'." >&2
        exit 1
    fi
fi

npm config set registry https://registry.npmmirror.com
YARN_REGISTRY=${YARN_REGISTRY:-https://registry.npmmirror.com}
if command -v yarn >/dev/null 2>&1; then
    export YARN_IGNORE_PATH=1
    export YARN_NPM_REGISTRY_SERVER="$YARN_REGISTRY"
    export YARN_REGISTRY="$YARN_REGISTRY"
fi
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
npm install -g cross-env
cd "$CORE_ROOT/plugins"
rm -rf node_modules
npm i
cd "$CORE_ROOT/plugins/uniapp-cli-vite"
# remove stale node_modules to avoid mismatched binaries from bundled archives
rm -rf node_modules
yarn --registry "$YARN_REGISTRY" --force
cd "$CORE_ROOT/plugins/uniapp-cli"
rm -rf node_modules
npm i -f
chmod +x "$CORE_ROOT/plugins/compile-node-sass/node_modules/node-sass-china/vendor/linux-x64-108/binding.node"
