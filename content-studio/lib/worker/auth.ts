import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";

export function requireWorkerSecret(request: NextRequest): NextResponse | null {
  const configured = process.env.WORKER_SHARED_SECRET;
  const supplied = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ?? "";
  if (!configured || !supplied) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const configuredBytes = Buffer.from(configured, "utf8");
  const suppliedBytes = Buffer.from(supplied, "utf8");
  if (configuredBytes.length !== suppliedBytes.length || !timingSafeEqual(configuredBytes, suppliedBytes)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  return null;
}

export async function readJson(request: NextRequest): Promise<Record<string, unknown>> {
  const value = await request.json();
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Request body must be an object");
  return value as Record<string, unknown>;
}
