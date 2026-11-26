import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Modal from "../../components/ui/Modal";
import { Thumb } from "../../components/ui/Table";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import { getRequest, approveRequest, rejectRequest } from "../../api/requests";
import { errorMessage } from "../../api/axios";
import { formatDateTime } from "../../utils/format";
import styles from "../pages.module.css";

// One request with its item and both people; approval is available here too.
export default function RequestDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [feedback, setFeedback] = useState(null);
  const [confirm, setConfirm] = useState(null); // "approve" | "reject"
  const [busy, setBusy] = useState(false);

  const { data, loading, error } = useApi(() => getRequest(id), [id]);
  const request = data?.request;

  const decide = async (action) => {
    setBusy(true);
    setFeedback(null);
    try {
      const act = action === "approve" ? approveRequest : rejectRequest;
      await act(id);
      setFeedback({ type: "success", text: `Request ${action}d` });
      setConfirm(null);
      navigate("/requests");
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
      setConfirm(null);
    } finally {
      setBusy(false);
    }
  };

  if (loading && !request) {
    return <LoadingSpinner size={28} />;
  }
  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }
  if (!request) {
    return (
      <div className="alert alert-error">
        Request #{id} not found. <Link to="/requests">Back to requests</Link>
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Request #{request.id}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/requests">← Back to requests</Link>
          </p>
        </div>
        {request.status === "pending" && (
          <div className="row">
            <Button onClick={() => setConfirm("approve")}>Approve</Button>
            <Button variant="ghost" onClick={() => setConfirm("reject")}>
              Reject
            </Button>
          </div>
        )}
      </header>

      {feedback && (
        <div className={`alert alert-${feedback.type}`}>{feedback.text}</div>
      )}

      <div className={styles["detail-grid"]}>
        <Card title="Item">
          <div className="stack">
            <Thumb src={request.item_image} alt={request.item_title} />
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Item</span>
                <span className={styles["info-value"]}>
                  <Link to={`/items/${request.item_id}`}>{request.item_title}</Link>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Owner</span>
                <span className={styles["info-value"]}>
                  <Link to={`/users/${request.owner_id}`}>{request.owner_name}</Link>
                </span>
              </div>
            </div>
          </div>
        </Card>

        <Card title="Request">
          <div className={styles["info-list"]}>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Status</span>
              <span className={styles["info-value"]}>
                <Badge>{request.status}</Badge>
              </span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Requester</span>
              <span className={styles["info-value"]}>
                <Link to={`/users/${request.requester_id}`}>
                  {request.requester_name}
                </Link>
              </span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Period</span>
              <span className={styles["info-value"]}>
                {request.start_date} → {request.end_date}
              </span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Created</span>
              <span className={styles["info-value"]}>
                {formatDateTime(request.created_at)}
              </span>
            </div>
          </div>

          <div className="stack" style={{ marginTop: "var(--spacing-md)" }}>
            <span className={styles["info-label"]}>Message to owner</span>
            <p className="text-sm">{request.message || "No message."}</p>
          </div>
        </Card>
      </div>

      <Modal
        open={Boolean(confirm)}
        title={confirm === "approve" ? "Approve request?" : "Reject request?"}
        danger={confirm === "reject"}
        loading={busy}
        confirmLabel={confirm === "approve" ? "Approve" : "Reject"}
        onConfirm={() => decide(confirm)}
        onClose={() => setConfirm(null)}
      >
        <p>
          {confirm === "approve"
            ? `Approve “${request.item_title}” for ${request.start_date} → ${request.end_date}?`
            : `Reject the request for “${request.item_title}”?`}
        </p>
      </Modal>
    </div>
  );
}