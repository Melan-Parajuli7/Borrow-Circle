import useAuth from "../../hooks/useAuth";
import Button from "./Button";
import Icon from "./icons";
import styles from "../layout/layout.module.css";

// Top bar: mobile menu trigger (hidden on desktop, where the sidebar is
// always visible), the signed-in admin, and the logout action.
export default function Header({ onMenuToggle }) {
  const { user, logout } = useAuth();

  return (
    <header className={styles.header}>
      <button
        type="button"
        className={styles["header-menu"]}
        onClick={onMenuToggle}
        aria-label="Toggle navigation"
      >
        <Icon name="menu" size={18} />
      </button>

      <div className="grow" />

      <div className={styles["header-user"]}>
        <div className={styles["header-avatar"]}>
          {(user?.full_name || "A").slice(0, 1).toUpperCase()}
        </div>
        <div className={styles["header-user-text"]}>
          <div className={styles["header-name"]}>{user?.full_name}</div>
          <div className={styles["header-role"]}>{user?.email}</div>
        </div>
      </div>

      <Button variant="ghost" size="sm" onClick={logout}>
        <Icon name="logout" size={16} />
        Log out
      </Button>
    </header>
  );
}