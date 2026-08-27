import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { useI18n } from '../i18n'
import { useTheme } from '../theme/ThemeProvider'
import { api } from '../api/client'
import logoDark from '../assets/logo_dark.png'
import logoLight from '../assets/logo_light.png'

/* ─── Login ─── */
export function Login() {
  const { t } = useI18n()
  const { theme } = useTheme()
  const { login } = useAuth()
  const navigate = useNavigate()
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [showForgot, setShowForgot] = useState(false)

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true); setError('')
    try {
      await login(phone, password)
      navigate('/')
    } catch (err: any) {
      setError(err.message ?? t('common.error'))
    } finally { setBusy(false) }
  }

  if (showForgot) return <ForgotPassword onBack={() => setShowForgot(false)} />

  return (
    <form className="auth-card glass-strong form-grid animate-fadeInUp" onSubmit={submit}>
      <div className="center">
        <img
          src={theme === 'dark' ? logoDark : logoLight}
          alt="Equipify"
          className="auth-logo"
        />
        <p className="muted" style={{ marginTop: 12 }}>{t('auth.loginSub')}</p>
      </div>

      {error && <div className="hint-box hint-error">{error}</div>}

      <div className="field">
        <label>{t('auth.phone')}</label>
        <input className="input" dir="ltr" inputMode="numeric" placeholder="07XXXXXXXX" value={phone} onChange={e => setPhone(e.target.value)} required />
      </div>

      <div className="field">
        <label>{t('auth.password')}</label>
        <input className="input" type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required />
      </div>

      <button className="btn btn-accent" type="submit" disabled={busy}>{busy ? '…' : t('nav.login')}</button>

      <div className="center" style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: '0.9rem' }}>
        <button type="button" className="link" style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--accent)' }}
          onClick={() => setShowForgot(true)}>{t('auth.forgotPassword')}</button>
        <span className="muted">
          {t('auth.noAccount')} <Link to="/register" className="link">{t('nav.register')}</Link>
        </span>
      </div>
    </form>
  )
}

/* ─── Forgot Password ─── */
function ForgotPassword({ onBack }: { onBack: () => void }) {
  const { t } = useI18n()
  const { theme } = useTheme()
  const navigate = useNavigate()
  const [step, setStep] = useState<'phone' | 'otp' | 'reset'>('phone')
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [newPass, setNewPass] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const sendOtp = async (e: React.FormEvent) => {
    e.preventDefault(); setBusy(true); setError('')
    try {
      await api('/auth/forgot-password', { method: 'POST', body: { phoneNumber: phone } })
      setStep('otp')
    } catch (err: any) { setError(err.message) }
    finally { setBusy(false) }
  }

  const verifyAndReset = async (e: React.FormEvent) => {
    e.preventDefault(); setBusy(true); setError('')
    try {
      await api('/auth/reset-password', { method: 'POST', body: { phoneNumber: phone, otpCode: otp, newPassword: newPass } })
      navigate('/login')
    } catch (err: any) { setError(err.message) }
    finally { setBusy(false) }
  }

  return (
    <form className="auth-card glass-strong form-grid animate-fadeInUp" onSubmit={step === 'phone' ? sendOtp : verifyAndReset}>
      <div className="center">
        <img
          src={theme === 'dark' ? logoDark : logoLight}
          alt="Equipify"
          className="auth-logo"
        />
        <p className="muted" style={{ marginTop: 12 }}>{t('auth.resetSub')}</p>
      </div>

      {error && <div className="hint-box hint-error">{error}</div>}

      {step === 'phone' && (
        <div className="field">
          <label>{t('auth.phone')}</label>
          <input className="input" dir="ltr" inputMode="numeric" placeholder="07XXXXXXXX" value={phone} onChange={e => setPhone(e.target.value)} required />
        </div>
      )}

      {(step === 'otp' || step === 'reset') && (
        <>
          <div className="hint-box hint-info">📱 {t('auth.otpSent')}</div>
          <div className="field">
            <label>{t('auth.otpCode')}</label>
            <input className="input otp-input" dir="ltr" maxLength={4} inputMode="numeric" placeholder="0000"
              value={otp} onChange={e => { setOtp(e.target.value); if (e.target.value.length === 4) setStep('reset') }} required />
          </div>
          {step === 'reset' && (
            <div className="field">
              <label>{t('auth.newPassword')}</label>
              <input className="input" type="password" minLength={8} value={newPass} onChange={e => setNewPass(e.target.value)} required />
            </div>
          )}
        </>
      )}

      <button className="btn btn-accent" type="submit" disabled={busy}>
        {busy ? '…' : step === 'phone' ? t('auth.sendOtp') : t('auth.resetPassword')}
      </button>
      <button type="button" className="btn btn-ghost" onClick={onBack}>{t('common.back')}</button>
    </form>
  )
}

/* ─── Register ─── */
export function Register() {
  const { t } = useI18n()
  const { theme } = useTheme()
  const { register, login } = useAuth()
  const navigate = useNavigate()
  const [step, setStep] = useState<'form' | 'otp'>('form')
  const [form, setForm] = useState({ firstName: '', lastName: '', emailAddress: '', phoneNumber: '', password: '' })
  const [otp, setOtp] = useState('')
  const [agreed, setAgreed] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm(f => ({ ...f, [k]: e.target.value }))

  const requestOtp = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!agreed) { setError(t('auth.mustAgree')); return }
    setBusy(true); setError('')
    try {
      // Check uniqueness first
      const [emailRes, phoneRes] = await Promise.all([
        api<{ exists: boolean }>(`/auth/check-email?email=${encodeURIComponent(form.emailAddress)}`),
        api<{ exists: boolean }>(`/auth/check-phone?phone=${encodeURIComponent(form.phoneNumber)}`)
      ])
      if (emailRes.exists) { setError(t('auth.emailExists')); setBusy(false); return }
      if (phoneRes.exists) { setError(t('auth.phoneExists')); setBusy(false); return }

      await api('/auth/send-otp', { method: 'POST', body: { phoneNumber: form.phoneNumber } })
      setStep('otp')
    } catch (err: any) { setError(err.message ?? t('common.error')) }
    finally { setBusy(false) }
  }

  const submitRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setBusy(true); setError('')
    try {
      await register({ ...form, otpCode: otp })
      await login(form.phoneNumber, form.password)
      navigate('/')
    } catch (err: any) { setError(err.message ?? t('common.error')) }
    finally { setBusy(false) }
  }

  return (
    <form className="auth-card glass-strong form-grid animate-fadeInUp" onSubmit={step === 'form' ? requestOtp : submitRegister}>
      <div className="center">
        <img
          src={theme === 'dark' ? logoDark : logoLight}
          alt="Equipify"
          className="auth-logo"
        />
        <p className="muted" style={{ marginTop: 12 }}>{t('auth.registerSub')}</p>
      </div>

      {error && <div className="hint-box hint-error">{error}</div>}

      {step === 'form' ? (
        <>
          <div className="row" style={{ gap: 12 }}>
            <div className="field" style={{ flex: 1 }}>
              <label>{t('auth.firstName')}</label>
              <input className="input" value={form.firstName} onChange={set('firstName')} required />
            </div>
            <div className="field" style={{ flex: 1 }}>
              <label>{t('auth.lastName')}</label>
              <input className="input" value={form.lastName} onChange={set('lastName')} required />
            </div>
          </div>
          <div className="field">
            <label>{t('auth.email')}</label>
            <input className="input" type="email" dir="ltr" value={form.emailAddress} onChange={set('emailAddress')} required />
          </div>
          <div className="field">
            <label>{t('auth.phone')} (077/078/079)</label>
            <input className="input" dir="ltr" inputMode="numeric" placeholder="079XXXXXXXX" pattern="(077|078|079)\d{7}" value={form.phoneNumber} onChange={set('phoneNumber')} required />
          </div>
          <div className="field">
            <label>{t('auth.password')}</label>
            <input className="input" type="password" minLength={8} value={form.password} onChange={set('password')} required />
          </div>

          <label className="terms-check">
            <input type="checkbox" checked={agreed} onChange={e => setAgreed(e.target.checked)} />
            <span>{t('auth.agreeTerms')} <Link to="/terms" target="_blank" className="link">{t('auth.termsLink')}</Link></span>
          </label>

          <button className="btn btn-accent" type="submit" disabled={busy || !agreed}>
            {busy ? '…' : t('auth.continue')}
          </button>
        </>
      ) : (
        <>
          <div className="hint-box hint-info">📱 {t('auth.otpSent')}</div>
          <div className="field">
            <label>{t('auth.otpCode')}</label>
            <input className="input otp-input" dir="ltr" maxLength={4} inputMode="numeric" placeholder="0000"
              value={otp} onChange={e => setOtp(e.target.value)} required autoFocus />
          </div>
          <button className="btn btn-accent" type="submit" disabled={busy}>{busy ? '…' : t('nav.register')}</button>
          <button type="button" className="btn btn-ghost" onClick={() => setStep('form')}>{t('common.back')}</button>
        </>
      )}

      <span className="center muted" style={{ fontSize: '0.9rem' }}>
        {t('auth.haveAccount')} <Link to="/login" className="link">{t('nav.login')}</Link>
      </span>
    </form>
  )
}
