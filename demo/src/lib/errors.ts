/**
 * このAPIの唯一のエラー表現。
 * 全ハンドラはこの形でエラーを返すことになっている（が、守られていない箇所がある）。
 */
export type ApiErrorCode =
  | "not_found"
  | "forbidden"
  | "invalid_request"
  | "internal";

export class ApiError extends Error {
  constructor(
    readonly code: ApiErrorCode,
    message: string,
    readonly status: number,
  ) {
    super(message);
    this.name = "ApiError";
  }

  static notFound(what: string): ApiError {
    return new ApiError("not_found", `${what} が見つかりません`, 404);
  }

  static forbidden(reason: string): ApiError {
    return new ApiError("forbidden", reason, 403);
  }

  static invalidRequest(reason: string): ApiError {
    return new ApiError("invalid_request", reason, 400);
  }
}

export type ApiErrorBody = {
  error: { code: ApiErrorCode; message: string };
};

export function toErrorBody(err: ApiError): ApiErrorBody {
  return { error: { code: err.code, message: err.message } };
}
