---
# 必須。小文字とハイフン。hook には agent_type として渡る
name: my-agent

# 必須。★いつ委譲すべきか。Claude はこれだけを見て判断する
description: <どんなときにこのエージェントに任せるか>。<何を返すか>。

# 使えるツールを絞る。絞ることがそのまま制約になる。
# 調査役に Edit を渡さない。省略すると全ツールを継承する
tools: Read, Grep, Glob, Bash

# sonnet / opus / haiku / fable / モデルID / inherit（既定）
# 軽い仕事は haiku にするとコストが下がる
model: inherit

# 起動時に本文ごとプリロードする skill。
# 会話履歴は継承されないので、規約を届けたいならここで渡す
# skills:
#   - team-conventions

# セッションの effort を上書き: low / medium / high / xhigh / max
# effort: high

# 一時 git worktree で実行する。並列編集の衝突回避
# isolation: worktree

# 永続メモリ: user / project / local
# memory: project

# タスク一覧での表示色
color: blue
---

あなたは <役割> です。

<!--
起動時にこのエージェントの文脈に載るもの:
  - このファイルの本文（＝システムプロンプト。Claude Code のフル版ではない）
  - 親が書いた委譲メッセージ
  - CLAUDE.md 階層と .claude/rules/
  - skills: に書いた skill の全文
  - git status のスナップショット

載らないもの:
  - 会話履歴 ← 一番重要。渡す情報は自分で設計する
  - 親の auto memory
  - output style
-->

## 手順

1. <最初にやること>
2. <次にやること>

## 報告してよいもの（これ以外は報告しない）

- <観点1>
- <観点2>

## 報告してはいけないもの

- スタイル・命名・整形の好み
- 「〜した方が保守しやすい」といった一般論
- 起こり得ないケースへの防御コードの提案
- 抽象化層の追加提案

**指摘が1つも無いことは正常な結果です。無理に見つけないでください。**

<!--
この最後の1行が無いと、「ギャップを探せ」と言われたレビュアーは
健全なコードにも必ず何かをでっち上げる。それを全部潰しに行くと過剰設計になる。
-->

## 出力形式

<固定の形式を指定する>
