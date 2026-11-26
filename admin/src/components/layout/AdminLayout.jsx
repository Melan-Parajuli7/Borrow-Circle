import { useEffect, useState } from "react";
import { Outlet, useLocation } from "react-router-dom";
import Sidebar from "../ui/Sidebar";
import Header from "../ui/Header";
import { listSupportChats } from "../../api/chats";
import styles from "./layout.module.css";

const COLLAPSE_KEY = "bc_admin_sidebar_collapsed";

// Shell for every admin screen.
//  - Desktop (>=1024px): the sidebar is always visible, in the normal flow,
//    so it can never cover the content. It collapses to an icon rail and the
//    choice is remembered in localStorage.
//  - Mobile (<1024px): the sidebar becomes an overlay drawer opened with the
//    header button and closed by navigating or tapping the backdrop.
export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(
    () => localStorage.getItem(COLLAPSE_KEY) === "1",
  );
  const [mobileOpen, setMobileOpen] = useState(false);
  const [supportBadge, setSupportBadge] = useState(0);
  const location = useLocation();
  const [renderedPath, setRenderedPath] = useState(location.pathname);

  useEffect(() => {
    localStorage.setItem(COLLAPSE_KEY, collapsed ? "1" : "0");
  }, [collapsed]);

  // Close the mobile drawer on navigation (React's "adjust state during
  // render" pattern instead of an effect)
  if (renderedPath !== location.pathname) {
    setRenderedPath(location.pathname);
    setMobileOpen(false);
  }

  // Support unread badge, refreshed periodically
  useEffect(() => {
    let alive = true;
    const loadBadge = () =>
      listSupportChats({ page: 1, limit: 50 })
        .then(({ data }) => {
          if (!alive) return;
          const unread = (data.conversations || []).reduce(
            (sum, c) => sum + (c.unread_count || 0),
            0,
          );
          setSupportBadge(unread);
        })
        .catch(() => {
          // A silent failure is fine here: the badge is decorative
          if (alive) setSupportBadge(0);
        });

    loadBadge();
    const timer = setInterval(loadBadge, 30000);
    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, []);

  return (
    <div className={styles.layout}>
      <Sidebar
        collapsed={collapsed}
        mobileOpen={mobileOpen}
        onNavigate={() => setMobileOpen(false)}
        onToggleCollapse={() => {
          setCollapsed((value) => !value);
          setMobileOpen(false);
        }}
        supportBadge={supportBadge}
      />

      {mobileOpen && (
        <div
          className={styles["sidebar-backdrop"]}
          onClick={() => setMobileOpen(false)}
        />
      )}

      <div className={styles["main-column"]}>
        <Header onMenuToggle={() => setMobileOpen((open) => !open)} />
        <main className={styles["main-content"]}>
          <div className={styles["content-inner"]}>
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}