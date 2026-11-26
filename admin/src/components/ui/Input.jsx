import styles from "./ui.module.css";

// `className` / `labelClassName` let a page skin the control (e.g. the glass
// login inputs) without reaching into this module's hashed class names.
// `action` renders a node (e.g. the password reveal button) inside the
// control, on the right side.
export default function Input({
  label,
  error,
  id,
  action,
  className = "",
  labelClassName = "",
  ...rest
}) {
  const inputId = id || rest.name;
  return (
    <label
      className={`${styles.field} ${labelClassName}`.trim()}
      htmlFor={inputId}
    >
      {label && (
        <span className={`${styles["field-label"]} ${labelClassName}`.trim()}>
          {label}
        </span>
      )}
      <span className={styles["field-control-wrap"]}>
        <input
          id={inputId}
          className={`${styles["field-control"]} ${
            action ? styles["field-control-with-action"] : ""
          } ${className}`.trim()}
          aria-invalid={error ? "true" : undefined}
          {...rest}
        />
        {action && <span className={styles["field-action"]}>{action}</span>}
      </span>
      {error && <span className={styles["field-error"]}>{error}</span>}
    </label>
  );
}