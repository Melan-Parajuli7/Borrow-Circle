import { useEffect } from "react";
import Button from "./Button";
import styles from "./ui.module.css";

// Confirmation dialogs. Closes on Escape or overlay click.
export default function Modal({
  open,
  title,
  children,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  danger = false,
  loading = false,
  onConfirm,
  onClose,
}) {
  useEffect(() => {
    if (!open) return undefined;
    const onKey = (event) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className={styles["modal-overlay"]}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div className={styles.modal} role="dialog" aria-modal="true" aria-label={title}>
        <header className={styles["modal-header"]}>
          <h3 className={styles["modal-title"]}>{title}</h3>
          <button className={styles["modal-close"]} onClick={onClose} aria-label="Close">
            ×
          </button>
        </header>
        <div className={styles["modal-body"]}>{children}</div>
        <footer className={styles["modal-footer"]}>
          <Button variant="ghost" onClick={onClose}>
            {cancelLabel}
          </Button>
          <Button
            variant={danger ? "danger" : "primary"}
            loading={loading}
            onClick={onConfirm}
          >
            {confirmLabel}
          </Button>
        </footer>
      </div>
    </div>
  );
}