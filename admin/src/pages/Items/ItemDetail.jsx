import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Modal from "../../components/ui/Modal";
import { Thumb } from "../../components/ui/Table";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import { getItem, deleteItem } from "../../api/items";
import { errorMessage } from "../../api/axios";
import { formatDate, titleCase, truncate } from "../../utils/format";
import styles from "../pages.module.css";

// Full item record, including who owns it and its loan history guard.
export default function ItemDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [feedback, setFeedback] = useState(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  const { data, loading, error } = useApi(() => getItem(id), [id]);
  const item = data?.item;

  const onDelete = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      await deleteItem(id);
      setConfirmOpen(false);
      setFeedback({ type: "success", text: "Item deleted" });
      navigate("/items");
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
      setConfirmOpen(false);
    } finally {
      setBusy(false);
    }
  };

  if (loading && !item) {
    return <LoadingSpinner size={28} />;
  }
  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }
  if (!item) return null;

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>{item.title}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/items">← Back to items</Link>
          </p>
        </div>
        <Button variant="danger" onClick={() => setConfirmOpen(true)}>
          Delete item
        </Button>
      </header>

      {feedback && (
        <div className={`alert alert-${feedback.type}`}>{feedback.text}</div>
      )}

      <div className={styles["detail-grid"]}>
        <Card title="Preview">
          <div className="stack">
            <Thumb src={item.image_url} alt={item.title} />
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Availability</span>
                <span className={styles["info-value"]}>
                  <Badge>{item.is_available ? "available" : "unavailable"}</Badge>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Group item</span>
                <span className={styles["info-value"]}>
                  {item.is_group_item ? item.group_name : "No"}
                </span>
              </div>
            </div>
          </div>
        </Card>

        <Card title="Details">
          <div className={styles["info-list"]}>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Title</span>
              <span className={styles["info-value"]}>{item.title}</span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Category</span>
              <span className={styles["info-value"]}>{item.category || "—"}</span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Condition</span>
              <span className={styles["info-value"]}>{titleCase(item.condition)}</span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Owner</span>
              <span className={styles["info-value"]}>
                <Link to={`/users/${item.owner_id}`}>{item.owner_name}</Link>
              </span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Listed</span>
              <span className={styles["info-value"]}>{formatDate(item.created_at)}</span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Last updated</span>
              <span className={styles["info-value"]}>{formatDate(item.updated_at)}</span>
            </div>
          </div>

          <div className="stack" style={{ marginTop: "var(--spacing-md)" }}>
            <span className={styles["info-label"]}>Description</span>
            <p className="text-sm">
              {item.description ? truncate(item.description, 1000) : "No description provided."}
            </p>
          </div>
        </Card>
      </div>

      <Modal
        open={confirmOpen}
        title="Delete this item?"
        danger
        loading={busy}
        confirmLabel="Delete"
        onConfirm={onDelete}
        onClose={() => setConfirmOpen(false)}
      >
        <p>
          “{item.title}” will be removed together with its borrow requests.
          Items with loan history cannot be deleted.
        </p>
      </Modal>
    </div>
  );
}