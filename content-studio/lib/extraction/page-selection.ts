export class PageSelectionError extends Error {}

export function parsePageSelection(value: string, maxPages = 500): number[] {
  const pages = new Set<number>();
  const parts = value.split(",").map((part) => part.trim());

  if (parts.length === 0 || parts.some((part) => part.length === 0)) {
    throw new PageSelectionError("Enter pages such as 1,3,4-6.");
  }

  for (const part of parts) {
    const match = /^(\d+)(?:-(\d+))?$/.exec(part);
    if (!match) throw new PageSelectionError(`Invalid page selection: ${part}`);

    const start = Number(match[1]);
    const end = Number(match[2] ?? match[1]);
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 1 || end < start) {
      throw new PageSelectionError(`Invalid page range: ${part}`);
    }

    for (let page = start; page <= end; page += 1) {
      if (page > maxPages) throw new PageSelectionError(`Select no more than ${maxPages} pages.`);
      if (pages.has(page)) throw new PageSelectionError(`Page ${page} was selected more than once.`);
      pages.add(page);
    }
  }

  return [...pages].sort((a, b) => a - b);
}
