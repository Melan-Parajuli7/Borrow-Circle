import { Navigate, Outlet, useLocation } from "react-router-dom";
import useAuth from "../../hooks/useAuth";
import LoadingSpinner from "../ui/LoadingSpinner";
import Button from "../ui/Button";

// Gate for every admin screen: restores the session, requires a login, and
// requires role === "admin" (the API enforces the same rule server-side).
export default function ProtectedRoute() {
  const { user, loading, isAdmin, logout } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="center-screen">
        <LoadingSpinner size={40} />
      </div>
    );
  }

  if (!user) {
    return (
      <Navigate to="/login" replace state={{ from: location.pathname }} />
    );
  }

  if (!isAdmin) {
    return (
      <div className="center-screen">
        <div className="denied-card">
          <h2>Admins only</h2>
          <p className="text-grey">
            This dashboard is restricted to BorrowCircle administrators. Your
            account has the “{user.role}” role.
          </p>
          <Button variant="secondary" onClick={logout}>
            Log out
          </Button>
        </div>
      </div>
    );
  }

  return <Outlet />;
}