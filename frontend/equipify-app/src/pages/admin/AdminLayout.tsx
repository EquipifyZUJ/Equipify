import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../../auth/AuthContext'
import { useI18n, type Key } from '../../i18n'

const links: Array<{ to: string; key: Key; end?: boolean }> = [
  { to: '/admin', key: 'admin.dashboard', end: true },
  { to: '/admin/listings', key: 'admin.listings' },
  { to: '/admin/users', key: 'admin.users' },
  { to: '/admin/categories', key: 'admin.categories' },
  { to: '/admin/requests', key: 'admin.requests' },
]

export default function AdminLayout() {
  const { t } = useI18n()
  const { isAdmin, ready, adminLogin } = useAuth()

  if (!ready) return null

  // Admin login gate
  if (!isAdmin) return <AdminGate t={t} adminLogin={adminLogin} />

  return (
    <div className="admin-layout">
      <nav className="admin-nav glass">
        {links.map(l => (
          <NavLink key={l.to} to={l.to} end={l.end}>{t(l.key)}</NavLink>
        ))}
      </nav>
      <div style={{ minWidth: 0 }}>
        <Outlet />
      </div>
    </div>
  )
}

function AdminGate({ t, adminLogin }: { t: (k: string) => string; adminLogin: (u: string, p: string) => Promise<void> }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true); setError('')
    try {
      await adminLogin(username, password)
    } catch (err: any) {
      setError(err.message ?? t('common.error'))
    } finally { setBusy(false) }
  }

  return (
    <div className="admin-gate-container">
      <form className="auth-card glass-strong form-grid animate-fadeInUp" onSubmit={submit}>
        <div className="center">
          <h1 style={{ fontSize: '1.5rem' }}>{t('admin.loginTitle')}</h1>
          <p className="muted" style={{ marginTop: 6 }}>{t('admin.loginSub')}</p>
        </div>

        {error && <div className="hint-box hint-error">{error}</div>}

        <div className="field">
          <label>{t('auth.username')}</label>
          <input className="input" dir="ltr" autoComplete="username" value={username} onChange={e => setUsername(e.target.value)} required autoFocus />
        </div>

        <div className="field">
          <label>{t('auth.password')}</label>
          <input className="input" type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required />
        </div>

        <button className="btn btn-accent" type="submit" disabled={busy}>
          {busy ? '…' : t('nav.login')}
        </button>

        <p className="muted center" style={{ fontSize: '0.75rem', marginTop: 4 }}>
          Dev: admin / Admin@12345
        </p>
      </form>
    </div>
  )
}
