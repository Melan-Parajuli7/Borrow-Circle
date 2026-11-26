// Small helpers shared across pages.

// Drops empty values so query strings stay clean (?page=1 only).
export const buildQuery = (params = {}) => {
  const query = {};
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === "") return;
    if (typeof value === "string" && value.trim() === "") return;
    query[key] = value;
  });
  return query;
};

// Percentage for progress-ish displays, guarded against divide-by-zero.
export const percent = (part, total) => {
  if (!total) return 0;
  return Math.round((part / total) * 100);
};