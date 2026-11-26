import styles from "./ui.module.css";
import { statusTone, titleCase } from "../../utils/format";

// Colored pill for statuses. `tone` overrides the automatic status mapping.
export default function Badge({ children, tone }) {
  const resolved = tone || statusTone(children);
  return (
    <span className={`${styles.badge} ${styles[`badge-${resolved}`] ?? ""}`}>
      {titleCase(children)}
    </span>
  );
}