import api from "./axios";

export const listReviews = (params) => api.get("/admin/reviews", { params });
export const getReview = (id) => api.get(`/admin/reviews/${id}`);
export const deleteReview = (id) => api.delete(`/admin/reviews/${id}`);