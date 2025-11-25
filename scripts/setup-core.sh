#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CORE_ROOT="${CORE_ROOT:-$ROOT_DIR/core}"

bash "$ROOT_DIR/core-install.sh"
