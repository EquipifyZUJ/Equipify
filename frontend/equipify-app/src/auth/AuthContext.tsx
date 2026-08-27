import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import { api, tokens } from '../api/client'
import type { AuthUser } from '../api/types'

interface AuthState {
  user: AuthUser | null
  isAdmin: boolean
  ready: boolean
  login: (phoneNumber: string, password: string) => Promise<AuthUser>
  adminLogin: (username: string, password: string) => Promise<void>
  register: (data: { firstName: string; lastName: string; emailAddress: string; phoneNumber: string; password: string; otpCode: string }) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthState>(null!)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [ready, setReady] = useState(false)

  // Decode the JWT payload to know the role without a server call.
  const applyToken = useCallback((accessToken: string) => {
    try {
      const payload = JSON.parse(atob(accessToken.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')))
      const role = payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
      setIsAdmin(role === 'Admin')
      if (role === 'Admin') setUser(null)
    } catch {
      setIsAdmin(false)
    }
  }, [])

  useEffect(() => {
    const at = tokens.access
    if (!at) {
      setReady(true)
      return
    }
    applyToken(at)
    api<AuthUser>('/auth/me')
      .then(setUser)
      .catch(() => {})
      .finally(() => setReady(true))
  }, [])

  useEffect(() => {
    const onRefreshed = (e: Event) => {
      const detail = (e as CustomEvent).detail as AuthUser | undefined
      if (detail) setUser(detail)
    }
    const onLogout = () => {
      setUser(null)
      setIsAdmin(false)
    }
    window.addEventListener('equipify:refreshed', onRefreshed)
    window.addEventListener('equipify:logout', onLogout)
    return () => {
      window.removeEventListener('equipify:refreshed', onRefreshed)
      window.removeEventListener('equipify:logout', onLogout)
    }
  }, [])

  const login = useCallback(async (phoneNumber: string, password: string) => {
    const data = await api<{ accessToken: string; refreshToken: string; user: AuthUser }>('/auth/login', {
      method: 'POST',
      body: { phoneNumber, password },
    })
    tokens.set(data.accessToken, data.refreshToken)
    applyToken(data.accessToken)
    setUser(data.user)
    return data.user
  }, [applyToken])

  const adminLogin = useCallback(async (username: string, password: string) => {
    const data = await api<{ accessToken: string }>('/auth/admin-login', {
      method: 'POST',
      body: { username, password },
    })
    tokens.set(data.accessToken, null)
    applyToken(data.accessToken)
  }, [applyToken])

  const register = useCallback(async (body: { firstName: string; lastName: string; emailAddress: string; phoneNumber: string; password: string; otpCode: string }) => {
    await api('/auth/register', { method: 'POST', body })
  }, [])

  const logout = useCallback(() => {
    const rt = tokens.refresh
    if (rt) api('/auth/logout', { method: 'POST', body: { refreshToken: rt } }).catch(() => {})
    tokens.set(null, null)
    setUser(null)
    setIsAdmin(false)
  }, [])

  return (
    <AuthContext.Provider value={{ user, isAdmin, ready, login, adminLogin, register, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
