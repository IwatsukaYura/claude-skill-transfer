#!/usr/bin/env bash
# Stop — テストが緑で、かつ実装だけを足していない状態でなければ終わらせない。

set -uo pipefail

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"')
stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
[ "$stop_active" = "true" ] && exit 0

counter="${TMPDIR:-/tmp}/tdd-gate-${session}"
count=$(cat "$counter" 2>/dev/null || echo 0)
[ "$count" -ge 3 ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root"

block() {
  echo $((count + 1)) > "$counter"
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

# ① テストが通るか
if ! output=$(npm test 2>&1); then
  detail=$(printf '%s' "$output" | grep -E '^not ok |AssertionError|expected:|actual:|^# fail' | head -12)
  block "$(printf 'tdd-gate: テストが失敗しています。通してから終了してください。\n\n%s' "$detail")"
fi

# ② テストの無い実装ファイルが無いか
allow_file=".tdd-gate-allow"
is_allowed() {
  [ -f "$allow_file" ] || return 1
  { sed 's/#.*//' "$allow_file" | tr -d ' \t' | grep -Fxq "$1"; } 2>/dev/null
}

missing=""
for f in src/*.ts; do
  [ -e "$f" ] || continue
  is_allowed "$f" && continue
  mod=$(basename "$f" .ts)
  if ! { grep -rl "src/${mod}\.js" tests/ 2>/dev/null || true; } | read -r _; then
    missing="${missing} $f"
  fi
done

if [ -n "$missing" ]; then
  block "$(cat <<EOS
tdd-gate: テストから参照されていない実装ファイルがあります。

$(for m in $missing; do echo "  - $m"; done)

TDD では実装はテストが要求したから存在します。
tests/ のどこからも import されていない実装は、要求されていないコードです。

対応は次のどれか:
  1. その振る舞いを固定するテストを tests/ に足す
  2. 要らないコードなら削除する
  3. 振る舞いを持たない宣言（型・エラークラス・定数）なら .tdd-gate-allow に登録する
  4. それ以外の理由で例外にするなら、理由を報告に書いてもう一度終了する
     （このフックは同一セッション3回までしかブロックしません）
EOS
)"
fi

rm -f "$counter"
exit 0
