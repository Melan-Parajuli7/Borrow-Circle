import api from "./axios";

export const listLoans = (params) => api.get("/admin/loans", { params });
export const getLoan = (id) => api.get(`/loans/${id}`);