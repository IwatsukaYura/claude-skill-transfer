# 仕様: 請求金額の計算

`src/invoice.ts` に `calculateInvoice` を実装する。

```ts
type LineItem = {
  name: string;
  unitPriceJpy: number;  // 税抜・円
  quantity: number;
  taxRate: 10 | 8;       // 8 は軽減税率（飲食料品・定期購読の新聞）
};

type Coupon = {
  code: string;
  discountJpy: number;   // 税抜の小計から引く
};

type Invoice = {
  subtotalJpy: number;              // 税抜の合計（クーポン適用後）
  taxByRate: { rate: 10 | 8; taxableJpy: number; taxJpy: number }[];
  totalTaxJpy: number;
  totalJpy: number;                 // subtotalJpy + totalTaxJpy
};

function calculateInvoice(items: LineItem[], coupon?: Coupon): Invoice;
```

## ルール

**R1. 税抜小計** — 各明細の `unitPriceJpy × quantity` を合計する。

**R2. 税額は税率ごとに1回だけ計算する。**

適格請求書（インボイス）制度の要件。
税率ごとに課税対象額を合計してから、その合計に対して税額を計算する。

**R3. 端数処理は切り捨て**（円未満）。税額の計算時に1回だけ適用する。

**R4. クーポン** — `discountJpy` を税抜小計から引く。

複数税率がある場合、**割引は税率ごとの課税対象額に、課税対象額の比で按分する。**
按分後の各課税対象額は円未満を切り捨てる。

**R5. クーポンが小計以上のとき** — 小計・税額・合計はすべて 0 円。マイナスにはしない。

**R6. 明細が空** — すべて 0 円。`taxByRate` は空配列。

**R7. 不正な入力は `InvoiceError` を投げる**（`src/errors.ts` に既存）。

| 条件 | メッセージに含める語 |
|---|---|
| `quantity` が 0 以下、または整数でない | `quantity` |
| `unitPriceJpy` が負、または整数でない | `unitPriceJpy` |
| `discountJpy` が負 | `discountJpy` |

**R8. `taxByRate` の並び順** — 税率の降順（10% → 8%）。
その税率の明細が1件も無ければ、その要素は含めない。

## 具体例

### 例1: 単一税率

| 明細 | 単価 | 数量 | 税率 |
|---|---|---|---|
| ノート | 300 | 3 | 10 |

小計 900、税 90、合計 990。

### 例2: 複数税率

| 明細 | 単価 | 数量 | 税率 |
|---|---|---|---|
| 弁当 | 500 | 2 | 8 |
| 文具 | 300 | 1 | 10 |

小計 1300。
8%: 課税対象 1000、税 80。
10%: 課税対象 300、税 30。
合計 1410。`taxByRate` は 10% が先。

### 例3: クーポンの按分

| 明細 | 単価 | 数量 | 税率 |
|---|---|---|---|
| 弁当 | 500 | 2 | 8 |
| 文具 | 300 | 1 | 10 |

クーポン 200 円。小計 1300 → 1100。

按分: 8% は `200 × 1000/1300` = 153.8… → 課税対象 `1000 - 153` = 847
10% は `200 × 300/1300` = 46.1… → 課税対象 `300 - 46` = 254

（按分の端数処理をどう置くかで答えが変わる。このSPECは
「各税率の課税対象額を切り捨て」と定めている。）
