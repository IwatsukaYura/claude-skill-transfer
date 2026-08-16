/** 請求計算の入力が不正なときに投げる。 */
export class InvoiceError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvoiceError";
  }
}
