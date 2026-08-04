#!/usr/bin/env bash
# PreToolUse — 未コミットの作業を破棄する git 操作をブロックする。
#
# なぜこれをブロックするのが正当か:
#   「捨てていい」と判断した人間は、いま何が未コミットかを把握していないことが多い。
#   破棄を stash に変えれば失うものは何も無く、間違いだったときに戻せる。
#   つまり「禁止」ではなく「不可逆を可逆に変える」フック。
#
# ★ここが hook の本質:
#   このフックはユーザーが明示的に「全部捨てて」と指示しても止める。
#   チームのルールが、その場の個人の指示より強い。CLAUDE.md では絶対にこうならない。
set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

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

# 1) 未コミットの変更をまとめて破棄するもの
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+(--hard|--merge)'; then
  deny "PreToolUse フックがブロックしました: git reset --hard は未コミットの作業を復元不可能に破棄します。代わりに 'git stash push -m \"<説明>\"' を使ってください。あとから 'git stash pop' で戻せます。"
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[a-z-]+[[:space:]]+)*(\.|--[[:space:]]+\.)([[:space:]]|$)'; then
  deny "PreToolUse フックがブロックしました: 作業ツリー全体の checkout/restore は、いま関係ない変更まで消します。代わりに 'git stash push -m \"<説明>\"' を使うか、対象ファイルだけを指定してください。"
fi

# 2) 未追跡ファイルの一括削除（-f が付いた clean は復元手段が無い）
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'; then
  deny "PreToolUse フックがブロックしました: git clean -f は未追跡ファイルを完全に削除します（git の履歴に残らないため復元できません）。まず 'git clean -n' で対象を確認し、消してよいか人間に確認してください。"
fi

# 3) 履歴を書き換える push
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force([^-]|$)|-f([[:space:]]|$))'; then
  deny "PreToolUse フックがブロックしました: force push は他の人のコミットを消す可能性があります。どうしても必要なら --force-with-lease を使い、人間が手元で実行してください。"
fi

# 4) 明らかに危険な rm
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)'; then
  deny "PreToolUse フックがブロックしました: rm -rf は使わないでください。削除が必要なら対象を1つずつ指定し、何を消すのかを先に報告してください。"
fi

exit 0
