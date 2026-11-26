import { useContext } from "react";
import AuthContext from "../contexts/AuthContext";

// Convenience accessor: const { user, isAdmin, login, logout } = useAuth();
const useAuth = () => useContext(AuthContext);

export default useAuth;