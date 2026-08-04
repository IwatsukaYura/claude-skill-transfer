#!/usr/bin/env bash
# InstructionsLoaded — CLAUDE.md / rules がいつ・なぜロードされたかを記録する。
#
# rules の paths: を書いたのに発火しない、というのが一番よくある失敗。
# しかも静かに失敗するので、書いた本人は気づかない。
# このフックを入れておくと、推測ではなく観測で確認できる。
#
# 出力先: demo/.claude-instructions.log（.gitignore 済み）
# 見方:   tail -f demo/.claude-instructions.log
#
# ★実測した v2.1.220 のペイロード（公式ドキュメントの記載とは異なる）:
#   {
#     "hook_event_name": "InstructionsLoaded",
#     "file_path":        ".../.claude/rules/api-handlers.md",
#     "memory_type":      "Project",
#     "load_reason":      "path_glob_match",
#     "globs":            ["src/handlers/**/*.ts"],
#     "trigger_file_path": ".../src/handlers/orders.ts"
#   }
#   1ファイル1イベントのフラット構造。ドキュメントは instructions[] の配列形式と
#   書いているが、この版では来ない。両方に対応させてある。
#
# load_reason の意味:
#   session_start     セッション開始時に無条件でロードされた
#   path_glob_match   paths: のグロブに一致するファイルを Claude が読んだのでロードされた ★
#   nested_traversal  ディレクトリを辿る過程でロードされた
#   include           @path のインポートでロードされた
#   compact           コンテキスト圧縮のときに再注入された
set -euo pipefail

input=$(cat)
log="${CLAUDE_PROJECT_DIR:-.}/.claude-instructions.log"

printf '%s' "$input" | jq -r '
  def line(reason; type; file; globs; trigger):
    "[" + (reason // "?") + "]"
    + "\t" + (type // "?")
    + "\t" + (file // "?")
    + (if (globs | length) > 0 then "\n\tmatched glob : " + (globs | join(", ")) else "" end)
    + (if trigger then "\n\ttriggered by : " + trigger else "" end);

  if has("instructions") then
    # ドキュメント記載の配列形式（将来この形になった場合の保険）
    .instructions[]? | line(.reason; .source; .file_path; [];  null)
  else
    # v2.1.220 実測のフラット形式
    line(.load_reason; .memory_type; .file_path; (.globs // []); .trigger_file_path)
  end
' >> "$log" 2>/dev/null || true

exit 0
