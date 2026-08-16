/**
 * 金額のヘルパー。円未満の扱いはこのファイルに集約する。
 * 既存・テスト済み。請求計算はここを使うこと。
 */

/** 円未満を切り捨てる。 */
export function floorYen(amount: number): number {
  return Math.floor(amount);
}

/** 税抜額と税率(%)から税額を求める。切り捨て。 */
export function taxOf(taxableJpy: number, ratePercent: number): number {
  return floorYen((taxableJpy * ratePercent) / 100);
}

/** a を b で按分した額（切り捨て）。b が 0 なら 0。 */
export function prorate(amount: number, numerator: number, denominator: number): number {
  if (denominator === 0) return 0;
  return floorYen((amount * numerator) / denominator);
}
