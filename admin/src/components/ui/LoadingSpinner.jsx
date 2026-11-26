import styles from "./ui.module.css";

export default function LoadingSpinner({ size = 20 }) {
  return (
    <span
      className={styles.spinner}
      style={{ width: size, height: size, display: "inline-block" }}
      role="status"
      aria-label="Loading"
    />
  );
}