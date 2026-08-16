#!/usr/bin/env bash
# ガードレールを1枚ずつ着脱するためのスクリプト。
#
#   ./guardrails.sh status                いま何が有効か
#   ./guardrails.sh off                   全部外す（＝素の Claude Code）
#   ./guardrails.sh only <layer>...       ★これを使う。off してから有効化する
#   ./guardrails.sh on   <layer>...       加算的に足す（積み上げたいときだけ）
#
# レイヤー:
#   claudemd          CLAUDE.md
#   skill             release-check スキル
#   agent             diff-reviewer サブエージェント
#   hook-migrations   PreToolUse: 適用済みマイグレーションの書き換えをブロック ★デモ4の主役
#   hook-tests        PreToolUse: テストの削除・skip をブロック
#   hook-lint         PostToolUse: 編集後チェックを Claude に返す ★デモ4の主役
#   hook-testgate     Stop: テストが通るまで終わらせない
#   hook-worktree     PreToolUse: 未コミットの作業を破棄する git 操作をブロック（付録）
#   hook-secrets      PreToolUse: 秘密情報ファイルへの書き込みをブロック（付録）
#   hooks             上記フック6種まとめて
#   all               全部
#
# 実体は guardrails/（demo の外）にあり、有効化すると demo/.claude/ にコピーされる。
# demo/ の中に置かないのは、OFF のとき Claude にガードレールの中身を見せないため。
# 切り替えたら Claude Code のセッションを開き直すこと（設定は起動時に読まれる）。
set -euo pipefail

cd "$(dirname "$0")"
SRC="guardrails"
DST="demo/.claude"

LAYERS=(claudemd skill agent hook-migrations hook-worktree hook-tests hook-lint hook-testgate hook-secrets)
HOOK_LAYERS=(hook-migrations hook-worktree hook-tests hook-lint hook-testgate hook-secrets)

die() { echo "エラー: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq が必要です。'brew install jq' を実行してください。"

# ---------------------------------------------------------------- 隔離設定
# 自分の ~/.claude/CLAUDE.md や ~/.claude/rules/ がデモに混入すると、
# 「ガードレール無し」の状態が再現しない。ここで明示的に除外する。
write_local_settings() {
  mkdir -p "$DST"
  if [ "${GUARDRAILS_NO_ISOLATE:-0}" = "1" ]; then
    jq -n '{}' > "$DST/settings.local.json"
    return
  fi
  jq -n --arg home "$HOME" '{
    claudeMdExcludes: [
      ($home + "/.claude/CLAUDE.md"),
      ($home + "/.claude/rules/**")
    ]
  }' > "$DST/settings.local.json"
}

# ------------------------------------------------------------ 各レイヤー
enabled() {
  case "$1" in
    claudemd)       [ -f "$DST/CLAUDE.md" ] ;;
    skill)          [ -d "$DST/skills" ] ;;
    agent)          [ -d "$DST/agents" ] ;;
    hook-*)         [ -f "$DST/.enabled-$1" ] ;;
    *)              return 1 ;;
  esac
}

enable_layer() {
  local layer="$1"
  mkdir -p "$DST"
  case "$layer" in
    claudemd) cp "$SRC/CLAUDE.md" "$DST/CLAUDE.md" ;;
    skill)    mkdir -p "$DST/skills" && cp -R "$SRC/skills/." "$DST/skills/" ;;
    agent)    mkdir -p "$DST/agents" && cp -R "$SRC/agents/." "$DST/agents/" ;;
    hook-*)
      mkdir -p "$DST/hooks"
      cp "$SRC"/hooks/*.sh "$DST/hooks/"
      chmod +x "$DST"/hooks/*.sh
      touch "$DST/.enabled-$layer"
      ;;
    *) die "不明なレイヤー: $layer（有効: ${LAYERS[*]} hooks all）" ;;
  esac
}

# 有効になっているフックの設定断片をマージして settings.json を作る
rebuild_settings() {
  local frags=()
  for layer in "${HOOK_LAYERS[@]}"; do
    [ -f "$DST/.enabled-$layer" ] && frags+=("$SRC/hooks/settings.$layer.json")
  done

  if [ ${#frags[@]} -eq 0 ]; then
    rm -f "$DST/settings.json"
    return
  fi

  # hooks.<イベント> は配列。同じイベントに複数の断片が来たら連結する。
  jq -s 'reduce .[] as $f ({hooks: {}};
           .hooks = (reduce ($f.hooks | to_entries[]) as $e (.hooks;
             .[$e.key] = ((.[$e.key] // []) + $e.value))))' \
    "${frags[@]}" > "$DST/settings.json"
}

expand() {
  case "$1" in
    all)   printf '%s\n' "${LAYERS[@]}" ;;
    hooks) printf '%s\n' "${HOOK_LAYERS[@]}" ;;
    *)     printf '%s\n' "$1" ;;
  esac
}

# ------------------------------------------------------------------ 本体
cmd="${1:-status}"

case "$cmd" in
  off)
    rm -rf "$DST"
    write_local_settings
    echo "ガードレール: 全部OFF（素の Claude Code）"
    ;;

  only|on)
    # only = off してから on。デモの切り替えでは基本こちらを使う（on は加算的なので）
    if [ "$cmd" = "only" ]; then rm -rf "$DST"; fi
    shift || true
    [ $# -gt 0 ] || die "レイヤーを指定してください（${LAYERS[*]} hooks all）"
    for arg in "$@"; do
      while IFS= read -r layer; do
        enable_layer "$layer"
        echo "有効化: $layer"
      done < <(expand "$arg")
    done
    rebuild_settings
    write_local_settings
    ;;

  status)
    echo "ガードレールの状態  (demo/.claude/)"
    echo "─────────────────────────────────────────"
    for layer in "${LAYERS[@]}"; do
      if enabled "$layer"; then printf '  [x] %s\n' "$layer"; else printf '  [ ] %s\n' "$layer"; fi
    done
    echo "─────────────────────────────────────────"
    if [ "${GUARDRAILS_NO_ISOLATE:-0}" = "1" ]; then
      echo "  個人設定の隔離: OFF（~/.claude/CLAUDE.md が混入します）"
    else
      echo "  個人設定の隔離: ON（~/.claude/CLAUDE.md と rules/ を除外中）"
    fi
    ;;

  *)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
