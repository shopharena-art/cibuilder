#!/usr/bin/env bash
# آپلود لاگ و خروجی‌ها به draft release موقت.
# (دانلود از release پایدارتر از artifact است؛ artifact گاهی خطای 503 می‌دهد.)
set -uo pipefail

if [ -z "${RELEASE_ID:-}" ]; then
  echo "RELEASE_ID تنظیم نشده؛ آپلود به release انجام نشد."
  exit 0
fi

PY=$(command -v python3 || command -v python)

up() {
  local f="$1" n
  n=$("$PY" -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$2")
  for i in 1 2 3; do
    if curl -fsS -X POST \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$f" \
      "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets?name=$n" > /dev/null; then
      echo "uploaded: $2"
      return 0
    fi
    sleep 3
  done
  echo "upload failed: $2"
  return 0
}

[ -f build.log ] && up build.log log.txt

if [ -d out ]; then
  for f in out/*; do
    [ -f "$f" ] && up "$f" "out-$(basename "$f")"
  done
fi
exit 0
