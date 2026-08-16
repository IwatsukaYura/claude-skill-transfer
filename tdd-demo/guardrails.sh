#!/usr/bin/env bash
# TDDデモ用のガードレール着脱。
#
#   ./guardrails.sh on       全部入り（CLAUDE.md + skill + agent + hooks 3本）
#   ./guardrails.sh off      素の Claude Code
#   ./guardrails.sh status   いまどちらか
#   ./guardrails.sh reset    app/ を開始状態に戻す（実装とテストを消す）
#
# 実体は guardrails/（app/ の外）にある。
# app/ の中に置くと、OFF のときでも Claude がフックのソースを読んで
# 自主的にTDDを始めてしまい「無い状態」が再現できない。
set -euo pipefail

cd "$(dirname "$0")"
SRC="guardrails"
APP="app"
DST="$APP/.claude"

die() { echo "エラー: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq が必要です。'brew install jq' を実行してください。"

# 自分の ~/.claude/CLAUDE.md がデモに混入すると OFF が再現しない
write_local_settings() {
  mkdir -p "$DST"
  if [ "${GUARDRAILS_NO_ISOLATE:-0}" = "1" ]; then
    jq -n '{}' > "$DST/settings.local.json"
  else
    jq -n --arg home "$HOME" '{
      claudeMdExcludes: [
        ($home + "/.claude/CLAUDE.md"),
        ($home + "/.claude/rules/**")
      ]
    }' > "$DST/settings.local.json"
  fi
}

case "${1:-status}" in
  on)
    rm -rf "$DST"
    mkdir -p "$DST/hooks"
    cp "$SRC/CLAUDE.md"    "$DST/CLAUDE.md"
    cp "$SRC/settings.json" "$DST/settings.json"
    mkdir -p "$DST/skills" "$DST/agents"
    cp -R "$SRC/skills/." "$DST/skills/"
    cp -R "$SRC/agents/." "$DST/agents/"
    cp "$SRC"/hooks/*.sh "$DST/hooks/"
    chmod +x "$DST"/hooks/*.sh
    write_local_settings
    rm -f "$APP/.tdd-state"
    echo "ガードレール: ON"
    echo "  CLAUDE.md / skills(tdd) / agents(test-designer) / hooks 3本"
    ;;

  off)
    rm -rf "$DST"
    write_local_settings
    rm -f "$APP/.tdd-state"
    echo "ガードレール: OFF（素の Claude Code）"
    ;;

  reset)
    rm -f "$APP/src/invoice.ts" "$APP/tests/invoice.test.ts" "$APP/.tdd-state"
    rm -rf "$APP/dist"
    ( cd "$APP" && npm test 2>&1 | grep -E '^# (pass|fail)' )
    echo "app/ を開始状態に戻しました（money のテスト3本だけが緑）"
    ;;

  status)
    if [ -f "$DST/settings.json" ]; then
      echo "ガードレール: ON"
      echo "  hooks: $(jq -r '.hooks | to_entries | map("\(.key)(\(.value | map(.hooks | length) | add))") | join(" ")' "$DST/settings.json")"
      echo "  skills: $(ls "$DST/skills" 2>/dev/null | tr '\n' ' ')"
      echo "  agents: $(ls "$DST/agents" 2>/dev/null | sed 's/\.md//' | tr '\n' ' ')"
    else
      echo "ガードレール: OFF"
    fi
    echo "─────────────────────────────────────────"
    echo "app/ の状態:"
    [ -f "$APP/src/invoice.ts" ]        && echo "  [x] src/invoice.ts"        || echo "  [ ] src/invoice.ts"
    [ -f "$APP/tests/invoice.test.ts" ] && echo "  [x] tests/invoice.test.ts" || echo "  [ ] tests/invoice.test.ts"
    if [ -f "$APP/.tdd-state" ]; then echo "  テスト: $(head -1 "$APP/.tdd-state")"; fi
    ;;

  *)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
