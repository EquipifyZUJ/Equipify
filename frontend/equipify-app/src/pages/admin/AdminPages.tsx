import { useEffect, useState } from 'react'
import { api, img } from '../../api/client'
import type { DashboardStats, ListingSummary, RentalRequest, AuthUser, Category } from '../../api/types'
import { ConfirmModal, Empty, Modal, Spinner, Stars } from '../../components/ui'
import { useToast } from '../../components/ToastProvider'
import { useI18n } from '../../i18n'

const statusBadge = (s: string) =>
  s === 'Active' || s === 'Accepted' ? 'badge-ok' : s === 'Pending' ? 'badge-warn' : 'badge-bad'

// ---------------- Dashboard ----------------
export function AdminDashboard() {
  const { t } = useI18n()
  const [stats, setStats] = useState<DashboardStats | null>(null)

  useEffect(() => {
    api<DashboardStats>('/admin/dashboard').then(setStats).catch(() => {})
  }, [])

  if (!stats) return <Spinner />

  const cards: Array<{ num: number; lbl: string; icon: string }> = [
    { num: stats.users, lbl: t('admin.stat.users'), icon: '👥' },
    { num: stats.listings, lbl: t('admin.stat.listings'), icon: '📦' },
    { num: stats.activeListings, lbl: t('admin.stat.activeListings'), icon: '✅' },
    { num: stats.pendingListings, lbl: t('admin.stat.pendingListings'), icon: '⏳' },
    { num: stats.requests, lbl: t('admin.stat.requests'), icon: '🧾' },
    { num: stats.pendingRequests, lbl: t('admin.stat.pendingRequests'), icon: '🔔' },
  ]

  return (
    <div className="grid stat-grid">
      {cards.map(c => (
        <div key={c.lbl} className="stat-card glass-strong">
          <div>{c.icon}</div>
          <div className="num">{c.num}</div>
          <div className="lbl">{c.lbl}</div>
        </div>
      ))}
    </div>
  )
}

// ---------------- Users ----------------
export function AdminUsers() {
  const { t } = useI18n()
  const toast = useToast()
  const [users, setUsers] = useState<AuthUser[] | null>(null)
  const [editing, setEditing] = useState<AuthUser | null>(null)
  const [toDelete, setToDelete] = useState<number | null>(null)

  const load = () => api<AuthUser[]>('/admin/users').then(setUsers).catch(() => setUsers([]))
  useEffect(() => { load() }, [])

  if (users === null) return <Spinner />

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    try {
      await api(`/admin/users/${editing.id}`, {
        method: 'PUT',
        body: { firstName: editing.firstName, lastName: editing.lastName, emailAddress: editing.emailAddress, phoneNumber: editing.phoneNumber },
      })
      setEditing(null); toast('✓'); load()
    } catch (err: any) { toast(err.message ?? t('common.error'), 'error') }
  }

  const toggleStatus = async (u: AuthUser) => {
    try { await api(`/admin/users/${u.id}/toggle-status`, { method: 'POST' }); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  const remove = async () => {
    if (toDelete === null) return
    try { await api(`/admin/users/${toDelete}`, { method: 'DELETE' }); toast('🗑 ✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  return (
    <>
      <h1 style={{ fontSize: '1.4rem', marginBottom: 18 }}>👥 {t('admin.users')}</h1>
      {users.length === 0 && <Empty text={t('requests.none')} />}
      <div className="table-wrap glass">
        <table className="glass-table">
          <thead>
            <tr><th>#</th><th>{t('auth.name')}</th><th>{t('auth.phone')}</th><th>{t('auth.email')}</th><th>⭐</th><th></th></tr>
          </thead>
          <tbody>
            {users.map(u => (
              <tr key={u.id}>
                <td>{u.id}</td>
                <td style={{ fontWeight: 700 }}>{u.name}</td>
                <td dir="ltr">{u.phoneNumber}</td>
                <td dir="ltr" className="muted">{u.emailAddress}</td>
                <td>{u.rating != null ? <Stars value={Math.round(u.rating)} /> : '—'}</td>
                <td>
                  <div className="row" style={{ gap: 6, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
                    <span className={`badge ${u.status === 'Active' ? 'badge-ok' : 'badge-bad'}`}>{t(`status.${u.status}` as any)}</span>
                    <button className="btn btn-ghost btn-sm" onClick={() => setEditing(u)}>✏️</button>
                    <button className="btn btn-ghost btn-sm" onClick={() => toggleStatus(u)}>🔒</button>
                    <button className="btn btn-danger btn-sm" onClick={() => setToDelete(u.id)}>🗑</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Modal open={editing !== null} title={`✏️ ${editing?.name ?? ''}`} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form-grid" onSubmit={save}>
            <div className="row" style={{ gap: 12 }}>
              <div className="field" style={{ flex: 1 }}>
                <label>{t('auth.firstName')}</label>
                <input className="input" value={editing.firstName} onChange={e => setEditing({ ...editing, firstName: e.target.value })} required />
              </div>
              <div className="field" style={{ flex: 1 }}>
                <label>{t('auth.lastName')}</label>
                <input className="input" value={editing.lastName} onChange={e => setEditing({ ...editing, lastName: e.target.value })} required />
              </div>
            </div>
            <div className="field">
              <label>{t('auth.email')}</label>
              <input className="input" type="email" dir="ltr" value={editing.emailAddress} onChange={e => setEditing({ ...editing, emailAddress: e.target.value })} required />
            </div>
            <div className="field">
              <label>{t('auth.phone')}</label>
              <input className="input" dir="ltr" value={editing.phoneNumber} onChange={e => setEditing({ ...editing, phoneNumber: e.target.value })} required />
            </div>
            <button className="btn btn-accent">{t('common.save')}</button>
          </form>
        )}
      </Modal>

      <ConfirmModal open={toDelete !== null} text={t('admin.confirmDelete')} onConfirm={remove} onClose={() => setToDelete(null)} />
    </>
  )
}

// ---------------- Listings ----------------
export function AdminListings() {
  const { t } = useI18n()
  const toast = useToast()
  const [listings, setListings] = useState<ListingSummary[] | null>(null)
  const [toDelete, setToDelete] = useState<number | null>(null)
  const [filter, setFilter] = useState<'All' | 'Pending' | 'Active' | 'Inactive'>('All')

  const load = () => api<ListingSummary[]>('/admin/listings').then(setListings).catch(() => setListings([]))
  useEffect(() => { load() }, [])

  if (listings === null) return <Spinner />

  const filtered = filter === 'All' ? listings : listings.filter(l => l.status === filter)
  const pendingCount = listings.filter(l => l.status === 'Pending').length

  const act = async (id: number, action: string) => {
    try { await api(`/admin/listings/${id}/${action}`, { method: 'POST' }); toast('✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  const remove = async () => {
    if (toDelete === null) return
    try { await api(`/admin/listings/${toDelete}`, { method: 'DELETE' }); toast('🗑 ✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  return (
    <>
      <div className="between" style={{ marginBottom: 18 }}>
        <h1 style={{ fontSize: '1.4rem' }}>📦 {t('admin.listings')}</h1>
        {pendingCount > 0 && (
          <span className="badge badge-warn" style={{ fontSize: '0.85rem', padding: '4px 12px' }}>
            ⏳ {pendingCount} {t('status.Pending')}
          </span>
        )}
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
        {(['All', 'Pending', 'Active', 'Inactive'] as const).map(s => (
          <button
            key={s}
            className={`btn btn-sm ${filter === s ? 'btn-accent' : 'btn-ghost'}`}
            onClick={() => setFilter(s)}
          >
            {s === 'All' ? t('admin.allListings') : t(`status.${s}` as any)}
            {s === 'Pending' && pendingCount > 0 ? ` (${pendingCount})` : ''}
          </button>
        ))}
      </div>

      <div className="table-wrap glass">
        <table className="glass-table">
          <thead>
            <tr>
              <th></th>
              <th>#</th>
              <th>{t('listings.titleField')}</th>
              <th>{t('listings.category')}</th>
              <th>💰</th>
              <th>{t('listings.statusField')}</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(l => (
              <tr key={l.id} style={l.status === 'Pending' ? { backgroundColor: 'rgba(251, 191, 36, 0.06)' } : undefined}>
                <td>
                  <img
                    src={img(l.mainImage)}
                    alt=""
                    style={{ width: 44, height: 34, objectFit: 'cover', borderRadius: 6 }}
                    loading="lazy"
                  />
                </td>
                <td>{l.id}</td>
                <td style={{ fontWeight: 700, maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{l.title}</td>
                <td className="muted">{l.categoryName}</td>
                <td dir="ltr">{l.costPerDay.toFixed(2)} JOD</td>
                <td>
                  <span className={`badge ${statusBadge(l.status)}`}>{t(`status.${l.status}` as any)}</span>
                </td>
                <td>
                  <div className="row" style={{ gap: 6, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
                    {l.status === 'Pending' && (
                      <button className="btn btn-ok btn-sm" onClick={() => act(l.id, 'approve')}>
                        ✓ {t('admin.approve')}
                      </button>
                    )}
                    {l.status === 'Active' && (
                      <button className="btn btn-ghost btn-sm" onClick={() => act(l.id, 'deactivate')}>⏸</button>
                    )}
                    {l.status === 'Inactive' && (
                      <button className="btn btn-ghost btn-sm" onClick={() => act(l.id, 'approve')}>▶</button>
                    )}
                    <button className="btn btn-danger btn-sm" onClick={() => setToDelete(l.id)}>🗑</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <ConfirmModal open={toDelete !== null} text={t('admin.confirmDelete')} onConfirm={remove} onClose={() => setToDelete(null)} />
    </>
  )
}

// ---------------- Categories ----------------
export function AdminCategories() {
  const { t } = useI18n()
  const toast = useToast()
  const [cats, setCats] = useState<Category[] | null>(null)
  const [editing, setEditing] = useState<{ id?: number; name: string; file?: File | null } | null>(null)
  const [toDelete, setToDelete] = useState<number | null>(null)

  const load = () => api<Category[]>('/categories').then(setCats).catch(() => setCats([]))
  useEffect(() => { load() }, [])

  if (cats === null) return <Spinner />

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    try {
      const form = new FormData()
      form.append('name', editing.name)
      if (editing.file) form.append('picture', editing.file)
      await api(editing.id ? `/admin/categories/${editing.id}` : '/admin/categories', {
        method: editing.id ? 'PUT' : 'POST',
        form,
      })
      setEditing(null); toast('✓'); load()
    } catch (err: any) { toast(err.message ?? t('common.error'), 'error') }
  }

  const remove = async () => {
    if (toDelete === null) return
    try { await api(`/admin/categories/${toDelete}`, { method: 'DELETE' }); toast('🗑 ✓'); load() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  return (
    <>
      <div className="between" style={{ marginBottom: 18 }}>
        <h1 style={{ fontSize: '1.4rem' }}>🗂 {t('admin.categories')}</h1>
        <button className="btn btn-accent btn-sm" onClick={() => setEditing({ name: '', file: null })}>＋ {t('admin.addCategory')}</button>
      </div>

      <div className="grid cat-grid">
        {cats.map(c => (
          <div key={c.id} className="cat-card listing-card glass">
            {c.picture && <img src={img(c.picture)} alt="" loading="lazy" />}
            <div className="card-body between">
              <strong>{c.name}</strong>
              <div className="row" style={{ gap: 6 }}>
                <button className="btn btn-ghost btn-sm" onClick={() => setEditing({ id: c.id, name: c.name })}>✏️</button>
                <button className="btn btn-danger btn-sm" onClick={() => setToDelete(c.id)}>🗑</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <Modal open={editing !== null} title={editing?.id ? `✏️ ${t('admin.editCategory')}` : `＋ ${t('admin.addCategory')}`} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form-grid" onSubmit={save}>
            <div className="field">
              <label>{t('auth.name')}</label>
              <input className="input" value={editing.name} onChange={e => setEditing({ ...editing, name: e.target.value })} required />
            </div>
            <div className="field">
              <label>{t('listings.images')} (1)</label>
              <input className="input" type="file" accept="image/jpeg,image/png,image/gif,image/webp"
                onChange={e => setEditing({ ...editing, file: e.target.files?.[0] ?? null })} />
            </div>
            <button className="btn btn-accent">{t('common.save')}</button>
          </form>
        )}
      </Modal>

      <ConfirmModal open={toDelete !== null} text={t('admin.confirmDelete')} onConfirm={remove} onClose={() => setToDelete(null)} />
    </>
  )
}

// ---------------- Requests (Listing approvals + Rental requests) ----------------
export function AdminRequests() {
  const { t } = useI18n()
  const toast = useToast()
  const [pending, setPending] = useState<ListingSummary[] | null>(null)
  const [requests, setRequests] = useState<RentalRequest[] | null>(null)
  const [tab, setTab] = useState<'listings' | 'rentals'>('listings')

  const loadPending = () => api<ListingSummary[]>('/admin/listings').then(data => setPending(data.filter(l => l.status === 'Pending'))).catch(() => setPending([]))
  const loadRequests = () => api<RentalRequest[]>('/admin/requests').then(setRequests).catch(() => setRequests([]))

  useEffect(() => { loadPending(); loadRequests() }, [])

  const approve = async (id: number) => {
    try { await api(`/admin/listings/${id}/approve`, { method: 'POST' }); toast('✓'); loadPending() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }
  const reject = async (id: number) => {
    try { await api(`/admin/listings/${id}/deactivate`, { method: 'POST' }); toast('✓'); loadPending() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }
  const deleteRequest = async (id: number) => {
    try { await api(`/admin/requests/${id}`, { method: 'DELETE' }); toast('✓'); loadRequests() }
    catch (e: any) { toast(e.message ?? t('common.error'), 'error') }
  }

  const pendingCount = pending?.length ?? 0
  const rentalCount = requests?.length ?? 0

  return (
    <>
      <h1 style={{ fontSize: '1.4rem', marginBottom: 18 }}>{t('admin.requests')}</h1>

      <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
        <button className={`btn btn-sm ${tab === 'listings' ? 'btn-accent' : 'btn-ghost'}`} onClick={() => setTab('listings')}>
          {t('admin.pendingListings')} {pendingCount > 0 && <span className="badge badge-warn" style={{ marginLeft: 6 }}>{pendingCount}</span>}
        </button>
        <button className={`btn btn-sm ${tab === 'rentals' ? 'btn-accent' : 'btn-ghost'}`} onClick={() => setTab('rentals')}>
          {t('admin.rentalRequests')} {rentalCount > 0 && <span className="badge badge-ok" style={{ marginLeft: 6 }}>{rentalCount}</span>}
        </button>
      </div>

      {tab === 'listings' && (
        pending === null ? <Spinner /> : pending.length === 0 ? (
          <Empty icon="✓" text={t('admin.noPending')} />
        ) : (
          <div className="form-grid">
            {pending.map(l => (
              <div key={l.id} className="request-row glass">
                <img
                  src={img(l.mainImage)}
                  alt=""
                  loading="lazy"
                  style={{ width: 90, height: 70, objectFit: 'cover', borderRadius: 8 }}
                />
                <div style={{ flex: 1, minWidth: 200 }}>
                  <strong>{l.title}</strong>
                  <div className="faint" style={{ marginTop: 2 }}>
                    {l.categoryName} · {l.locationAddress}
                  </div>
                  <div style={{ marginTop: 4, fontWeight: 700, fontSize: '0.9rem' }} dir="ltr">
                    {l.costPerDay.toFixed(2)} JOD/{t(`browse.unit${l.rentalUnit?.charAt(0).toUpperCase() + l.rentalUnit?.slice(1)}` as any)}
                  </div>
                </div>
                <div className="row" style={{ gap: 6, flexShrink: 0 }}>
                  <button className="btn btn-ok btn-sm" onClick={() => approve(l.id)}>
                    ✓ {t('admin.approve')}
                  </button>
                  <button className="btn btn-danger btn-sm" onClick={() => reject(l.id)}>
                    ✕ {t('admin.reject')}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )
      )}

      {tab === 'rentals' && (
        requests === null ? <Spinner /> : requests.length === 0 ? (
          <Empty icon="🧾" text={t('requests.none')} />
        ) : (
          <div className="form-grid">
            {requests.map(r => (
              <div key={r.id} className="request-row glass">
                <img src={img(r.listingImage)} alt="" loading="lazy" />
                <div style={{ flex: 1, minWidth: 200 }}>
                  <strong>{r.listingTitle}</strong>
                  <div className="faint">
                    {r.renter.name} · <span dir="ltr">{r.renter.phoneNumber}</span>
                  </div>
                  <div className="faint" dir="ltr">
                    {r.fromDate} → {r.toDate} · {r.totalCost.toFixed(2)} JOD
                  </div>
                </div>
                <span className={`badge ${statusBadge(r.status)}`}>{t(`status.${r.status}` as any)}</span>
                <button className="btn btn-danger btn-sm" onClick={() => deleteRequest(r.id)}>🗑</button>
              </div>
            ))}
          </div>
        )
      )}
    </>
  )
}
