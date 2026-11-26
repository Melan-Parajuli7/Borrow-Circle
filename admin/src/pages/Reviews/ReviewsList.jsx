import { useState } from "react";
import { Link } from "react-router-dom";
import Button from "../../components/ui/Button";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import { CellMain, Table } from "../../components/ui/Table";
import Pagination from "../../components/ui/Pagination";
import LoadingSpinner from "../../components/ui/LoadingSpinner";
import Modal from "../../components/ui/Modal";
import usePagination from "../../hooks/usePagination";
import useApi from "../../hooks/useApi";
import { listReviews, deleteReview } from "../../api/reviews";
import { errorMessage } from "../../api/axios";
import { buildQuery } from "../../utils/helpers";
import { formatDate, formatNumber, truncate } from "../../utils/format";
import styles from "../pages.module.css";

// Every review, with moderation (delete) for inappropriate content.
export default function ReviewsList() {
  const pagination = usePagination();
  const [search, setSearch] = useState("");
  const [rating, setRating] = useState("");
  const [feedback, setFeedback] = useState(null);
  const [pending, setPending] = useState(null);
  const [busy, setBusy] = useState(false);

  const query = buildQuery(pagination.queryParams({ search, rating }));

  const { data, loading, error, reload } = useApi(
    () => listReviews(query),
    [pagination.page, pagination.limit, search, rating],
  );

  const onDelete = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      await deleteReview(pending.id);
      setFeedback({ type: "success", text: `Review #${pending.id} deleted` });
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
          <h1 className={styles["page-title"]}>Reviews</h1>
          <p className={styles["page-subtitle"]}>
            {data ? `${formatNumber(data.total)} reviews` : "Loading reviews…"}
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
          placeholder="Reviewer, reviewee, item or comment…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <Select
          label="Rating"
          name="rating"
          value={rating}
          onChange={(event) => {
            setRating(event.target.value);
            pagination.reset();
          }}
          options={[5, 4, 3, 2, 1].map((value) => ({
            value: String(value),
            label: `${value} star${value > 1 ? "s" : ""}`,
          }))}
        />
        <Button type="submit">Search</Button>
      </form>

      {error && <div className="alert alert-error">{error}</div>}
      {loading && !data && <LoadingSpinner size={28} />}

      <Table
        rows={data?.reviews || []}
        emptyMessage="No reviews match these filters."
        columns={[
          { key: "reviewer_name", label: "Reviewer", render: (row) => (
            <Link className="text-sm" to={`/users/${row.reviewer_id}`}>{row.reviewer_name}</Link>
          ) },
          { key: "reviewee_name", label: "Reviewee", render: (row) => (
            <Link className="text-sm" to={`/users/${row.reviewee_id}`}>{row.reviewee_name}</Link>
          ) },
          { key: "item_title", label: "Item", render: (row) => (
            <CellMain sub={truncate(row.comment, 50) || "—"}>{row.item_title}</CellMain>
          ) },
          {
            key: "rating",
            label: "Rating",
            render: (row) => "★".repeat(row.rating) + "☆".repeat(5 - row.rating),
          },
          { key: "created_at", label: "Date", render: (row) => formatDate(row.created_at) },
          {
            key: "actions",
            label: "Actions",
            render: (row) => (
              <div className="row">
                <Link className="text-sm" to={`/reviews/${row.id}`}>
                  View
                </Link>
                <Button size="sm" variant="ghost" onClick={() => setPending(row)}>
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
        title="Delete this review?"
        danger
        loading={busy}
        confirmLabel="Delete"
        onConfirm={onDelete}
        onClose={() => setPending(null)}
      >
        <p>
          Review #{pending?.id} by {pending?.reviewer_name} will be permanently
          removed. This cannot be undone.
        </p>
      </Modal>
    </div>
  );
}