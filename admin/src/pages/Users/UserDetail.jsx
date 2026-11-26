import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Card from "../../components/ui/Card";
import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Modal from "../../components/ui/Modal";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import useApi from "../../hooks/useApi";
import useAuth from "../../hooks/useAuth";
import usePagination from "../../hooks/usePagination";
import { getUser, updateUserRole, deleteUser } from "../../api/users";
import { listItems } from "../../api/items";
import UserRoleForm from "../../components/forms/UserRoleForm";
import { errorMessage } from "../../api/axios";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber } from "../../utils/format";
import styles from "../pages.module.css";

// One account: profile, role management, deletion (guarded server-side),
// and the items they own.
export default function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user: admin } = useAuth();
  const pagination = usePagination(10);
  const [feedback, setFeedback] = useState(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  const { data, loading, error, reload } = useApi(() => getUser(id), [id]);
  const items = useApi(
    () =>
      listItems(
        buildQuery(pagination.queryParams({ owner_id: id, limit: 10 })),
      ),
    [id, pagination.page, pagination.limit],
  );

  const user = data?.user;

  const onRoleChange = async (role) => {
    setBusy(true);
    setFeedback(null);
    try {
      await updateUserRole(id, role);
      setFeedback({ type: "success", text: `Role updated to "${role}"` });
      reload();
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
    } finally {
      setBusy(false);
    }
  };

  const onDelete = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      await deleteUser(id);
      navigate("/users");
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
      setConfirmOpen(false);
    } finally {
      setBusy(false);
    }
  };

  if (loading && !user) {
    return <LoadingSpinner size={28} />;
  }
  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }
  if (!user) return null;

  const isSelf = String(user.id) === String(admin?.id);

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>{user.full_name}</h1>
          <p className={styles["page-subtitle"]}>
            <Link to="/users">← Back to users</Link>
          </p>
        </div>
        <Button variant="danger" onClick={() => setConfirmOpen(true)}>
          Delete user
        </Button>
      </header>

      {feedback && (
        <div className={`alert alert-${feedback.type}`}>{feedback.text}</div>
      )}

      <div className={styles["detail-grid"]}>
        <div className="stack">
          <Card title="Profile">
            <div className={styles["info-list"]}>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Email</span>
                <span className={styles["info-value"]}>{user.email}</span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Role</span>
                <span className={styles["info-value"]}>
                  <Badge>{user.role}</Badge>
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Items listed</span>
                <span className={styles["info-value"]}>
                  {formatNumber(user.items_count ?? 0)}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Requests sent</span>
                <span className={styles["info-value"]}>
                  {formatNumber(user.requests_count ?? 0)}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Loans involved</span>
                <span className={styles["info-value"]}>
                  {formatNumber(user.loans_count ?? 0)}
                </span>
              </div>
              <div className={styles["info-row"]}>
                <span className={styles["info-label"]}>Joined</span>
                <span className={styles["info-value"]}>
                  {formatDate(user.created_at)}
                </span>
              </div>
            </div>
          </Card>

          <Card title="Change role">
            <UserRoleForm
              currentRole={user.role}
              busy={busy}
              isSelf={isSelf}
              onSubmit={onRoleChange}
            />
          </Card>
        </div>

        <Card title="Items owned">
          <Table
            rows={items.data?.items || []}
            emptyMessage="This user has no listed items."
            columns={[
              {
                key: "title",
                label: "Title",
                render: (row) => (
                  <CellMain sub={row.category || "—"}>{row.title}</CellMain>
                ),
              },
              {
                key: "is_available",
                label: "Status",
                render: (row) => (
                  <Badge>{row.is_available ? "available" : "unavailable"}</Badge>
                ),
              },
              {
                key: "actions",
                label: "Actions",
                render: (row) => (
                  <Link className="text-sm" to={`/items/${row.id}`}>
                    View
                  </Link>
                ),
              },
            ]}
          />
          <Pagination
            page={items.data?.page || pagination.page}
            totalPages={items.data?.totalPages || 1}
            total={items.data?.total || 0}
            onChange={pagination.setPage}
          />
        </Card>
      </div>

      <Modal
        open={confirmOpen}
        title="Delete this user?"
        danger
        loading={busy}
        confirmLabel="Delete"
        onConfirm={onDelete}
        onClose={() => setConfirmOpen(false)}
      >
        <p>
          {user.full_name} ({user.email}) will be removed together with their
          items, requests, reviews and conversations. Users with loan history
          cannot be deleted.
        </p>
      </Modal>
    </div>
  );
}