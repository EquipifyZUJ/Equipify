/**
 * Minimal fetch wrapper with automatic JWT attach and one silent
 * access-token refresh on 401 (single-flight, queue-safe).
 */

const API = import.meta.env.VITE_API_URL ?? '/api'

// API base URL without /api suffix — used for image paths like /images/... /uploads/...
export const API_BASE = API.replace(/\/api\/?$/, '')

/** Prefix relative image paths with the API server URL so they load on production */
export function img(path: string | null | undefined): string {
  if (!path) return '/placeholder.svg'
  if (path.startsWith('http')) return path
  return `${API_BASE}${path}`
}

export class ApiError extends Error {
  status: number
  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

export const tokens = {
  get access() { return localStorage.getItem('equipify.at') },
  set(access: string | null, refresh: string | null) {
    if (access) localStorage.setItem('equipify.at', access); else localStorage.removeItem('equipify.at')
    if (refresh) localStorage.setItem('equipify.rt', refresh); else localStorage.removeItem('equipify.rt')
  },
  get refresh() { return localStorage.getItem('equipify.rt') },
}

let refreshing: Promise<boolean> | null = null

async function doRefresh(): Promise<boolean> {
  const rt = tokens.refresh
  if (!rt) return false

  refreshing ??= (async () => {
    try {
      const res = await fetch(`${API}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: rt }),
      })
      if (!res.ok) return false
      const data = await res.json()
      tokens.set(data.accessToken, data.refreshToken)
      window.dispatchEvent(new CustomEvent('equipify:refreshed', { detail: data.user }))
      return true
    } catch {
      return false
    } finally {
      refreshing = null
    }
  })()

  return refreshing
}

interface Options extends Omit<RequestInit, 'body'> {
  body?: unknown
  form?: FormData
}

export async function api<T = unknown>(path: string, options: Options = {}): Promise<T> {
  const send = async (): Promise<Response> => {
    const headers: Record<string, string> = {}
    const at = tokens.access
    if (at) headers['Authorization'] = `Bearer ${at}`
    let body: BodyInit | undefined
    if (options.form) {
      body = options.form // browser sets multipart boundary
    } else if (options.body !== undefined) {
      headers['Content-Type'] = 'application/json'
      body = JSON.stringify(options.body)
    }
    return fetch(`${API}${path}`, { ...options, headers: { ...headers, ...options.headers }, body })
  }

  let res = await send()

  if (res.status === 401 && tokens.refresh && !path.startsWith('/auth/')) {
    if (await doRefresh()) res = await send()
  }

  if (res.status === 204 || res.status === 201) return undefined as T

  const text = await res.text()
  const payload = text ? safeJson(text) : null

  if (!res.ok) {
    if (res.status === 401 && !path.startsWith('/auth/')) {
      tokens.set(null, null)
      window.dispatchEvent(new Event('equipify:logout'))
    }
    throw new ApiError(res.status, payload?.error ?? payload?.detail ?? `HTTP ${res.status}`)
  }
  return payload as T
}

function safeJson(text: string): any {
  try { return JSON.parse(text) } catch { return text }
}
