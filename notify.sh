#!/bin/sh
# notify.sh — fan out task completion to webhook + Telegram
set -u

LAST_COMMIT="$(git log -n 1 --pretty=format:'%h %s' 2>/dev/null || echo 'no commit')"
PROJECT_DIR_NAME="$(basename "$(pwd)")"

# 1) original webhook
./codex-web-notify.sh "$(git log -n 1 2>/dev/null)" || true

# 2) Telegram via openclaw
if command -v openclaw >/dev/null 2>&1; then
  openclaw message send \
    --channel telegram \
    --target 8698274873 \
    --message "🤖 [${PROJECT_DIR_NAME}] ${LAST_COMMIT}" \
    --silent >/dev/null 2>&1 || true
fi
