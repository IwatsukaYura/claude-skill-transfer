#!/usr/bin/env bash
# migrations/*.sql の ALTER TABLE ... ADD COLUMN と
# src/db/schema.ts の型定義がズレていないか検査する。
#
# このプロジェクト固有の検査。tsc も npm test も見つけてくれない。
# つまり「Claude が推測できない手順」であり、skill にする価値があるもの。
set -uo pipefail

cd "$(dirname "$0")/.."

fail=0

while IFS= read -r column; do
  if ! grep -q "^\s*${column}\s*:" src/db/schema.ts; then
    echo "NG: migrations に列 '${column}' があるが src/db/schema.ts に無い"
    fail=1
  fi
done < <(grep -ho 'ADD COLUMN [a-z_]*' migrations/*.sql | awk '{print $3}')

if [ "$fail" -eq 0 ]; then
  echo "OK: migrations と src/db/schema.ts は同期している"
fi

exit "$fail"
