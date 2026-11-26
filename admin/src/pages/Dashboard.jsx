import { Link } from "react-router-dom";
import Card from "../components/ui/Card";
import Badge from "../components/ui/Badge";
import { CellMain, Table } from "../components/ui/Table";
import LoadingSpinner from "../components/ui/LoadingSpinner";
import useApi from "../hooks/useApi";
import { getDashboardStats } from "../api/admin";
import { listUsers } from "../api/users";
import { listItems } from "../api/items";
import { listRequests } from "../api/requests";
import { listLoans } from "../api/loans";
import { formatNumber, timeAgo } from "../utils/format";
import styles from "./pages.module.css";

// Overview: headline counters + the newest rows of each collection.
export default function Dashboard() {
  const stats = useApi(() => getDashboardStats(), []);
  const users = useApi(() => listUsers({ page: 1, limit: 5 }), []);
  const items = useApi(() => listItems({ page: 1, limit: 5 }), []);
  const requests = useApi(() => listRequests({ page: 1, limit: 5 }), []);
  const loans = useApi(() => listLoans({ page: 1, limit: 5 }), []);

  const loading =
    stats.loading || users.loading || items.loading || requests.loading || loans.loading;

  const s = stats.data?.stats;

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Dashboard</h1>
          <p className={styles["page-subtitle"]}>
            Platform overview and recent activity
          </p>
        </div>
      </header>

      {stats.error && <div className="alert alert-error">{stats.error}</div>}
      {loading && !s && <LoadingSpinner size={32} />}

      {s && (
        <>
          <div className={styles["stats-grid"]}>
            <StatCard label="Users" value={formatNumber(s.total_users)} hint={`${formatNumber(s.total_admins)} admins`} />
            <StatCard label="Items" value={formatNumber(s.total_items)} hint={`${formatNumber(s.available_items)} available`} />
            <StatCard label="Active loans" value={formatNumber(s.active_loans)} hint={`${formatNumber(s.returned_loans)} returned`} />
            <StatCard label="Pending requests" value={formatNumber(s.pending_requests)} hint={`${formatNumber(s.total_requests)} total`} />
            <StatCard label="Reviews" value={formatNumber(s.total_reviews)} hint={`${formatNumber(s.total_messages)} messages sent`} />
            <StatCard
              label="Support chats"
              value={formatNumber(s.support_chats)}
              hint={s.support_unread > 0 ? `${formatNumber(s.support_unread)} unread` : "all read"}
            />
          </div>

          <div className={styles["list-stack"]}>
            <Card
              title="Newest users"
              action={<Link to="/users">View all</Link>}
            >
              <Table
                rows={users.data?.users || []}
                emptyMessage="No users yet."
                columns={[
                  {
                    key: "full_name",
                    label: "Name",
                    render: (row) => (
                      <CellMain sub={row.email}>{row.full_name}</CellMain>
                    ),
                  },
                  { key: "role", label: "Role", render: (row) => <Badge>{row.role}</Badge> },
                  {
                    key: "created_at",
                    label: "Joined",
                    render: (row) => timeAgo(row.created_at),
                  },
                ]}
              />
            </Card>

            <Card title="Newest items" action={<Link to="/items">View all</Link>}>
              <Table
                rows={items.data?.items || []}
                emptyMessage="No items yet."
                columns={[
                  { key: "title", label: "Title", render: (row) => <CellMain sub={row.category || "—"}>{row.title}</CellMain> },
                  { key: "owner_name", label: "Owner" },
                  {
                    key: "is_available",
                    label: "Status",
                    render: (row) => (
                      <Badge>{row.is_available ? "available" : "unavailable"}</Badge>
                    ),
                  },
                  { key: "created_at", label: "Created", render: (row) => timeAgo(row.created_at) },
                ]}
              />
            </Card>

            <Card title="Newest requests" action={<Link to="/requests">View all</Link>}>
              <Table
                rows={requests.data?.requests || []}
                emptyMessage="No requests yet."
                columns={[
                  { key: "item_title", label: "Item", render: (row) => <CellMain sub={row.requester_name}>{row.item_title}</CellMain> },
                  { key: "status", label: "Status", render: (row) => <Badge>{row.status}</Badge> },
                  { key: "start_date", label: "From" },
                  { key: "end_date", label: "To" },
                  { key: "created_at", label: "Created", render: (row) => timeAgo(row.created_at) },
                ]}
              />
            </Card>

            <Card title="Newest loans" action={<Link to="/loans">View all</Link>}>
              <Table
                rows={loans.data?.loans || []}
                emptyMessage="No loans yet."
                columns={[
                  { key: "item_title", label: "Item", render: (row) => <CellMain sub={row.borrower_name}>{row.item_title}</CellMain> },
                  { key: "owner_name", label: "Owner" },
                  { key: "stage", label: "Stage", render: (row) => <Badge>{row.stage}</Badge> },
                  { key: "created_at", label: "Created", render: (row) => timeAgo(row.created_at) },
                ]}
              />
            </Card>
          </div>
        </>
      )}
    </div>
  );
}

function StatCard({ label, value, hint }) {
  return (
    <div className={styles["stat-card"]}>
      <span className={styles["stat-label"]}>{label}</span>
      <span className={styles["stat-value"]}>{value}</span>
      {hint && <span className={styles["stat-hint"]}>{hint}</span>}
    </div>
  );
}