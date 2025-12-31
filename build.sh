#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="${APP_NAME:-OpenInTerminal}"
SRC="${ROOT_DIR}/src/OpenInTerminal.applescript"
OUT_DIR="${ROOT_DIR}/dist"
APP_PATH="${OUT_DIR}/${APP_NAME}.app"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"

BUNDLE_ID="${BUNDLE_ID:-com.vvicat.openinterminal}"
LSUI_ELEMENT="${LSUI_ELEMENT:-false}"

ICON_SRC="/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns"

if [[ ! -f "${SRC}" ]]; then
  echo "未找到脚本源文件：${SRC}" >&2
  exit 1
fi

rm -rf "${APP_PATH}"
mkdir -p "${OUT_DIR}"

echo "编译脚本应用：${APP_PATH}"
osacompile -o "${APP_PATH}" "${SRC}"

if [[ -f "${INFO_PLIST}" ]]; then
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string \"${BUNDLE_ID}\"" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier \"${BUNDLE_ID}\"" "${INFO_PLIST}"

  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string \"1.0.0\"" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \"1.0.0\"" "${INFO_PLIST}"

  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string \"1\"" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion \"1\"" "${INFO_PLIST}"

  # 是否隐藏 Dock/⌘Tab 图标（默认 false，更贴近 Go2Shell 行为，且更利于排障）
  /usr/libexec/PlistBuddy -c "Add :LSUIElement bool ${LSUI_ELEMENT}" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :LSUIElement ${LSUI_ELEMENT}" "${INFO_PLIST}"

  # 自动化权限提示文案（控制 Finder/System Events）
  AE_DESC="用于从 Finder 获取当前目录，并在 Terminal 中打开。"
  /usr/libexec/PlistBuddy -c "Add :NSAppleEventsUsageDescription string \"${AE_DESC}\"" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :NSAppleEventsUsageDescription \"${AE_DESC}\"" "${INFO_PLIST}"
fi

# 默认使用系统 Terminal 图标（可按需替换）
if [[ -f "${ICON_SRC}" ]]; then
  ICON_FILE="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "${INFO_PLIST}" 2>/dev/null || echo "applet")"
  ICON_DST="${APP_PATH}/Contents/Resources/${ICON_FILE}.icns"
  cp "${ICON_SRC}" "${ICON_DST}"
fi

touch "${APP_PATH}"

# 由于我们修改了 Info.plist / 图标，重新做一次 ad-hoc 签名，避免出现“invalid Info.plist”。
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "${APP_PATH}" >/dev/null 2>&1 || true
fi

echo "完成：${APP_PATH}"
