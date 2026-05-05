#!/bin/bash
MSG="${1:-Task completed}"
# Escape double quotes and newlines for JSON
MSG_ESCAPED=$(echo "$MSG" | sed 's/"/\\"/g' | tr '\n' ' ')

curl -s -X POST \
  -H "api-key: bet-bot-api-key-2026" \
  -H "Content-Type: application/json" \
  "https://bot-prod.microsoftlionrock.com/api/messages/send" \
  -d "{\"userName\":\"Hai Chang\",\"message\":{\"type\":\"text\",\"text\":\"[RateBar] ${MSG_ESCAPED}\"}}"
