import { useCallback, useEffect, useState } from "react";
import { errorMessage } from "../api/axios";

// Minimal data-fetching hook: runs `fetcher` whenever `deps` change and
// exposes { data, loading, error, reload } for the pages.
//
// Note: no "mounted" ref is used on purpose. Under React StrictMode (dev)
// effects run twice — mount, cleanup, mount — and a ref would stay false
// after the simulated unmount, silently swallowing every response. React
// ignores setState on unmounted components, so nothing needs guarding.
const useApi = (fetcher, deps = []) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    return Promise.resolve(fetcher())
      .then((res) => setData(res.data))
      .catch((err) => setError(errorMessage(err)))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    load();
  }, [load]);

  return { data, loading, error, reload: load };
};

export default useApi;