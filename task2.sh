#!/bin/bash
set -euo pipefail
LOG_FILE="app.log"

if [ $# -lt 1 ]; then
    echo "Error: Missing required argument 'LOG_LEVEL'." >&2
    echo "Usage: $0 <LOG_LEVEL> [DATE]" >&2
    echo "Example: $0 ERROR 2026-04-06" >&2
    exit 1
fi
LOG_LEVEL=$(echo "$1" | tr '[:lower:]' '[:upper:]')

TARGET_DATE="${2:-$(date +%F)}"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Target log archive '$LOG_FILE' does not exist in the working directory." >&2
    exit 1
fi

TOTAL_COUNT=$(grep "^${TARGET_DATE} .* ${LOG_LEVEL}" "$LOG_FILE" | wc -l | xargs)

echo "Log Level: ${LOG_LEVEL}"
echo "Date: ${TARGET_DATE}"
echo "Total: ${TOTAL_COUNT}"
echo "By component:"

if [ "$TOTAL_COUNT" -gt 0 ]; then
    grep "^${TARGET_DATE} .* ${LOG_LEVEL}" "$LOG_FILE" \
        | awk '{print $4}' \
        | sort \
        | uniq -c \
        | sort -nr \
        | awk '{print $1 " " $2}'
fi