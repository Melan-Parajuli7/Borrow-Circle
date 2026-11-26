import styles from "./ui.module.css";

// Generic data table. `columns` is [{ key, label, render?(row), width? }];
// rows without a render fall back to the raw value.
function Table({ columns, rows, emptyMessage = "Nothing to show yet." }) {
  if (!rows || rows.length === 0) {
    return (
      <div className={styles["table-wrap"]}>
        <div className={styles["table-empty"]}>{emptyMessage}</div>
      </div>
    );
  }

  return (
    <div className={styles["table-wrap"]}>
      <table className={styles.table}>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.key} style={column.width ? { width: column.width } : undefined}>
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={row.id ?? index}>
              {columns.map((column) => (
                <td key={column.key}>
                  {column.render ? column.render(row) : String(row[column.key] ?? "—")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Cell helpers used by most tables.
export const CellMain = ({ children, sub }) => (
  <div>
    <div className={styles["cell-main"]}>{children}</div>
    {sub && <div className={styles["cell-sub"]}>{sub}</div>}
  </div>
);

export const Thumb = ({ src, alt }) => {
  if (!src) {
    return (
      <div className={styles["thumb-fallback"]}>
        {(alt || "?").slice(0, 1).toUpperCase()}
      </div>
    );
  }
  // Avatars/images are stored as "/uploads/..." on the API host
  const url = src.startsWith("http") ? src : `http://localhost:3000${src}`;
  return <img className={styles.thumb} src={url} alt={alt || ""} loading="lazy" />;
};

export { Table };
export default Table;