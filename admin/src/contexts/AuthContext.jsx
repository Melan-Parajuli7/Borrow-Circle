import { createContext, useCallback, useEffect, useState } from "react";
import * as authApi from "../api/auth";

// Session state for the whole dashboard. The tokens stay in httpOnly cookies;
// only the profile (id, email, full_name, role) is kept in memory here.
const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true); // true while restoring the session

  // Restore the session once on mount: a valid cookie means "still logged in".
  useEffect(() => {
    let alive = true;
    authApi
      .getMe()
      .then(({ data }) => {
        if (alive) setUser(data.user);
      })
      .catch(() => {
        if (alive) setUser(null);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, []);

  const login = useCallback(async (credentials) => {
    const { data } = await authApi.login(credentials);
    setUser(data.user);
    return data.user;
  }, []);

  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } finally {
      setUser(null);
    }
  }, []);

  const value = {
    user,
    loading,
    isAdmin: user?.role === "admin",
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export default AuthContext;