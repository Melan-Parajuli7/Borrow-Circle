import styles from "./ui.module.css";

// Variant: primary | secondary | danger | ghost. `loading` shows a spinner
// and blocks the button.
export default function Button({
  children,
  variant = "primary",
  size = "md",
  loading = false,
  className = "",
  ...rest
}) {
  const classes = [
    styles.btn,
    styles[`btn-${variant}`] ?? styles["btn-primary"],
    size === "sm" ? styles["btn-sm"] : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button className={classes} disabled={loading || rest.disabled} {...rest}>
      {loading && <span className={styles["btn-spinner"]} />}
      {children}
    </button>
  );
}