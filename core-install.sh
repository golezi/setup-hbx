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
if command -v yarn >/dev/null 2>&1; then
    YARN_IGNORE_PATH=1 yarn config set registry https://registry.npmmirror.com
fi
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
npm install -g cross-env
cd "$CORE_ROOT/plugins"
npm i
cd "$CORE_ROOT/plugins/uniapp-cli-vite"
yarn --force
cd "$CORE_ROOT/plugins/uniapp-cli"
npm i -f
chmod +x "$CORE_ROOT/plugins/compile-node-sass/node_modules/node-sass-china/vendor/linux-x64-108/binding.node"
