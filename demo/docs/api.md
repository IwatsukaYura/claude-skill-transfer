# API リファレンス

この表が公開ドキュメントの生成元。**ここに無いエンドポイントは存在しないものとして扱われる。**

## エンドポイント

| メソッド | パス | ハンドラ | 認可 | 監査ログ |
|---|---|---|---|---|
| GET | `/orders` | `listOrders` | 自分の注文のみ | 不要 |
| GET | `/orders/:id` | `getOrder` | 所有者のみ | 必要 |
| POST | `/orders/:id/cancel` | `cancelOrder` | 所有者のみ | 必要 |

## エラーコード

| code | HTTP | 意味 |
|---|---|---|
| `not_found` | 404 | リソースが存在しない |
| `forbidden` | 403 | 権限が無い |
| `invalid_request` | 400 | リクエストが不正 |
| `internal` | 500 | サーバー内部エラー |
