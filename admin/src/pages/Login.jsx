import { useState } from "react";
import { Navigate, useLocation } from "react-router-dom";
import useAuth from "../hooks/useAuth";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Icon from "../components/ui/icons";
import { errorMessage } from "../api/axios";
import styles from "./pages.module.css";

export default function Login() {
  const { user, isAdmin, login, logout } = useAuth();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  // Already signed in as admin? Skip the form.
  if (user && isAdmin) {
    return <Navigate to={location.state?.from || "/dashboard"} replace />;
  }

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const signedIn = await login({ email: email.trim(), password });

      // Members who are not admins authenticate fine, but this portal is
      // admins-only: end their session and explain why.
      if (signedIn?.role !== "admin") {
        await logout();
        setPassword("");
        setError(
          "Only BorrowCircle administrators can sign in through this portal. This account does not have admin access.",
        );
      }
      // admins are redirected by the check at the top on the next render
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles["login-page"]}>
      {/* decorative background blobs */}
      <span className={`${styles["login-blob"]} ${styles["login-blob-1"]}`} />
      <span className={`${styles["login-blob"]} ${styles["login-blob-2"]}`} />
      <span className={`${styles["login-blob"]} ${styles["login-blob-3"]}`} />

      <form className={styles["login-card"]} onSubmit={onSubmit}>
        <div className={styles["login-brand"]}>
          <img
            src="/borrowcircle-logo.jpeg"
            alt="BorrowCircle"
            className={styles["login-logo"]}
          />
          <div>
            <div className={styles["login-title"]}>BorrowCircle Admin</div>
            <div className={styles["login-subtitle"]}>
              Sign in with an administrator account
            </div>
          </div>
        </div>

        {error && (
          <div className={styles["login-error"]} role="alert">
            <Icon name="alert" size={16} />
            <span>{error}</span>
          </div>
        )}

        <Input
          label="Email"
          type="email"
          name="email"
          autoComplete="email"
          placeholder="admin@college.edu"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className={styles["login-input"]}
          labelClassName={styles["login-label"]}
          required
        />
        <Input
          label="Password"
          type={showPassword ? "text" : "password"}
          name="password"
          autoComplete="current-password"
          placeholder="••••••••"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className={styles["login-input"]}
          labelClassName={styles["login-label"]}
          required
          action={
            <button
              type="button"
              className={styles["login-eye"]}
              onClick={() => setShowPassword((value) => !value)}
              aria-label={showPassword ? "Hide password" : "Show password"}
              title={showPassword ? "Hide password" : "Show password"}
            >
              <Icon name={showPassword ? "eye" : "eyeOff"} size={18} />
            </button>
          }
        />

        <Button
          type="submit"
          loading={loading}
          disabled={!email || !password}
          className={styles["login-submit"]}
        >
          Sign in
        </Button>

        <p className={styles["login-footer"]}>
          Restricted area · BorrowCircle v1.0
        </p>
      </form>
    </div>
  );
}