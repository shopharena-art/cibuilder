#!/usr/bin/env bash
# دانلود زیپ از draft release، باز کردن آن و بارگذاری secretها در محیط
set -euo pipefail

PY=$(command -v python3 || command -v python)

curl -fsSL \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/octet-stream" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/assets/$ASSET_ID" \
  -o src.zip

rm -rf proj
mkdir proj
"$PY" -m zipfile -e src.zip proj
rm -f src.zip

# هر خط فایل secret به شکل KEY:BASE64VALUE است
if [ -f proj/.build-secrets.env ]; then
  while IFS=: read -r k v || [ -n "$k" ]; do
    [ -z "$k" ] && continue
    val=$(printf '%s' "$v" | base64 -d)
    while IFS= read -r line; do
      [ -n "$line" ] && echo "::add-mask::$line"
    done <<< "$val"
    d="EOF_${RANDOM}${RANDOM}${RANDOM}"
    {
      echo "$k<<$d"
      printf '%s\n' "$val"
      echo "$d"
    } >> "$GITHUB_ENV"
  done < proj/.build-secrets.env
  rm -f proj/.build-secrets.env
  echo "secrets loaded"
fi
