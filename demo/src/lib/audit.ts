/**
 * 監査ログ。金額を含むレスポンスの参照を記録する。
 * 監査要件で全社的に義務付けられているが、呼び出しは各ハンドラの責務。
 */
type AuditEvent = {
  actor: string;
  action: string;
  resource: string;
  at: string;
};

const events: AuditEvent[] = [];

export const audit = {
  recordAccess(actor: string, action: string, resource: string): void {
    events.push({ actor, action, resource, at: new Date().toISOString() });
  },

  /** テストと運用調査用 */
  drain(): AuditEvent[] {
    return events.splice(0, events.length);
  },
};
