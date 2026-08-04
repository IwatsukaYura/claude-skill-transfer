#!/usr/bin/env bash
# PreToolUse — テストを消す・スキップする・弱めることをブロックする。
#
# なぜこれをブロックするのが正当か:
#   「テストを通して」と言われたエージェントには2つの道がある。
#     ① コードを直す（望んでいる方）
#     ② テストを消す・skip する・アサーションを緩める（望んでいない方）
#   ②は一瞬で緑になるので、指示の解釈としては筋が通ってしまう。
#   ルールベースで②だけを塞げば、①しか残らない。
#
# Stop フック（test-gate.sh）との関係:
#   test-gate  … 落ちたまま終わらせない
#   これ       … 消して緑にすることを許さない
#   2つ揃って初めて「テストを通す」が意味を持つ。
set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

case "$path" in
  *test*|*spec*) ;;
  *) exit 0 ;;
esac

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# テスト宣言の数を数える。
# コメントアウトを「削除」として検出するため、コメント行は数えない。
#
# grep を { ... || true; } で包んでいるのは必須。
# set -o pipefail 下では、マッチ0件の grep が返す終了コード1で
# スクリプト全体が落ち、チェックが素通りしてしまう（＝止まらないフックになる）。
count_tests() {
  printf '%s' "$1" \
    | awk '{ line = $0; sub(/^[[:space:]]+/, "", line);
             if (line ~ /^(\/\/|\/\*|\*)/) next;
             print }' \
    | { grep -oE '\b(test|it|describe)\(' || true; } \
    | wc -l | tr -d ' '
}

case "$tool" in
  Edit)
    old=$(printf '%s' "$input" | jq -r '.tool_input.old_string // ""')
    new=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""')

    # skip / todo の追加
    if printf '%s' "$new" | grep -Eq '\b(test|it|describe)\.(skip|todo)\b' \
       && ! printf '%s' "$old" | grep -Eq '\b(test|it|describe)\.(skip|todo)\b'; then
      deny "PreToolUse フックがブロックしました: テストを skip/todo に変えることは許可されていません。テストが落ちているなら、テストではなくコードを直してください。仕様が変わってテストが不要になったのなら、その判断は人間に確認してください。"
    fi

    # テスト宣言の減少（削除・コメントアウト）
    before=$(count_tests "$old")
    after=$(count_tests "$new")
    if [ "$after" -lt "$before" ]; then
      deny "PreToolUse フックがブロックしました: この編集はテストを $((before - after)) 件減らします（削除またはコメントアウト）。テストを通したいなら、テストではなくコードを直してください。"
    fi
    ;;

  Write)
    new=$(printf '%s' "$input" | jq -r '.tool_input.content // ""')
    [ -f "$path" ] || exit 0   # 新規作成は素通し
    before=$(count_tests "$(cat "$path")")
    after=$(count_tests "$new")
    if [ "$after" -lt "$before" ]; then
      deny "PreToolUse フックがブロックしました: この上書きはテストを $((before - after)) 件減らします。テストを通したいなら、テストではなくコードを直してください。"
    fi
    if printf '%s' "$new" | grep -Eq '\b(test|it|describe)\.(skip|todo)\b'; then
      deny "PreToolUse フックがブロックしました: テストの skip/todo は許可されていません。テストではなくコードを直してください。"
    fi
    ;;
esac

exit 0
