/**
 * FNV-1a 64-bit checksum for content-pack integrity verification.
 *
 * Canonicalization contract (must match Dart implementation exactly):
 * 1. Build the pack object WITHOUT the `checksum` field.
 * 2. Sort ALL object keys alphabetically at every nesting level (recursive).
 * 3. Serialize to JSON with 2-space indentation and NO trailing newline.
 * 4. Encode as UTF-8 bytes.
 * 5. Compute FNV-1a 64-bit over those bytes.
 * 6. Format as `fnv1a64:<16 lowercase hex digits>`.
 */

const OFFSET_BASIS = BigInt("14695981039346656037");
const PRIME = BigInt("1099511628211");
const MASK64 = (BigInt(1) << BigInt(64)) - BigInt(1);

/** Recursively sort all object keys for deterministic serialization. */
function sortKeys(obj: unknown): unknown {
  if (Array.isArray(obj)) {
    return obj.map(sortKeys);
  }
  if (obj !== null && typeof obj === "object" && !(obj instanceof Date)) {
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(obj).sort()) {
      sorted[key] = sortKeys((obj as Record<string, unknown>)[key]);
    }
    return sorted;
  }
  return obj;
}

/**
 * Produce the canonical JSON string used for checksum computation.
 *
 * - Excludes the `checksum` field.
 * - Sorts all keys alphabetically at every level.
 * - Uses 2-space indentation, no trailing newline.
 */
export function canonicalJson(pack: Record<string, unknown>): string {
  const withoutChecksum = { ...pack };
  delete withoutChecksum.checksum;
  const sorted = sortKeys(withoutChecksum);
  return JSON.stringify(sorted, null, 2);
}

/** Compute FNV-1a 64-bit hash over a UTF-8 byte array. */
function fnv1a64(bytes: Uint8Array): bigint {
  let hash = OFFSET_BASIS;
  for (const byte of bytes) {
    hash = (hash ^ BigInt(byte)) & MASK64;
    hash = (hash * PRIME) & MASK64;
  }
  return hash;
}

/** Encode a string to UTF-8 bytes. */
function utf8Bytes(s: string): Uint8Array {
  return new TextEncoder().encode(s);
}

/**
 * Compute the content-pack checksum.
 *
 * Returns a string in the format `fnv1a64:<16 lowercase hex digits>`.
 */
export function computeChecksum(pack: Record<string, unknown>): string {
  const canonical = canonicalJson(pack);
  const hash = fnv1a64(utf8Bytes(canonical));
  return `fnv1a64:${hash.toString(16).padStart(16, "0")}`;
}
