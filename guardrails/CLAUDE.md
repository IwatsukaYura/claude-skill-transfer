# orders-api

注文APIのバックエンド。TypeScript / Node.js。

## コマンド

| 目的 | コマンド |
|---|---|
| ビルド | `npm run build` |
| テスト | `npm test` |
| 型チェックのみ | `npm run lint` |
| マイグレーション整合チェック | `npm run check:migrations` |

## 構成

- `src/handlers/` — HTTPハンドラ。1エンドポイント1関数
- `src/lib/errors.ts` — エラーはすべて `ApiError` で表現する
- `src/db/schema.ts` — DBの行の型。`migrations/*.sql` と**手で**同期している
- `scripts/check-migration-sync.sh` — 上記の同期を検査する

## 規約

- `any` は使わない。外部入力は `unknown` で受けて絞り込む
- エラーを握りつぶさない。握りつぶす場合は理由をコメントで書く
- 秘密情報を含むファイル（`.env` など）は編集しない
- コミットは Conventional Commits、本文は日本語
