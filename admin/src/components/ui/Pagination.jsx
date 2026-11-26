import Button from "./Button";
import styles from "./ui.module.css";

export default function Pagination({ page, totalPages, total, onChange }) {
  return (
    <div className={styles.pagination}>
      <span className={styles["pagination-info"]}>
        {total} {total === 1 ? "item" : "items"}
      </span>
      <div className={styles["pagination-controls"]}>
        <Button
          size="sm"
          variant="ghost"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          Previous
        </Button>
        <span className={styles["pagination-page"]}>
          Page {page} of {Math.max(totalPages, 1)}
        </span>
        <Button
          size="sm"
          variant="ghost"
          disabled={page >= totalPages}
          onClick={() => onChange(page + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
}