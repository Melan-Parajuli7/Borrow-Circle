import { useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import Button from "../../components/ui/Button";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Badge from "../../components/ui/Badge";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listUsers } from "../../api/users";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber } from "../../utils/format";
import styles from "../pages.module.css";

// Every account, searchable by name/email and filterable by role.
export default function UsersList() {
  const [searchParams] = useSearchParams();
  const pagination = usePagination();
  const [search, setSearch] = useState(searchParams.get("search") || "");
  const [role, setRole] = useState(searchParams.get("role") || "");

  const query = buildQuery(pagination.queryParams({ search, role }));

  const { data, loading, error, reload } = useApi(
    () => listUsers(query),
    [pagination.page, pagination.limit, search, role],
  );

  const onSearch = (event) => {
    event.preventDefault();
    pagination.reset();
    reload();
  };

  return (
    <div className={styles.page}>
      <header className={styles["page-header"]}>
        <div>
          <h1 className={styles["page-title"]}>Users</h1>
          <p className={styles["page-subtitle"]}>
            {data ? `${formatNumber(data.total)} accounts` : "Loading accounts…"}
          </p>
        </div>
      </header>

      <form className={styles.filters} onSubmit={onSearch}>
        <Input
          className={styles["field-search"]}
          label="Search"
          name="search"
          placeholder="Name or email…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Select
          label="Role"
          name="role"
          value={role}
          onChange={(event) => {
            setRole(event.target.value);
            pagination.reset();
          }}
          options={[
            { value: "user", label: "User" },
            { value: "admin", label: "Admin" },
          ]}
        />
        <Button type="submit">Search</Button>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={data?.users || []}
        emptyMessage="No users match these filters."
        columns={[
          {
            key: "full_name",
            label: "Name",
            render: (row) => (
              <Link to={`/users/${row.id}`}>
                <CellMain sub={row.email}>{row.full_name}</CellMain>
              </Link>
            ),
          },
          { key: "role", label: "Role", render: (row) => <Badge>{row.role}</Badge> },
          { key: "items_count", label: "Items", render: (row) => row.items_count ?? 0 },
          { key: "requests_count", label: "Requests", render: (row) => row.requests_count ?? 0 },
          { key: "loans_count", label: "Loans", render: (row) => row.loans_count ?? 0 },
          { key: "created_at", label: "Joined", render: (row) => formatDate(row.created_at) },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <Link className="text-sm" to={`/users/${row.id}`}>
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