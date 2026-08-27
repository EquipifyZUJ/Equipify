import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api/client'
import type { AuthUser, Review } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { Stars } from '../components/ui'
import { useToast } from '../components/ToastProvider'
import { useI18n } from '../i18n'

export default function Profile() {
  const { t } = useI18n()
  const { user, logout } = useAuth()
  const toast = useToast()
  const navigate = useNavigate()

  const [form, setForm] = useState({ firstName: '', lastName: '', emailAddress: '', phoneNumber: '' })
  const [pw, setPw] = useState({ currentPassword: '', newPassword: '' })
  const [busy, setBusy] = useState(false)
  const [reviews, setReviews] = useState<Review[]>([])
  const [reviewsLoading, setReviewsLoading] = useState(true)

  useEffect(() => {
    if (user) setForm({ firstName: user.firstName, lastName: user.lastName, emailAddress: user.emailAddress, phoneNumber: user.phoneNumber })
  }, [user])

  useEffect(() => {
    if (!user) return
    setReviewsLoading(true)
    api<Review[]>(`/users/${user.id}/reviews`)
      .then(setReviews)
      .catch(() => {})
      .finally(() => setReviewsLoading(false))
  }, [user])

  if (!user) return null

  const saveProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true)
    try {
      await api<AuthUser>('/auth/me', { method: 'PUT', body: form })
      toast('✓')
    } catch (err: any) {
      toast(err.message ?? t('common.error'), 'error')
    } finally {
      setBusy(false)
    }
  }

  const changePw = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true)
    try {
      await api('/auth/change-password', { method: 'POST', body: pw })
      toast('✓')
      setPw({ currentPassword: '', newPassword: '' })
      logout()
      navigate('/login')
    } catch (err: any) {
      toast(err.message ?? t('common.error'), 'error')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div style={{ maxWidth: 560, marginInline: 'auto' }} className="form-grid animate-fadeInUp">
      <div className="glass-strong" style={{ padding: 26 }}>
        <div className="row" style={{ gap: 16 }}>
          <div className="avatar" style={{ width: 62, height: 62, fontSize: '1.6rem' }}>{user.firstName.charAt(0).toUpperCase()}</div>
          <div>
            <h1 style={{ fontSize: '1.3rem' }}>{user.name}</h1>
            {user.rating != null && (
              <span className="muted" style={{ fontSize: '0.9rem' }}>
                {t('auth.myRating')}: <Stars value={Math.round(user.rating)} /> {user.rating.toFixed(1)}
              </span>
            )}
          </div>
        </div>
      </div>

      <form className="glass-strong form-grid" style={{ padding: 26 }} onSubmit={saveProfile}>
        <h2 style={{ fontSize: '1.1rem' }}>👤 {t('nav.profile')}</h2>
        <div className="row" style={{ gap: 12 }}>
          <div className="field" style={{ flex: 1 }}>
            <label>{t('auth.firstName')}</label>
            <input className="input" value={form.firstName} onChange={e => setForm(f => ({ ...f, firstName: e.target.value }))} />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>{t('auth.lastName')}</label>
            <input className="input" value={form.lastName} onChange={e => setForm(f => ({ ...f, lastName: e.target.value }))} />
          </div>
        </div>
        <div className="field">
          <label>{t('auth.email')}</label>
          <input className="input" type="email" dir="ltr" value={form.emailAddress} onChange={e => setForm(f => ({ ...f, emailAddress: e.target.value }))} />
        </div>
        <div className="field">
          <label>{t('auth.phone')}</label>
          <input className="input" dir="ltr" value={form.phoneNumber} onChange={e => setForm(f => ({ ...f, phoneNumber: e.target.value }))} />
        </div>
        <button className="btn btn-accent" disabled={busy}>{t('auth.saveChanges')}</button>
      </form>

      <form className="glass-strong form-grid" style={{ padding: 26 }} onSubmit={changePw}>
        <h2 style={{ fontSize: '1.1rem' }}>🔒 {t('auth.changePassword')}</h2>
        <div className="field">
          <label>{t('auth.currentPassword')}</label>
          <input className="input" type="password" required value={pw.currentPassword} onChange={e => setPw(p => ({ ...p, currentPassword: e.target.value }))} />
        </div>
        <div className="field">
          <label>{t('auth.newPassword')}</label>
          <input className="input" type="password" required minLength={8} value={pw.newPassword} onChange={e => setPw(p => ({ ...p, newPassword: e.target.value }))} />
        </div>
        <button className="btn" disabled={busy}>{t('auth.changePassword')}</button>
      </form>

      <div className="glass-strong" style={{ padding: 26 }}>
        <h2 style={{ fontSize: '1.1rem', marginBottom: 14 }}>⭐ {t('auth.reviews')}</h2>
        {reviewsLoading ? (
          <p className="muted">{t('common.loading')}</p>
        ) : reviews.length === 0 ? (
          <p className="muted">{t('auth.noReviews')}</p>
        ) : (
          <div className="form-grid" style={{ gap: 12 }}>
            {reviews.map(r => (
              <div key={r.id} className="glass" style={{ padding: 14, borderRadius: 12 }}>
                <div className="between" style={{ marginBottom: 6 }}>
                  <strong>{r.renterName}</strong>
                  <Stars value={Math.round(r.rating)} />
                </div>
                <p className="muted" style={{ fontSize: '0.85rem', margin: 0 }}>
                  {r.listingTitle} — {new Date(r.createdAt).toLocaleDateString()}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
