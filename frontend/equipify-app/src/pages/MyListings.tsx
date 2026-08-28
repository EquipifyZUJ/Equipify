import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, img } from '../api/client'
import type { ListingSummary } from '../api/types'
import { ConfirmModal, Empty, Spinner } from '../components/ui'
import { useToast } from '../components/ToastProvider'
import { useI18n } from '../i18n'

const statusBadge = (s: string) =>
  s === 'Active' ? 'badge-ok' : s === 'Pending' ? 'badge-warn' : 'badge-bad'

export default function MyListings() {
  const { t } = useI18n()
  const toast = useToast()
  const [listings, setListings] = useState<ListingSummary[] | null>(null)
  const [toDelete, setToDelete] = useState<ListingSummary | null>(null)
  const [toToggle, setToToggle] = useState<ListingSummary | null>(null)
  const [busy, setBusy] = useState(false)

  const load = useCallback(() => {
    api<ListingSummary[]>('/listings/mine').then(setListings).catch(() => setListings([]))
  }, [])

  useEffect(load, [load])

  if (listings === null) return <Spinner />

  const doToggle = async () => {
    if (!toToggle || busy) return
    const target = toToggle.status === 'Active' ? 'Inactive' : 'Active'
    setBusy(true)
    try {
      await api(`/listings/${toToggle.id}/status`, {
        method: 'POST',
        body: { status: target },
      })
      toast(target === 'Active' ? `▶ ${t('listings.activate')} ✓` : `⏸ ${t('listings.deactivate')} ✓`)
      load()
    } catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
    finally { setBusy(false); setToToggle(null) }
  }

  const remove = async () => {
    if (toDelete === null || busy) return
    setBusy(true)
    try {
      await api(`/listings/${toDelete.id}`, { method: 'DELETE' })
      toast('🗑 ✓')
      load()
    } catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
    finally { setBusy(false); setToDelete(null) }
  }

  return (
    <>
      <div className="between" style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.5rem' }}>{t('listings.mine')}</h1>
        <Link to="/my-listings/new" className="btn btn-accent btn-sm">＋ {t('listings.addNew')}</Link>
      </div>

      {listings.length === 0 && <Empty icon="📦" text={t('listings.empty')} />}

      <div className="grid listing-grid">
        {listings.map(l => (
          <div key={l.id} className="listing-card glass">
            <Link to={`/listings/${l.id}`} className="card-media">
              <img src={img(l.mainImage)} alt={l.title} loading="lazy" />
              <span className={`badge ${statusBadge(l.status)}`} style={{ position: 'absolute', top: 10, insetInlineEnd: 10 }}>
                {t(`status.${l.status}` as any)}
              </span>
            </Link>
            <div className="card-body">
              <div className="card-title">{l.title}</div>
              <div className="card-sub">{l.costPerDay} {t('listing.perDay')} · 📍{l.locationAddress}</div>
              <div className="row" style={{ marginTop: 12, flexWrap: 'wrap', gap: 8 }}>
                <Link to={`/my-listings/${l.id}/edit`} className="btn btn-ghost btn-sm" title={t('listings.edit')}>✏️ {t('listings.edit')}</Link>
                {l.status === 'Active' && (
                  <button className="btn btn-ghost btn-sm" disabled={busy} onClick={() => setToToggle(l)} title={t('listings.deactivate')}>
                    ⏸ {t('listings.deactivate')}
                  </button>
                )}
                {l.status === 'Inactive' && (
                  <button className="btn btn-accent btn-sm" disabled={busy} onClick={() => setToToggle(l)} title={t('listings.activate')}>
                    ▶ {t('listings.activate')}
                  </button>
                )}
                {l.status === 'Pending' && (
                  <span className="badge badge-warn" style={{ fontSize: '0.7rem' }}>{t('listings.pendingAdminApproval')}</span>
                )}
                <button className="btn btn-danger btn-sm" disabled={busy} onClick={() => setToDelete(l)} title={t('admin.confirmDelete')}>🗑</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <ConfirmModal open={toDelete !== null} text={toDelete ? `${t('admin.confirmDelete')} "${toDelete.title}"?` : t('admin.confirmDelete')} onConfirm={remove} onClose={() => setToDelete(null)} />
      <ConfirmModal
        open={toToggle !== null}
        text={toToggle ? `${toToggle.status === 'Active' ? t('listings.deactivate') : t('listings.activate')} "${toToggle.title}"?` : ''}
        onConfirm={doToggle}
        onClose={() => setToToggle(null)}
      />
    </>
  )
}
