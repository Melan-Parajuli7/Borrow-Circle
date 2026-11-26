import api from "./axios";

// Auth lives on /api/users (shared with the mobile app); cookies carry the
// tokens, so the admin app only stores the user profile in memory.
export const login = (credentials) => api.post("/users/login", credentials);
export const logout = () => api.post("/users/logout");
export const getMe = () => api.get("/users/me");