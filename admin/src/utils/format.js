// Display formatters shared by the dashboard pages.

export const formatDateTime = (value) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

export const formatDate = (value) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
};

export const timeAgo = (value) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  const seconds = Math.round((Date.now() - d.getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days}d ago`;
  return formatDate(d);
};

export const formatNumber = (value) =>
  new Intl.NumberFormat().format(Number(value) || 0);

export const truncate = (text, max = 60) => {
  if (!text) return "";
  return text.length > max ? `${text.slice(0, max)}…` : text;
};

export const titleCase = (text) =>
  String(text || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());

// Badge tones: which colour a status/label should use.
const TONES = {
  // requests
  pending: "warning",
  approved: "success",
  rejected: "error",
  cancelled: "neutral",
  // loans
  active: "success",
  overdue: "error",
  returned: "neutral",
  awaiting_handover: "warning",
  on_loan: "success",
  // users
  admin: "primary",
  user: "neutral",
  // availability
  available: "success",
  unavailable: "error",
  // reviews
};

export const statusTone = (status) => TONES[status] ?? "neutral";

export const isAvailable = (item) => (item?.is_available ? "available" : "unavailable");