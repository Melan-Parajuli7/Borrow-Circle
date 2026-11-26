import { useState } from "react";

// Page/limit state for the list screens. `reset()` goes back to page 1 when
// a filter changes, and `queryParams()` merges in the extra filters.
const usePagination = (initialLimit = 20) => {
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(initialLimit);

  const goTo = (next) => {
    const n = Number(next);
    if (Number.isInteger(n) && n >= 1) setPage(n);
  };

  return {
    page,
    limit,
    setPage: goTo,
    setLimit: (next) => {
      setLimit(Number(next) || initialLimit);
      setPage(1);
    },
    reset: () => setPage(1),
    queryParams: (extra = {}) => ({ page, limit, ...extra }),
  };
};

export default usePagination;