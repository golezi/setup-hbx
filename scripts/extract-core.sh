#!/usr/bin/env bash
set -euo pipefail

REQUESTED="${1:-}"
if [[ -z "$REQUESTED" ]]; then
  echo "Usage: extract-core.sh <version-or-archive>" >&2
  exit 1
fi

ACTION_DIR="${GITHUB_ACTION_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

declare -a CANDIDATES=()
if [[ "$REQUESTED" == core-*.* ]]; then
  CANDIDATES+=("$REQUESTED")
else
  CANDIDATES+=("core-${REQUESTED}.tar.gz" "core-${REQUESTED}.tgz" "core-${REQUESTED}.zip")
fi
CANDIDATES+=("$REQUESTED")

ARCHIVE_PATH=""
for name in "${CANDIDATES[@]}"; do
  if [[ -f "$ACTION_DIR/$name" ]]; then
    ARCHIVE_PATH="$ACTION_DIR/$name"
    break
  fi
done

if [[ -z "$ARCHIVE_PATH" ]]; then
  echo "Unable to locate archive for '${REQUESTED}'. Looked for: ${CANDIDATES[*]}" >&2
  exit 1
fi

WORK_BASE="${RUNNER_TEMP:-$ACTION_DIR/.tmp}/hbx-core"
rm -rf "$WORK_BASE"
mkdir -p "$WORK_BASE"

EXTRACT_DIR="$WORK_BASE/src"
mkdir -p "$EXTRACT_DIR"

case "$ARCHIVE_PATH" in
  *.tar.gz|*.tgz)
    tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR"
    ;;
  *.zip)
    unzip -q "$ARCHIVE_PATH" -d "$EXTRACT_DIR"
    ;;
  *)
    echo "Unsupported archive format: $ARCHIVE_PATH" >&2
    exit 1
    ;;
esac

CORE_DIR=""
if [[ -d "$EXTRACT_DIR/core/plugins" ]]; then
  CORE_DIR="$EXTRACT_DIR/core"
elif [[ -d "$EXTRACT_DIR/plugins" ]]; then
  CORE_DIR="$EXTRACT_DIR"
else
  while IFS= read -r -d '' plugins_dir; do
    CORE_DIR="$(dirname "$plugins_dir")"
    break
  done < <(find "$EXTRACT_DIR" -type d -name plugins -print0)
fi

if [[ -z "$CORE_DIR" ]]; then
  echo "Failed to locate plugins directory inside archive $ARCHIVE_PATH" >&2
  exit 1
fi

CORE_DIR="$(cd "$CORE_DIR" && pwd)"

echo "Using archive: $ARCHIVE_PATH" >&2
echo "Extracted core to: $CORE_DIR" >&2

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "core-root=$CORE_DIR"
    echo "archive=$ARCHIVE_PATH"
  } >> "$GITHUB_OUTPUT"
fi

printf '%s\n' "$CORE_DIR"
