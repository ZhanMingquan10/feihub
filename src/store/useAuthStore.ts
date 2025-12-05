import { create } from "zustand";

type User = {
  email: string;
  quota: number;
};

type AuthState = {
  user: User | null;
  token: string | null;
  loading: boolean;
  error: string | null;
  message: string | null;
  init: () => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string) => Promise<void>;
  requestPasswordReset: (email: string) => Promise<void>;
  logout: () => void;
  clearStatus: () => void;
  addQuota: (amount: number) => Promise<void>;
  consumeQuota: () => Promise<boolean>;
};

const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:4000";
const TOKEN_KEY = "feihub_token";

const mapUser = (payload: any): User => ({
  email: payload.email,
  quota: payload.quota ?? 0
});

async function handleResponse<T>(response: Response): Promise<T> {
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.message || "请求失败");
  }
  return data as T;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  loading: false,
  error: null,
  message: null,

  init: async () => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) return;
    try {
      const res = await fetch(`${API_BASE}/api/auth/profile`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await handleResponse<{ user: User }>(res);
      set({ user: data.user, token });
    } catch (error) {
      console.warn("Profile init failed", error);
      localStorage.removeItem(TOKEN_KEY);
    }
  },

  login: async (email: string, password: string) => {
    set({ loading: true, error: null, message: null });
    try {
      const res = await fetch(`${API_BASE}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });
      const data = await handleResponse<{ token: string; user: User }>(res);
      localStorage.setItem(TOKEN_KEY, data.token);
      set({ user: mapUser(data.user), token: data.token, loading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : "登录失败", loading: false });
    }
  },

  register: async (email: string, password: string) => {
    set({ loading: true, error: null, message: null });
    try {
      const res = await fetch(`${API_BASE}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });
      const data = await handleResponse<{ token: string; user: User }>(res);
      localStorage.setItem(TOKEN_KEY, data.token);
      set({ user: mapUser(data.user), token: data.token, loading: false, message: "注册成功，已自动登录。" });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : "注册失败", loading: false });
    }
  },

  requestPasswordReset: async (email: string) => {
    set({ loading: true, error: null, message: null });
    try {
      const res = await fetch(`${API_BASE}/api/auth/reset-request`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email })
      });
      const data = await handleResponse<{ message: string }>(res);
      set({ message: data.message, loading: false });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : "请求失败", loading: false });
    }
  },

  addQuota: async (amount: number) => {
    const { token } = get();
    if (!token) return;
    const res = await fetch(`${API_BASE}/api/quota/change`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({ delta: amount })
    });
    try {
      const data = await handleResponse<{ user: User }>(res);
      set({ user: mapUser(data.user) });
    } catch (error) {
      console.error("Add quota failed", error);
    }
  },

  consumeQuota: async () => {
    const { token, user } = get();
    if (!token || !user || user.quota <= 0) return false;

    const res = await fetch(`${API_BASE}/api/quota/change`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({ delta: -1 })
    });

    try {
      const data = await handleResponse<{ user: User }>(res);
      set({ user: mapUser(data.user) });
      return true;
    } catch (error) {
      console.error("Consume quota failed", error);
      return false;
    }
  },

  logout: () => {
    localStorage.removeItem(TOKEN_KEY);
    set({ user: null, token: null });
  },

  clearStatus: () => set({ error: null, message: null })
}));
