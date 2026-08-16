# TDDデモ — 全部揃った状態で1サイクル回す

研修の締め。CLAUDE.md / Skill / Subagent / Hooks が**同時に**働くとどうなるかを見る。

`demo/` とは別の独立した環境。ガードレールの着脱も専用の `guardrails.sh` を使う。

---

## 動かす

準備:

```bash
./setup.sh
```

いま何が有効かを見る:

```bash
./guardrails.sh status
```

全部外す / 全部入れる:

```bash
./guardrails.sh off
./guardrails.sh on
```

開始状態に戻す:

```bash
./guardrails.sh reset
```

`reset` は `app/src/invoice.ts` と `app/tests/invoice.test.ts` を消す。
**OFF と ON を切り替えるたびに `reset` する。** 前の実行の成果物が残っていると比較にならない。

起動は `app/` をカレントにする:

```bash
cd app && claude
```

## 採点

`acceptance/spec.test.ts` は **SPEC.md だけを根拠に**書いた受け入れテスト。
実装を見ずに作ってあるので、OFF と ON を同じ基準で採点できる。

```bash
cp acceptance/spec.test.ts app/tests/_spec.test.ts && (cd app && npm test)
rm app/tests/_spec.test.ts
```

## 構成

```
tdd-demo/
├── setup.sh
├── guardrails.sh          on / off / status / reset
│
├── app/                   ★ Claude が見るのはここだけ
│   ├── SPEC.md            仕様書
│   ├── src/money.ts       円未満の扱いを集約。既存・テスト済み
│   ├── src/errors.ts      InvoiceError
│   ├── tests/money.test.ts  3本。開始時はここだけが緑
│   └── .tdd-gate-allow    Stop フックの除外リスト
│
├── acceptance/
│   └── spec.test.ts       SPECのみを根拠にした受け入れテスト（採点用）
│
└── guardrails/            app/ の外（OFF のとき中身を見せないため）
    ├── CLAUDE.md
    ├── skills/tdd/SKILL.md        Red→Green→Refactor の固定手順
    ├── agents/test-designer.md    仕様書だけを読んでケースを列挙。tools に Edit 無し
    ├── settings.json
    └── hooks/
        ├── require-red.sh   PreToolUse  ★Red が無いと src/ を編集できない
        ├── run-tests.sh     PostToolUse  編集後に自動でテスト実行→結果を返す
        └── tdd-gate.sh      Stop         緑でない／テストの無い実装があると終われない
```

## フック3本の役割分担

| フック                      | 塞ぐ抜け道                                              |
| --------------------------- | ------------------------------------------------------- |
| `require-red`（PreToolUse） | テストを書く前に実装を書く                              |
| `run-tests`（PostToolUse）  | テスト実行を人間の承認待ちにする（＝往復が増える）      |
| `tdd-gate`（Stop）          | 落ちたまま「できました」と言う / テストの無い実装を残す |

