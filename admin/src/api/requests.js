import api from "./axios";

export const listRequests = (params) => api.get("/admin/requests", { params });
// The regular endpoint already lets admins read any request
export const getRequest = (id) => api.get(`/requests/${id}`);
export const approveRequest = (id) => api.patch(`/admin/requests/${id}/approve`);
export const rejectRequest = (id) => api.patch(`/admin/requests/${id}/reject`);