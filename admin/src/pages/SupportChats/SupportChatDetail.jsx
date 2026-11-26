import { useEffect } from "react";
import { Link, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Button from "../../components/ui/Button";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import useAuth from "../../hooks/useAuth";
import { getSupportChatMessages } from "../../api/chats";
import { timeAgo } from "../../utils/format";
import styles from "../pages.module.css";

// One support conversation. Opening it marks the user's messages as read
// (server side), and the thread refreshes itself every few seconds so an
// admin watching the screen sees new messages arrive. Read-only for now:
// replying from the dashboard is a planned enhancement.
export default function SupportChatDetail() {
  const { id } = useParams();
  const { user: admin } = useAuth();

  const { data, loading, error, reload } = useApi(
    () => getSupportChatMessages(id, { page: 1, limit: 100 }),
    [id],
  );

  // Light polling while the screen is open.
  useEffect(() => {
    const timer = setInterval(reload, 5000);
    return () => clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const messages = data?.messages || [];

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Support chat #{id}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/support-chats">← Back to support chats</Link>
          </p>
        </div>
        <Button variant="ghost" size="sm" onClick={reload}>
          Refresh
        </Button>
      </header>

      {error && <div className="alert alert-error">{error}</div>}

      <Card title="Conversation">
        <div className="stack">
          {loading && !data ? (
            <LoadingSpinner size={24} />
          ) : (
            <div className={styles["chat-thread"]}>
              {messages.length === 0 && (
                <p className="text-sm text-grey">No messages yet.</p>
              )}
              {messages.map((message) => {
                const mine = Number(message.sender_id) === Number(admin?.id);
                return (
                  <div
                    key={message.id}
                    className={`${styles["chat-bubble"]} ${
                      mine ? styles["chat-bubble-admin"] : ""
                    }`}
                  >
                    <div className={styles["chat-meta"]}>
                      {message.sender_name || (mine ? "Admin" : "User")} ·{" "}
                      {timeAgo(message.created_at)}
                    </div>
                    <div>{message.text}</div>
                  </div>
                );
              })}
            </div>
          )}

          <p className="text-sm text-grey">
            Read-only view — replying from the dashboard is coming in a later
            release.
          </p>
        </div>
      </Card>
    </div>
  );
}