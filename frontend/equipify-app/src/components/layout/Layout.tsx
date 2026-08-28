import { useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import './layout.css'
import { useAuth } from '../../auth/AuthContext'
import { useI18n, type Key } from '../../i18n'
import { useTheme } from '../../theme/ThemeProvider'
import logoDark from '../../assets/logo_dark.png'
import logoLight from '../../assets/logo_light.png'

export function Layout() {
  const { t, lang, toggle } = useI18n()
  const { theme, toggle: toggleTheme } = useTheme()
  const { user, isAdmin, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [menuOpen, setMenuOpen] = useState(false)
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)

  useEffect(() => { setMenuOpen(false) }, [location.pathname])

  const links: Array<{ to: string; key: Key }> = [
    { to: '/', key: 'nav.home' },
    { to: '/browse', key: 'nav.browse' },
    { to: '/faq', key: 'nav.faq' },
    { to: '/terms', key: 'nav.terms' },
  ]

  if (user || isAdmin) {
    links.push(
      { to: '/my-listings', key: 'nav.myListings' },
      { to: '/requests', key: 'nav.requests' },
      { to: '/incoming', key: 'nav.incoming' },
    )
  }

  const confirmLogout = () => { setMenuOpen(false); setShowLogoutConfirm(true) }
  const doLogout = () => { setShowLogoutConfirm(false); logout(); navigate('/') }

  return (
    <>
      <header className="navbar" id="main-navbar">
        <div className="container nav-inner">
          <NavLink to="/" className="brand" aria-label="Equipify" id="brand-link">
            <img
              src={theme === 'dark' ? logoDark : logoLight}
              alt="Equipify"
              className="brand-logo"
            />
            <span className="brand-text">Equipify</span>
          </NavLink>

          <nav className={`nav-links${menuOpen ? ' open' : ''}`} onClick={() => setMenuOpen(false)}>
            {links.map(l => (
              <NavLink key={l.to} to={l.to} end={l.to === '/'}>{t(l.key)}</NavLink>
            ))}
            {(user || isAdmin) && <NavLink to="/profile">{t('nav.profile')}</NavLink>}

            {/* Auth actions live inside the mobile drawer */}
            <div className="nav-menu-auth">
              {user || isAdmin ? (
                <button className="btn btn-danger btn-block" onClick={confirmLogout}>{t('nav.logout')}</button>
              ) : (
                <>
                  <NavLink to="/login" className="btn btn-ghost btn-block">{t('nav.login')}</NavLink>
                  <NavLink to="/register" className="btn btn-accent btn-block">{t('nav.register')}</NavLink>
                </>
              )}
            </div>
          </nav>

          <div className="nav-actions">
            <button
              className="btn btn-ghost btn-icon"
              onClick={toggle}
              title={lang === 'ar' ? 'English' : 'العربية'}
              id="lang-toggle-btn"
            >
              {lang === 'ar' ? 'EN' : 'ع'}
            </button>
            <button
              className="btn btn-ghost btn-icon"
              onClick={toggleTheme}
              title="theme"
              id="theme-toggle-btn"
            >
              {theme === 'dark' ? '☀️' : '🌙'}
            </button>

            {user || isAdmin ? (
              <button className="btn btn-sm btn-auth-desktop" onClick={confirmLogout} id="logout-btn">
                {t('nav.logout')}
              </button>
            ) : (
              <>
                <NavLink to="/login" className="btn btn-ghost btn-sm btn-auth-desktop" id="login-btn">
                  {t('nav.login')}
                </NavLink>
                <NavLink to="/register" className="btn btn-accent btn-sm btn-auth-desktop" id="register-btn">
                  {t('nav.register')}
                </NavLink>
              </>
            )}

            <button
              className="btn btn-ghost btn-icon nav-burger"
              aria-label="menu"
              aria-expanded={menuOpen}
              onClick={(e) => { e.stopPropagation(); setMenuOpen(o => !o) }}
              id="mobile-menu-btn"
            >
              {menuOpen ? '✕' : '☰'}
            </button>
          </div>
        </div>
      </header>

      <main className="page container">
        <Outlet />
      </main>

      <footer className="footer container center faint" style={{ display: 'flex', flexDirection: 'column', gap: 8, paddingBottom: 32 }}>
        <div className="row" style={{ justifyContent: 'center', gap: 16 }}>
          <NavLink to="/faq" className="link faint">{t('nav.faq')}</NavLink>
          <span>•</span>
          <NavLink to="/terms" className="link faint">{t('nav.terms')}</NavLink>
          <span>•</span>
          <NavLink to="/download" className="link faint">{t('nav.download')}</NavLink>
          <span>•</span>
          <NavLink to="/admin" className="link faint">{t('nav.adminDashboard')}</NavLink>
        </div>
        <div>Equipify © {new Date().getFullYear()} — rent anything, anywhere.</div>
      </footer>

      {showLogoutConfirm && (
        <div className="modal-overlay" onClick={() => setShowLogoutConfirm(false)}>
          <div className="modal glass-strong animate-fadeInUp" onClick={e => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <h2 style={{ fontSize: '1.15rem', marginBottom: 8 }}>{t('auth.logoutTitle')}</h2>
            <p className="muted" style={{ marginBottom: 20 }}>{t('auth.logoutConfirm')}</p>
            <div className="row" style={{ justifyContent: 'flex-end', gap: 8 }}>
              <button className="btn btn-ghost btn-sm" onClick={() => setShowLogoutConfirm(false)}>{t('common.cancel')}</button>
              <button className="btn btn-danger btn-sm" onClick={doLogout}>{t('nav.logout')}</button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
