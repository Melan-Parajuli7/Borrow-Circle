import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Button from "../../components/ui/Button";
import Modal from "../../components/ui/Modal";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import { getReview, deleteReview } from "../../api/reviews";
import { errorMessage } from "../../api/axios";
import { formatDateTime } from "../../utils/format";
import styles from "../pages.module.css";

// One review in full, with the delete action for moderation.
export default function ReviewDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [feedback, setFeedback] = useState(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  const { data, loading, error } = useApi(() => getReview(id), [id]);
  const review = data?.review;

  const onDelete = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      await deleteReview(id);
      navigate("/reviews");
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
      setConfirmOpen(false);
    } finally {
      setBusy(false);
    }
  };

  if (loading && !review) {
    return <LoadingSpinner size={28} />;
  }
  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }
  if (!review) return null;

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Review #{review.id}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/reviews">← Back to reviews</Link>
          </p>
        </div>
        <Button variant="danger" onClick={() => setConfirmOpen(true)}>
          Delete review
        </Button>
      </header>

      {feedback && (
        <div className={`alert alert-${feedback.type}`}>{feedback.text}</div>
      )}

      <div className={styles["detail-grid"]}>
        <Card title="Summary">
          <div className={styles["info-list"]}>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Rating</span>
              <span className={styles["info-value"]}>
                {"★".repeat(review.rating)}
                {"☆".repeat(5 - review.rating)}
              </span>
            </div>
            <div className={styles["info-row"]}>
              <span className={styles["info-label"]}>Date</span>
              <span className={styles["info-value"]}>
                {formatDateTime(review.created_at)}
              </span>
            </div>
          </div>
        </Card>

        <div className="stack">
          <Card title="Context">
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Reviewer</span>
                <span className={styles["info-value"]}>
                  <Link to={`/users/${review.reviewer_id}`}>
                    {review.reviewer_name}
                  </Link>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Reviewee</span>
                <span className={styles["info-value"]}>
                  <Link to={`/users/${review.reviewee_id}`}>
                    {review.reviewee_name}
                  </Link>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Loan</span>
                <span className={styles["info-value"]}>
                  <Link to={`/loans/${review.loan_id}`}>{review.item_title}</Link>
                </span>
              </div>
            </div>
          </Card>

          <Card title="Comment">
            <p className="text-sm">
              {review.comment || "No comment left with this rating."}
            </p>
          </Card>
        </div>
      </div>

      <Modal
        open={confirmOpen}
        title="Delete this review?"
        danger
        loading={busy}
        confirmLabel="Delete"
        onConfirm={onDelete}
        onClose={() => setConfirmOpen(false)}
      >
        <p>
          Review #{review.id} by {review.reviewer_name} will be permanently
          removed. This cannot be undone.
        </p>
      </Modal>
    </div>
  );
}