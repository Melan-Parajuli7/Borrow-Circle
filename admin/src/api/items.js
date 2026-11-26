import api from "./axios";

export const listItems = (params) => api.get("/admin/items", { params });
export const getItem = (id) => api.get(`/items/${id}`);
export const deleteItem = (id) => api.delete(`/admin/items/${id}`);