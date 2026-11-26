import { Link, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Badge from "../../components/ui/Badge";
import { Thumb } from "../../components/ui/Table";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import { getLoan } from "../../api/loans";
import { formatDateTime } from "../../utils/format";
import styles from "../pages.module.css";

// One loan. Admins also see the handover code (it is returned to admins by
// the API, the same as to the borrower).
export default function LoanDetail() {
  const { id } = useParams();
  const { data, loading, error } = useApi(() => getLoan(id), [id]);
  const loan = data?.loan;

  if (loading && !loan) {
    return <LoadingSpinner size={28} />;
  }
  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }
  if (!loan) return null;

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Loan #{loan.id}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/loans">← Back to loans</Link>
          </p>
        </div>
        <Badge>{loan.stage}</Badge>
      </header>

      <div className={styles["detail-grid"]}>
        <Card title="Item">
          <div className="stack">
            <Thumb src={loan.item_image} alt={loan.item_title} />
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Item</span>
                <span className={styles["info-value"]}>
                  <Link to={`/items/${loan.item_id}`}>{loan.item_title}</Link>
                </span>
              </div>
            </div>
          </div>
        </Card>

        <div className="stack">
          <Card title="People">
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Borrower</span>
                <span className={styles["info-value"]}>
                  <Link to={`/users/${loan.borrower_id}`}>
                    {loan.borrower_name}
                  </Link>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Owner</span>
                <span className={styles["info-value"]}>
                  <Link to={`/users/${loan.owner_id}`}>{loan.owner_name}</Link>
                </span>
              </div>
            </div>
          </Card>

          <Card title="Timeline">
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Period</span>
                <span className={styles["info-value"]}>
                  {loan.start_date} → {loan.end_date}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Status</span>
                <span className={styles["info-value"]}>
                  <Badge>{loan.status}</Badge>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Handover code</span>
                <span className={styles["info-value"]}>
                  {loan.handover_code || "—"}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Handed over</span>
                <span className={styles["info-value"]}>
                  {formatDateTime(loan.handed_over_at)}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Returned</span>
                <span className={styles["info-value"]}>
                  {formatDateTime(loan.returned_at)}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Created</span>
                <span className={styles["info-value"]}>
                  {formatDateTime(loan.created_at)}
                </span>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}