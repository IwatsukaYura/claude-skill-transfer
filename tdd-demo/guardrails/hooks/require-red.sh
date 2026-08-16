#!/usr/bin/env bash
# PreToolUse — 失敗しているテストが無い状態では src/ を編集させない。

set -euo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

[ -n "$path" ] || exit 0

# 相対パスに正規化
root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${path#"$root"/}"

case "$rel" in
  tests/*)  exit 0 ;;   # テストは常に書ける
  src/*)    ;;          # 判定対象
  *)        exit 0 ;;   # SPEC.md・設定ファイルなどは対象外
esac

decide() {
  jq -n --arg d "$1" --arg r "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

cd "$root"


state_file=".tdd-state"
if [ -f "$state_file" ]; then
  state=$(head -1 "$state_file")
else
  if npm test >/dev/null 2>&1; then state="green"; else state="red"; fi
  printf '%s\n' "$state" > "$state_file"
fi

if [ "$state" = "red" ]; then
  # 失敗しているテストがある = 実装フェーズ
  exit 0
fi

failing=$(sed -n '2,6p' "$state_file" 2>/dev/null || true)

decide "ask" "$(cat <<EOS
require-red フック: いまテストは全部通っています（Green）。

TDD では Green の状態で src/ を編集するのは「リファクタ」のときだけです。

- **新しい振る舞いを足すなら**: まず tests/ に失敗するテストを1本書いてください。
  Red になればこのフックは自動的に通します。
- **リファクタなら**: 承認してください。振る舞いを変えないこと。

編集しようとしたファイル: ${rel}
EOS
)"
