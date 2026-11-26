import { useState } from "react";
import Select from "../ui/Select";
import Button from "../ui/Button";
import { errorMessage } from "../../api/axios";

// Promote or demote an account. The API refuses self-changes.
export default function UserRoleForm({
  currentRole,
  busy = false,
  isSelf = false,
  onSubmit,
}) {
  const [role, setRole] = useState(currentRole || "user");
  const [error, setError] = useState(null);

  const submit = async (event) => {
    event.preventDefault();
    setError(null);
    try {
      await onSubmit(role);
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  return (
    <form className="stack" onSubmit={submit}>
      <Select
        label="Role"
        name="role"
        value={role}
        disabled={isSelf}
        onChange={(event) => setRole(event.target.value)}
        options={[
          { value: "user", label: "User — regular member" },
          { value: "admin", label: "Admin — dashboard access" },
        ]}
      />
      {isSelf ? (
        <p className="text-sm text-grey">
          You cannot change your own role.
        </p>
      ) : (
        <Button type="submit" loading={busy} disabled={role === currentRole}>
          Save role
        </Button>
      )}
      {error && <div className="alert alert-error">{error}</div>}
    </form>
  );
}