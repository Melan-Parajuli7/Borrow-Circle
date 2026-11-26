import { useState } from "react";
import { Link } from "react-router-dom";
import Button from "../../components/ui/Button";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Badge from "../../components/ui/Badge";
import { CellMain, Table, Thumb } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import Modal from "../../components/ui/Modal";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listItems, deleteItem } from "../../api/items";
import { errorMessage } from "../../api/axios";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber, titleCase } from "../../utils/format";
import styles from "../pages.module.css";

// Every listed item with admin-only deletion.
export default function ItemsList() {
  const pagination = usePagination();
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [condition, setCondition] = useState("");
  const [available, setAvailable] = useState("");
  const [feedback, setFeedback] = useState(null);
  const [pending, setPending] = useState(null); // item awaiting delete confirm
  const [busy, setBusy] = useState(false);

  const query = buildQuery(
    pagination.queryParams({ search, category, condition, available }),
  );

  const { data, loading, error, reload } = useApi(
    () => listItems(query),
    [pagination.page, pagination.limit, search, category, condition, available],
  );

  const onDelete = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      await deleteItem(pending.id);
      setFeedback({ type: "success", text: `"${pending.title}" deleted` });
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
          <h1 className={styles["page-title"]}>Items</h1>
          <p className={styles["page-subtitle"]}>
            {data ? `${formatNumber(data.total)} items listed` : "Loading items…"}
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
          placeholder="Title or description…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Input
          label="Category"
          name="category"
          placeholder="e.g. electronics"
          value={category}
          onChange={(event) => setCategory(event.target.value)}
        />
        <Select
          label="Condition"
          name="condition"
          value={condition}
          onChange={(event) => {
            setCondition(event.target.value);
            pagination.reset();
          }}
          options={[
            { value: "new", label: "New" },
            { value: "like_new", label: "Like new" },
            { value: "good", label: "Good" },
            { value: "fair", label: "Fair" },
            { value: "poor", label: "Poor" },
          ]}
        />
        <Select
          label="Availability"
          name="available"
          value={available}
          onChange={(event) => {
            setAvailable(event.target.value);
            pagination.reset();
          }}
          options={[
            { value: "true", label: "Available" },
            { value: "false", label: "Unavailable" },
          ]}
        />
        <Button type="submit">Search</Button>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={data?.items || []}
        emptyMessage="No items match these filters."
        columns={[
          {
            key: "image_url",
            label: "Image",
            width: 60,
            render: (row) => <Thumb src={row.image_url} alt={row.title} />,
          },
          {
            key: "title",
            label: "Title",
            render: (row) => (
              <Link to={`/items/${row.id}`}>
                <CellMain sub={titleCase(row.condition)}>{row.title}</CellMain>
              </Link>
            ),
          },
          { key: "category", label: "Category", render: (row) => row.category || "—" },
          { key: "owner_name", label: "Owner", render: (row) => row.owner_name || "—" },
          {
            key: "is_group_item",
            label: "Group",
            render: (row) => (row.is_group_item ? "Yes" : "No"),
          },
          {
            key: "is_available",
            label: "Status",
            render: (row) => (
              <Badge>{row.is_available ? "available" : "unavailable"}</Badge>
            ),
          },
          { key: "created_at", label: "Created", render: (row) => formatDate(row.created_at) },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <div className="row">
                <Link className="text-sm" to={`/items/${row.id}`}>
                  View
                </Link>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setPending(row)}
                >
                  Delete
                </Button>
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
        title="Delete this item?"
        danger
        loading={busy}
        confirmLabel="Delete"
        onConfirm={onDelete}
        onClose={() => setPending(null)}
      >
        <p>
          “{pending?.title}” will be removed together with its borrow requests.
          Items with loan history cannot be deleted.
        </p>
      </Modal>
    </div>
  );
}