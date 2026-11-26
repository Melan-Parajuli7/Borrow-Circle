import { useState } from "react";
import { Link } from "react-router-dom";
import Input from "../../components/ui/Input";
import Badge from "../../components/ui/Badge";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listSupportChats } from "../../api/chats";
import { buildQuery } from "../../utils/helpers";
import { formatNumber, timeAgo, truncate } from "../../utils/format";
import styles from "../pages.module.css";

// Support threads only: conversations where an admin takes part.
// Private user-to-user chats are never listed here.
export default function SupportChatsList() {
  const pagination = usePagination();
  const [search, setSearch] = useState("");
  const [unreadOnly, setUnreadOnly] = useState(false);

  const query = buildQuery(pagination.queryParams({ search }));

  const { data, loading, error } = useApi(
    () => listSupportChats(query),
    [pagination.page, pagination.limit, search],
  );

  // The API returns the whole support list; the client applies the
  // "unread only" toggle on the current page.
  const rows = (data?.conversations || []).filter(
    (row) => !unreadOnly || row.unread_count > 0,
  );

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Support chats</h1>
          <p className={styles["page-subtitle"]}>
            {data
              ? `${formatNumber(data.total)} conversations with admins`
              : "Loading conversations…"}
          </p>
        </div>
      </header>

      <form
        className={styles.filters}
        onSubmit={(event) => {
          event.preventDefault();
          pagination.reset();
        }}
      >
        <Input
          className={styles["field-search"]}
          label="Search"
          name="search"
          placeholder="User name…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <label className="row" style={{ paddingBottom: 10 }}>
          <input
            type="checkbox"
            checked={unreadOnly}
            onChange={(event) => setUnreadOnly(event.target.checked)}
          />
          <span className="text-sm">Unread only</span>
        </label>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={rows}
        emptyMessage="No support conversations yet."
        columns={[
          {
            key: "participant_name",
            label: "User",
            render: (row) => (
              <CellMain sub={row.participant_avatar ? "" : undefined}>
                {row.participant_name}
              </CellMain>
            ),
          },
          {
            key: "last_message",
            label: "Last message",
            render: (row) => (
              <span className="text-sm text-grey">
                {row.last_message ? truncate(row.last_message, 70) : "No messages yet"}
              </span>
            ),
          },
          {
            key: "last_message_at",
            label: "Last activity",
            render: (row) => timeAgo(row.last_message_at || row.updated_at),
          },
          {
            key: "unread_count",
            label: "Unread",
            render: (row) =>
              row.unread_count > 0 ? (
                <Badge tone="error">{row.unread_count} new</Badge>
              ) : (
                <span className="text-sm text-grey">—</span>
              ),
          },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <Link className="text-sm" to={`/support-chats/${row.id}`}>
                Open
              </Link>
            ),
          },
        ]}
      />

      <Pagination
        page={data?.page || pagination.page}
        totalPages={data?.totalPages || 1}
        total={data?.total || 0}
        onChange={pagination.setPage}
      />
    </div>
  );
}