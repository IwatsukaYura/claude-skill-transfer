---
name: release-check
description: リリース前チェックを実行する。「リリース前チェック」「リリースしていいか」「出す前に確認して」「デプロイ前チェック」と言われたときに使う。5つの検査を決まった順で実行し、結果をチェックリストで報告する。
argument-hint: "[バージョン番号(任意)]"
allowed-tools: Bash(npm run *) Bash(npm test) Bash(git status) Bash(git log *) Read Grep
---

# リリース前チェック

**5つの検査を、以下の順で、1つも飛ばさずに実行する。**
途中で失敗しても止めず、最後まで実行してから結果をまとめる。

## 1. 型チェック

```bash
npm run lint
```

## 2. テスト

```bash
npm test
```

## 3. マイグレーション整合

```bash
npm run check:migrations
```

`migrations/*.sql` に足した列が `src/db/schema.ts` に反映されているかを見る。
**tsc もテストもこのズレを検知しない。** 本番でだけ落ちるので必ず実行する。

## 4. CHANGELOG の `[Unreleased]`

`CHANGELOG.md` を読み、`[Unreleased]` セクションに項目があるか確認する。
空なら **NG**（前回リリース以降の変更が記録されていない）。

## 5. 未コミットの変更

```bash
git status --porcelain
```

出力があれば **要確認**（リリース対象に入らない変更が手元に残っている）。

## 報告の形式

必ず次の表で報告する。項目を減らしたり順番を変えたりしない。

```
| # | 検査 | 結果 | 詳細 |
|---|---|---|---|
| 1 | 型チェック | OK / NG | |
| 2 | テスト | OK / NG | |
| 3 | マイグレーション整合 | OK / NG | |
| 4 | CHANGELOG [Unreleased] | OK / NG | |
| 5 | 未コミットの変更 | OK / 要確認 | |

判定: リリース可 / リリース不可
```

NG が1つでもあれば **リリース不可**。
`$ARGUMENTS` が渡されていれば、そのバージョン番号を報告の冒頭に書く。
