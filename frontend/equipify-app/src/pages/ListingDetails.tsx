import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api, img } from '../api/client'
import type { Listing, Review } from '../api/types'
import { MiniMap } from '../components/map/Maps'
import { Empty, Spinner, Stars } from '../components/ui'
import { useAuth } from '../auth/AuthContext'
import { useToast } from '../components/ToastProvider'
import { useI18n } from '../i18n'

export default function ListingDetails() {
  const { id } = useParams()
  const { t } = useI18n()
  const { user } = useAuth()
  const toast = useToast()
  const navigate = useNavigate()
  const unitSingular = (u: string) => t(`browse.unit${u.charAt(0).toUpperCase() + u.slice(1)}Singular` as any)

  const [listing, setListing] = useState<Listing | null>(null)
  const [loading, setLoading] = useState(true)
  const [activeImg, setActiveImg] = useState(0)
  const [reviews, setReviews] = useState<Review[]>([])

  // Booking state
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [fromTime, setFromTime] = useState('09:00')
  const [toTime, setToTime] = useState('17:00')
  const [otpSent, setOtpSent] = useState(false)
  const [otpCode, setOtpCode] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    setLoading(true)
    api<Listing>(`/listings/${id}`)
      .then(l => setListing(l))
      .catch(() => setListing(null))
      .finally(() => setLoading(false))
    api<Review[]>(`/listings/${id}/reviews`).then(setReviews).catch(() => {})
  }, [id])

  if (loading) return <Spinner />
  if (!listing) return <Empty icon="😕" text={t('listing.notFound')} />

  const today = new Date().toISOString().slice(0, 10)
  const primaryPrice = listing.rentalUnit === 'hour' ? listing.costPerHour
    : listing.rentalUnit === 'week' ? listing.costPerWeek
    : listing.rentalUnit === 'month' ? listing.costPerMonth
    : listing.rentalUnit === 'year' ? listing.costPerYear
    : listing.costPerDay
  const days = fromDate && toDate
    ? Math.max(1, Math.round((+new Date(toDate) - +new Date(fromDate)) / 86_400_000))
    : 0
  const total = days * (primaryPrice ?? listing.costPerDay)

  const sendOtp = async () => {
    setBusy(true)
    try {
      const res = await api<{ devCode: string | null }>('/requests/otp/send', {
        method: 'POST',
        body: { listingId: listing.id },
      })
      setOtpSent(true)
      toast(t('listing.otpSent') + (res.devCode ? ` — ${res.devCode}` : ''), 'info')
    } catch (e: any) {
      toast(e.message ?? t('common.error'), 'error')
    } finally {
      setBusy(false)
    }
  }

  const submitRequest = async () => {
    if (!fromDate || !toDate) return
    setBusy(true)
    try {
      await api('/requests', {
        method: 'POST',
        body: {
          listingId: listing.id,
          fromDate,
          toDate,
          fromTime: `${fromTime}:00`,
          toTime: `${toTime}:00`,
          otpCode,
        },
      })
      toast(t('listing.confirmRequest') + ' ✓')
      navigate('/requests')
    } catch (e: any) {
      toast(e.message ?? t('common.error'), 'error')
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <div className="details-grid">
        {/* Left column */}
        <div>
          <div className="gallery-main glass" style={{ padding: 0 }}>
            <img className="img-cover" src={img(listing.images[activeImg])} alt={listing.title} />
          </div>
          {listing.images.length > 1 && (
            <div className="thumbs">
              {listing.images.map((src, i) => (
                <div key={src} className={`thumb ${i === activeImg ? 'on' : ''}`} onClick={() => setActiveImg(i)}>
                  <img src={img(src)} alt="" loading="lazy" />
                </div>
              ))}
            </div>
          )}

          <h1 style={{ marginBlock: '20px 6px', fontSize: '1.7rem' }}>{listing.title}</h1>
          <div className="row muted" style={{ fontSize: '0.95rem' }}>
            <span>📍 {listing.locationAddress}</span>
            <span>•</span>
            <span>{listing.categoryName}</span>
            {listing.owner?.rating != null && (
              <>
                <span>•</span>
                <Stars value={Math.round(listing.owner.rating)} />
                <span>{listing.owner.rating.toFixed(1)}</span>
              </>
            )}
          </div>

          <p style={{ marginTop: 16, lineHeight: 1.9, color: 'var(--text-soft)' }}>{listing.description}</p>

          {reviews.length > 0 && (
            <div style={{ marginTop: 20 }}>
              <h3 style={{ fontSize: '1.05rem', marginBottom: 10 }}>⭐ {t('auth.reviews')}</h3>
              <div className="form-grid" style={{ gap: 10 }}>
                {reviews.map(r => (
                  <div key={r.id} className="glass" style={{ padding: 12, borderRadius: 10 }}>
                    <div className="between" style={{ marginBottom: 4 }}>
                      <strong style={{ fontSize: '0.9rem' }}>{r.renterName}</strong>
                      <Stars value={Math.round(r.rating)} />
                    </div>
                    <p className="muted" style={{ fontSize: '0.82rem', margin: 0 }}>
                      {r.listingTitle} — {new Date(r.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="mini-map glass" style={{ padding: 0 }}>
            <MiniMap lat={listing.latitude} lng={listing.longitude} title={listing.title} />
          </div>
        </div>

        {/* Right column — booking */}
        <aside className="booking-card glass-strong">
          <div className="between">
            <span style={{ fontSize: '1.5rem', fontWeight: 800 }}>
              {primaryPrice ?? listing.costPerDay} <small className="muted" style={{ fontSize: '0.85rem' }}>{t(listing.rentalUnit === 'hour' ? 'listing.perHour' : listing.rentalUnit === 'week' ? 'listing.perWeek' : listing.rentalUnit === 'month' ? 'listing.perMonth' : listing.rentalUnit === 'year' ? 'listing.perYear' : 'listing.perDay')}</small>
            </span>
            <span className={`badge ${listing.status === 'Active' ? 'badge-ok' : 'badge-warn'}`}>
              {t(`status.${listing.status}` as any)}
            </span>
          </div>

          {/* Other prices */}
          {(() => {
            const others: { val: number | null; key: string }[] = []
            if (listing.rentalUnit !== 'hour' && listing.costPerHour != null) others.push({ val: listing.costPerHour, key: 'listing.perHour' })
            if (listing.rentalUnit !== 'day') others.push({ val: listing.costPerDay, key: 'listing.perDay' })
            if (listing.rentalUnit !== 'week' && listing.costPerWeek != null) others.push({ val: listing.costPerWeek, key: 'listing.perWeek' })
            if (listing.rentalUnit !== 'month' && listing.costPerMonth != null) others.push({ val: listing.costPerMonth, key: 'listing.perMonth' })
            if (listing.rentalUnit !== 'year' && listing.costPerYear != null) others.push({ val: listing.costPerYear, key: 'listing.perYear' })
            return others.length > 0 && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
                {others.map(o => <span key={o.key} className="badge badge-info">{o.val} {t(o.key as any)}</span>)}
              </div>
            )
          })()}

          {/* Min/Max duration — labels match the listing's rental unit */}
          {(listing.minRentalDays || listing.maxRentalDays) && (
            <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
              {listing.minRentalDays != null && <span className="badge badge-warn">≥ {listing.minRentalDays} {unitSingular(listing.rentalUnit)}</span>}
              {listing.maxRentalDays != null && <span className="badge badge-warn">≤ {listing.maxRentalDays} {unitSingular(listing.rentalUnit)}</span>}
            </div>
          )}

          {!user ? (
            <Link to="/login" className="btn btn-accent">{t('listing.loginToBook')}</Link>
          ) : (
            <>
              <div className="form-grid">
                <div className="field">
                  <label>{t('listing.from')}</label>
                  <input type="date" className="input" min={today} value={fromDate} onChange={e => setFromDate(e.target.value)} />
                </div>
                <div className="field">
                  <label>{t('listing.to')}</label>
                  <input type="date" className="input" min={fromDate || today} value={toDate} onChange={e => setToDate(e.target.value)} />
                </div>
                <div className="row" style={{ gap: 10 }}>
                  <div className="field" style={{ flex: 1 }}>
                    <label>{t('listing.pickupTime')}</label>
                    <input type="time" className="input" value={fromTime} onChange={e => setFromTime(e.target.value)} />
                  </div>
                  <div className="field" style={{ flex: 1 }}>
                    <label>{t('listing.returnTime')}</label>
                    <input type="time" className="input" value={toTime} onChange={e => setToTime(e.target.value)} />
                  </div>
                </div>
              </div>

              {days > 0 && (
                <div className="between" style={{ borderTop: '1px solid var(--glass-border)', paddingTop: 12 }}>
                  <span className="muted">{t('listing.days', { n: days })}</span>
                  <span className="booking-total">{total.toFixed(2)}</span>
                </div>
              )}

              {!otpSent ? (
                <button
                  className="btn btn-accent"
                  disabled={!fromDate || !toDate || busy}
                  onClick={sendOtp}
                >
                  📱 {t('listing.sendOtp')}
                </button>
              ) : (
                <>
                  <div className="field">
                    <label>{t('listing.otpLabel')}</label>
                    <input
                      className="input"
                      inputMode="numeric"
                      maxLength={4}
                      placeholder="0000"
                      style={{ letterSpacing: 8, textAlign: 'center', fontWeight: 800 }}
                      value={otpCode}
                      onChange={e => setOtpCode(e.target.value)}
                    />
                  </div>
                  <button className="btn btn-ok" disabled={otpCode.length !== 4 || busy} onClick={submitRequest}>
                    ✓ {t('listing.confirmRequest')}
                  </button>
                </>
              )}
            </>
          )}

          <div className="owner-card glass">
            <div className="avatar">{listing.owner?.name.charAt(0).toUpperCase() ?? '?'}</div>
            <div>
              <div style={{ fontWeight: 700 }}>{t('listing.owner')}</div>
              <div className="muted" style={{ fontSize: '0.9rem' }}>{listing.owner?.name}</div>
              {listing.owner?.rating != null && (
                <Stars value={Math.round(listing.owner.rating)} />
              )}
            </div>
          </div>
        </aside>
      </div>
    </>
  )
}
