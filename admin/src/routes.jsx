import { Navigate, Route, Routes } from "react-router-dom";
import ProtectedRoute from "./components/layout/ProtectedRoute.jsx";
import AdminLayout from "./components/layout/AdminLayout.jsx";
import Login from "./pages/Login.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import UsersList from "./pages/Users/UsersList.jsx";
import UserDetail from "./pages/Users/UserDetail.jsx";
import ItemsList from "./pages/Items/ItemsList.jsx";
import ItemDetail from "./pages/Items/ItemDetail.jsx";
import RequestsList from "./pages/Requests/RequestsList.jsx";
import RequestDetail from "./pages/Requests/RequestDetail.jsx";
import LoansList from "./pages/Loans/LoansList.jsx";
import LoanDetail from "./pages/Loans/LoanDetail.jsx";
import ReviewsList from "./pages/Reviews/ReviewsList.jsx";
import ReviewDetail from "./pages/Reviews/ReviewDetail.jsx";
import SupportChatsList from "./pages/SupportChats/SupportChatsList.jsx";
import SupportChatDetail from "./pages/SupportChats/SupportChatDetail.jsx";

// Public login screen; everything else lives behind the admin guard.
export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />

          <Route path="/users" element={<UsersList />} />
          <Route path="/users/:id" element={<UserDetail />} />

          <Route path="/items" element={<ItemsList />} />
          <Route path="/items/:id" element={<ItemDetail />} />

          <Route path="/requests" element={<RequestsList />} />
          <Route path="/requests/:id" element={<RequestDetail />} />

          <Route path="/loans" element={<LoansList />} />
          <Route path="/loans/:id" element={<LoanDetail />} />

          <Route path="/reviews" element={<ReviewsList />} />
          <Route path="/reviews/:id" element={<ReviewDetail />} />

          <Route path="/support-chats" element={<SupportChatsList />} />
          <Route path="/support-chats/:id" element={<SupportChatDetail />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}