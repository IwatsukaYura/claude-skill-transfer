---
name: my-skill
description: <何をするか>。「<言い方1>」「<言い方2>」と言われたときに使う。<どんな形で返すか>。

argument-hint: "[引数の説明]"
disable-model-invocation: true

# そのターンだけ権限を事前承認する
allowed-tools: Bash(npm run *) Read Grep

# user-invocable: false   # / メニューに出さない
# disallowed-tools: AskUserQuestion
# model: haiku
# context: fork           # 隔離コンテキストで実行する
---

# <スキル名>

## 前提

<このスキルが成立するための前提。他人の環境で動かすとここで壊れる>

## 手順

**すべて実行する。途中で失敗しても止めず、最後までやってから結果をまとめる。**

### 1. <手順1>

```bash
<コマンド>
```

### 2. <手順2>

<Claude が推測で辿り着けない、プロジェクト固有の手順をここに書く>

## 報告の形式

**必ずこの形で報告する。項目を減らしたり順番を変えたりしない。**

```
| # | 項目 | 結果 | 詳細 |
|---|---|---|---|
| 1 | ... | OK / NG | |

判定: <結論>
```
