import { NavLink } from "react-router-dom";
import Icon from "./icons";
import styles from "../layout/layout.module.css";

// Primary navigation. `collapsed` shrinks the sidebar to an icon rail
// (labels hide, active items keep their highlight). `supportBadge` shows
// unread support messages. `onNavigate` closes the mobile drawer.
const NAV = [
  { to: "/dashboard", label: "Dashboard", icon: "dashboard" },
  { to: "/users", label: "Users", icon: "users" },
  { to: "/items", label: "Items", icon: "box" },
  { to: "/requests", label: "Requests", icon: "inbox" },
  { to: "/loans", label: "Loans", icon: "calendar" },
  { to: "/reviews", label: "Reviews", icon: "star" },
  { to: "/support-chats", label: "Support Chats", icon: "chat" },
];

export default function Sidebar({
  collapsed = false,
  mobileOpen = false,
  onNavigate,
  onToggleCollapse,
  supportBadge = 0,
}) {
  return (
    <aside
      className={[
        styles.sidebar,
        collapsed ? styles["sidebar-collapsed"] : "",
        mobileOpen ? styles["sidebar-mobile-open"] : "",
      ]
        .filter(Boolean)
        .join(" ")}
    >
      <div className={styles["sidebar-brand"]}>
        <img
          src="/borrowcircle-logo.jpeg"
          alt=""
          className={styles["sidebar-logo"]}
        />
        {!collapsed && (
          <div className={styles["sidebar-brand-text"]}>
            <div className={styles["sidebar-title"]}>BorrowCircle</div>
            <div className={styles["sidebar-subtitle"]}>Admin Dashboard</div>
          </div>
        )}
        <button
          type="button"
          className={styles["sidebar-collapse-btn"]}
          onClick={onToggleCollapse}
          title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          <Icon name="chevron" size={16} />
        </button>
      </div>

      <nav className={styles["sidebar-nav"]}>
        {NAV.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === "/dashboard"}
            className={({ isActive }) =>
              `${styles["nav-link"]} ${isActive ? styles["nav-link-active"] : ""}`
            }
            title={collapsed ? item.label : undefined}
            onClick={onNavigate}
          >
            <Icon name={item.icon} />
            {!collapsed && <span className={styles["nav-label"]}>{item.label}</span>}
            {item.to === "/support-chats" && supportBadge > 0 && (
              <span className={styles["nav-badge"]}>{supportBadge}</span>
            )}
          </NavLink>
        ))}
      </nav>

      {!collapsed && (
        <div className={styles["sidebar-footer"]}>
          <span className="text-sm">BorrowCircle v1.0</span>
        </div>
      )}
    </aside>
  );
}