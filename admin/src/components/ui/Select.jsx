import styles from "./ui.module.css";

// options: [{ value, label }]; value "" renders as the "All" choice.
export default function Select({
  label,
  options = [],
  allLabel = "All",
  id,
  ...rest
}) {
  const selectId = id || rest.name;
  return (
    <label className={styles.field} htmlFor={selectId}>
      {label && <span className={styles["field-label"]}>{label}</span>}
      <select id={selectId} className={styles["field-control"]} {...rest}>
        <option value="">{allLabel}</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}