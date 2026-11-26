import { useState } from "react";
import { Link } from "react-router-dom";
import Button from "../../components/ui/Button";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Badge from "../../components/ui/Badge";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import Modal from "../../components/ui/Modal";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listRequests, approveRequest, rejectRequest } from "../../api/requests";
import { errorMessage } from "../../api/axios";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber, truncate } from "../../utils/format";
import styles from "../pages.module.css";

// Every borrow request. Admins may approve/reject any request (the same
// business rules as owners apply: pending only, no overlap, item available).
export default function RequestsList() {
  const pagination = usePagination();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [feedback, setFeedback] = useState(null);
  const [pending, setPending] = useState(null); // { request, action }
  const [busy, setBusy] = useState(false);

  const query = buildQuery(pagination.queryParams({ search, status }));

  const { data, loading, error, reload } = useApi(
    () => listRequests(query),
    [pagination.page, pagination.limit, search, status],
  );

  const onDecide = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      const act =
        pending.action === "approve" ? approveRequest : rejectRequest;
      await act(pending.request.id);
      setFeedback({
        type: "success",
        text: `Request #${pending.request.id} ${pending.action}d`,
      });
      setPending(null);
      reload();
    } catch (err) {
      setFeedback({ type: "error", text: errorMessage(err) });
      setPending(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Borrow requests</h1>
          <p className={styles["page-subtitle"]}>
            {data ? `${formatNumber(data.total)} requests` : "Loading requests…"}
          </p>
        </div>
      </header>

      {feedback && (
        <div className={`alert alert-${feedback.type}`}>{feedback.text}</div>
      )}

      <form
        className={styles.filters}
        onSubmit={(event) => {
          event.preventDefault();
          pagination.reset();
          reload();
        }}
      >
        <Input
          className={styles["field-search"]}
          label="Search"
          name="search"
          placeholder="Item, requester or owner…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Select
          label="Status"
          name="status"
          value={status}
          onChange={(event) => {
            setStatus(event.target.value);
            pagination.reset();
          }}
          options={[
            { value: "pending", label: "Pending" },
            { value: "approved", label: "Approved" },
            { value: "rejected", label: "Rejected" },
            { value: "cancelled", label: "Cancelled" },
          ]}
        />
        <Button type="submit">Search</Button>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={data?.requests || []}
        emptyMessage="No requests match these filters."
        columns={[
          {
            key: "item_title",
            label: "Item",
            render: (row) => (
              <Link to={`/requests/${row.id}`}>
                <CellMain sub={truncate(row.message, 40) || "—"}>
                  {row.item_title}
                </CellMain>
              </Link>
            ),
          },
          { key: "requester_name", label: "Requester" },
          { key: "owner_name", label: "Owner" },
          {
            key: "dates",
            label: "Dates",
            render: (row) => (
              <CellMain sub={`${row.start_date} → ${row.end_date}`}>
                {row.start_date}
              </CellMain>
            ),
          },
          { key: "status", label: "Status", render: (row) => <Badge>{row.status}</Badge> },
          { key: "created_at", label: "Created", render: (row) => formatDate(row.created_at) },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <div className="row">
                <Link className="text-sm" to={`/requests/${row.id}`}>
                  View
                </Link>
                {row.status === "pending" && (
                  <>
                    <Button
                      size="sm"
                      onClick={() => setPending({ request: row, action: "approve" })}
                    >
                      Approve
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => setPending({ request: row, action: "reject" })}
                    >
                      Reject
                    </Button>
                  </>
                )}
              </div>
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

      <Modal
        open={Boolean(pending)}
        title={pending?.action === "approve" ? "Approve request?" : "Reject request?"}
        danger={pending?.action === "reject"}
        loading={busy}
        confirmLabel={pending?.action === "approve" ? "Approve" : "Reject"}
        onConfirm={onDecide}
        onClose={() => setPending(null)}
      >
        <p>
          {pending?.action === "approve"
            ? `Approve “${pending?.request?.item_title}” for ${pending?.request?.start_date} → ${pending?.request?.end_date}? The requester will be able to turn it into a loan.`
            : `Reject the request for “${pending?.request?.item_title}”? The requester will be notified by this status.`}
        </p>
      </Modal>
    </div>
  );
}