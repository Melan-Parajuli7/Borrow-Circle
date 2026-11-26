import axios from "axios";

// Credentials: the API keeps the JWT in httpOnly cookies, so the browser
// must be told to send them on every call (including cross-origin ones).
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000/api",
  withCredentials: true,
  headers: { "Content-Type": "application/json" },
});

// One refresh call shared by every request that hits an expired token.
let refreshPromise = null;

const refreshSession = () => {
  if (!refreshPromise) {
    refreshPromise = axios
      .post(
        `${api.defaults.baseURL}/users/refresh`,
        {},
        { withCredentials: true },
      )
      .finally(() => {
        refreshPromise = null;
      });
  }
  return refreshPromise;
};

const isAuthEndpoint = (url = "") =>
  url.includes("/users/login") ||
  url.includes("/users/refresh") ||
  url.includes("/users/logout");

// The API answers 401 with code "TOKEN_EXPIRED" when the access token aged
// out: refresh once (new cookies) and replay the original request.
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const config = error.config || {};
    const status = error.response?.status;
    const expired = error.response?.data?.code === "TOKEN_EXPIRED";

    if (
      status === 401 &&
      expired &&
      !config._retried &&
      !isAuthEndpoint(config.url)
    ) {
      config._retried = true;
      try {
        await refreshSession();
        return api(config);
      } catch {
        // refresh token is dead too — the UI falls back to the login screen
      }
    }
    return Promise.reject(error);
  },
);

// Turns any thrown error into a short human message for banners.
export const errorMessage = (error) =>
  error?.response?.data?.message ||
  error?.message ||
  "Something went wrong. Please try again.";

export default api;