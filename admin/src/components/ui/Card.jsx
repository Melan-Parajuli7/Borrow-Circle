import styles from "./ui.module.css";

export default function Card({ title, action, children, bodyClassName = "" }) {
  return (
    <section className={styles.card}>
      {title && (
        <header className={styles["card-header"]}>
          <h3 className={styles["card-title"]}>{title}</h3>
          {action}
        </header>
      )}
      <div className={`${styles["card-body"]} ${bodyClassName}`.trim()}>
        {children}
      </div>
    </section>
  );
}