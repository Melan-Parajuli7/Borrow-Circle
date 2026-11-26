import { useState } from "react";
import { Link } from "react-router-dom";
import Button from "../../components/ui/Button";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Badge from "../../components/ui/Badge";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listLoans } from "../../api/loans";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber } from "../../utils/format";
import styles from "../pages.module.css";

// Every loan in the system, filterable by derived stage.
export default function LoansList() {
  const pagination = usePagination();
  const [search, setSearch] = useState("");
  const [stage, setStage] = useState("");
  const [status, setStatus] = useState("");

  const query = buildQuery(
    pagination.queryParams({ search, stage, status }),
  );

  const { data, loading, error } = useApi(
    () => listLoans(query),
    [pagination.page, pagination.limit, search, stage, status],
  );

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Loans</h1>
          <p className={styles["page-subtitle"]}>
            {data ? `${formatNumber(data.total)} loans` : "Loading loans…"}
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
          placeholder="Item, borrower or owner…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Select
          label="Stage"
          name="stage"
          value={stage}
          onChange={(event) => {
            setStage(event.target.value);
            pagination.reset();
          }}
          options={[
            { value: "awaiting_handover", label: "Awaiting handover" },
            { value: "on_loan", label: "On loan" },
            { value: "overdue", label: "Overdue" },
            { value: "returned", label: "Returned" },
          ]}
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
            { value: "active", label: "Active" },
            { value: "overdue", label: "Overdue" },
            { value: "returned", label: "Returned" },
          ]}
        />
        <Button type="submit">Search</Button>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={data?.loans || []}
        emptyMessage="No loans match these filters."
        columns={[
          {
            key: "item_title",
            label: "Item",
            render: (row) => (
              <Link to={`/loans/${row.id}`}>
                <CellMain sub={row.borrower_name}>{row.item_title}</CellMain>
              </Link>
            ),
          },
          {
            key: "owner_name",
            label: "Owner",
            render: (row) => (
              <Link className="text-sm" to={`/users/${row.owner_id}`}>
                {row.owner_name}
              </Link>
            ),
          },
          {
            key: "dates",
            label: "Period",
            render: (row) => `${row.start_date} → ${row.end_date}`,
          },
          { key: "stage", label: "Stage", render: (row) => <Badge>{row.stage}</Badge> },
          {
            key: "handed_over_at",
            label: "Handover",
            render: (row) => formatDate(row.handed_over_at),
          },
          {
            key: "returned_at",
            label: "Returned",
            render: (row) => formatDate(row.returned_at),
          },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <Link className="text-sm" to={`/loans/${row.id}`}>
                View
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