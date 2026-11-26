import api from "./axios";

// Only support threads (an admin takes part) are ever returned here.
export const listSupportChats = (params) =>
  api.get("/admin/support-chats", { params });
export const getSupportChatMessages = (id, params) =>
  api.get(`/admin/support-chats/${id}/messages`, { params });