#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="${APP_NAME:-OpenInTerminal}"
APP_PATH="${ROOT_DIR}/dist/${APP_NAME}.app"

DEST_DIR="${1:-${HOME}/Applications}"
DEST_APP_PATH="${DEST_DIR}/${APP_NAME}.app"

mkdir -p "${DEST_DIR}"
rm -rf "${DEST_APP_PATH}"
cp -R "${APP_PATH}" "${DEST_APP_PATH}"

# 如果是从网络下载/拷贝导致有隔离属性，尝试移除（失败不影响使用）
xattr -dr com.apple.quarantine "${DEST_APP_PATH}" 2>/dev/null || true

echo "已安装：${DEST_APP_PATH}"
echo "下一步：在 Finder 工具栏上按住 ⌘，把该应用拖进去作为按钮。"

