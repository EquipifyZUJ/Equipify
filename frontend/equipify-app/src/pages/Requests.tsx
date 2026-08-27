import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, img } from '../api/client'
import type { RentalRequest } from '../api/types'
import { ConfirmModal, Empty, Modal, Spinner, Stars } from '../components/ui'
import { useToast } from '../components/ToastProvider'
import { useI18n } from '../i18n'

const statusBadge = (s: string) =>
  s === 'Accepted' ? 'badge-ok' : s === 'Rejected' ? 'badge-bad' : 'badge-warn'

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

/** Outgoing requests placed by the current user. */
export function MyRequests() {
  const { t } = useI18n()
  const toast = useToast()
  const [requests, setRequests] = useState<RentalRequest[] | null>(null)
  const [cancelId, setCancelId] = useState<number | null>(null)
  const [rating, setRating] = useState<{ id: number; stars: number } | null>(null)

  const load = useCallback(() => {
    api<RentalRequest[]>('/requests/mine').then(setRequests).catch(() => setRequests([]))
  }, [])
  useEffect(load, [load])

  if (requests === null) return <Spinner />

  const cancel = async () => {
    if (cancelId === null) return
    try { await api(`/requests/${cancelId}`, { method: 'DELETE' }); toast('✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  const submitRating = async () => {
    if (!rating) return
    try {
      await api(`/requests/${rating.id}/rating`, { method: 'POST', body: { rating: rating.stars } })
      toast('⭐ ✓')
      load()
    } catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  return (
    <>
      <h1 style={{ fontSize: '1.5rem', marginBottom: 20 }}>{t('requests.mine')}</h1>
      {requests.length === 0 && <Empty icon="🧾" text={t('requests.none')} />}

      <div className="form-grid">
        {requests.map(r => (
          <div key={r.id} className="request-row glass">
            <Link to={`/listings/${r.listingId}`}>
              <img src={img(r.listingImage ?? '/placeholder.svg')} alt="" loading="lazy" />
            </Link>
            <div style={{ flex: 1, minWidth: 180 }}>
              <strong><Link to={`/listings/${r.listingId}`} style={{ color: 'inherit', textDecoration: 'none' }}>{r.listingTitle}</Link></strong>
              <div className="faint" dir="ltr">
                {fmtDate(r.fromDate)} → {fmtDate(r.toDate)} · {r.totalCost.toFixed(2)} JOD
              </div>
            </div>
            <span className={`badge ${statusBadge(r.status)}`}>{t(`status.${r.status}` as any)}</span>
            {r.status === 'Pending' && (
              <button className="btn btn-ghost btn-sm" onClick={() => setCancelId(r.id)}>✕ {t('requests.cancel')}</button>
            )}
            {r.status === 'Accepted' && !r.hasRating && (
              <button className="btn btn-accent btn-sm" onClick={() => setRating({ id: r.id, stars: 0 })}>⭐ {t('requests.rate')}</button>
            )}
          </div>
        ))}
      </div>

      <ConfirmModal open={cancelId !== null} text={t('admin.confirmDelete')} onConfirm={cancel} onClose={() => setCancelId(null)} />

      <Modal open={rating !== null} title={t('requests.rateTitle')} onClose={() => setRating(null)}>
        <div className="center form-grid">
          <Stars value={rating?.stars ?? 0} onChange={stars => setRating(r => (r ? { ...r, stars } : r))} />
          <button className="btn btn-accent" disabled={!rating?.stars} onClick={submitRating}>{t('requests.submitRating')}</button>
        </div>
      </Modal>
    </>
  )
}

/** Incoming requests on listings owned by the current user. */
export function IncomingRequests() {
  const { t } = useI18n()
  const toast = useToast()
  const [requests, setRequests] = useState<RentalRequest[] | null>(null)

  const load = useCallback(() => {
    api<RentalRequest[]>('/requests/incoming').then(setRequests).catch(() => setRequests([]))
  }, [])
  useEffect(load, [load])

  if (requests === null) return <Spinner />

  const decide = async (id: number, action: 'accept' | 'reject') => {
    try { await api(`/requests/${id}/${action}`, { method: 'POST' }); toast('✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  return (
    <>
      <h1 style={{ fontSize: '1.5rem', marginBottom: 20 }}>{t('requests.incoming')}</h1>
      {requests.length === 0 && <Empty icon="📥" text={t('requests.none')} />}

      <div className="form-grid">
        {requests.map(r => (
          <div key={r.id} className="request-row glass">
            <img src={img(r.listingImage ?? '/placeholder.svg')} alt="" loading="lazy" />
            <div style={{ flex: 1, minWidth: 200 }}>
              <strong>{r.listingTitle}</strong>
              <div className="faint">
                👤 {r.renter.name} · 📞 <a href={`tel:${r.renter.phoneNumber}`} className="link" dir="ltr">{r.renter.phoneNumber}</a>
              </div>
              <div className="faint" dir="ltr">
                {fmtDate(r.fromDate)} → {fmtDate(r.toDate)} · {r.totalCost.toFixed(2)} JOD
              </div>
            </div>
            <span className={`badge ${statusBadge(r.status)}`}>{t(`status.${r.status}` as any)}</span>
            {r.status === 'Pending' && (
              <>
                <button className="btn btn-ok btn-sm" onClick={() => decide(r.id, 'accept')}>✓ {t('requests.accept')}</button>
                <button className="btn btn-danger btn-sm" onClick={() => decide(r.id, 'reject')}>✕ {t('requests.reject')}</button>
              </>
            )}
          </div>
        ))}
      </div>
    </>
  )
}
