import { useCallback, useEffect, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { api, img } from '../api/client'
import type { Category, Listing } from '../api/types'
import { MapPicker } from '../components/map/MapPicker'
import { useToast } from '../components/ToastProvider'
import { useAuth } from '../auth/AuthContext'
import { useI18n } from '../i18n'

const RENTAL_UNITS = ['hour', 'day', 'week', 'month', 'year'] as const
const MAX_IMAGES = 6
const MAX_FILE_SIZE_MB = 5
const MAX_FILE_SIZE = MAX_FILE_SIZE_MB * 1024 * 1024
const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

export default function ListingForm() {
  const { id } = useParams()
  const editing = Boolean(id)
  const { t, lang } = useI18n()
  const categoryName = (c: Category) => lang === 'ar' && c.nameAr ? c.nameAr : c.name
  const unitKey = (u: string) => `browse.unit${u.charAt(0).toUpperCase() + u.slice(1)}` as any
  const unitSingular = (u: string) => t(`browse.unit${u.charAt(0).toUpperCase() + u.slice(1)}Singular` as any)
  const toast = useToast()
  const navigate = useNavigate()
  const { user } = useAuth()

  const [categories, setCategories] = useState<Category[]>([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [locationAddress, setLocationAddress] = useState('')
  const [costPerHour, setCostPerHour] = useState('')
  const [costPerDay, setCostPerDay] = useState('')
  const [costPerWeek, setCostPerWeek] = useState('')
  const [costPerMonth, setCostPerMonth] = useState('')
  const [costPerYear, setCostPerYear] = useState('')
  const [rentalUnit, setRentalUnit] = useState('day')
  const [minRentalDays, setMinRentalDays] = useState('')
  const [maxRentalDays, setMaxRentalDays] = useState('')
  const [lat, setLat] = useState<number | null>(null)
  const [lng, setLng] = useState<number | null>(null)
  const [files, setFiles] = useState<File[]>([])
  const [previews, setPreviews] = useState<string[]>([])
  const [existingImages, setExistingImages] = useState<string[]>([])
  const [busy, setBusy] = useState(false)
  const [dragging, setDragging] = useState(false)
  const [uploadError, setUploadError] = useState<string | null>(null)
  const dropRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    api<Category[]>('/categories').then(setCategories).catch(() => {})
    if (editing) {
      api<Listing>(`/listings/${id}`).then(l => {
        setTitle(l.title)
        setDescription(l.description)
        setCategoryId(String(l.categoryId))
        setLocationAddress(l.locationAddress)
        setCostPerHour(l.costPerHour ? String(l.costPerHour) : '')
        setCostPerDay(String(l.costPerDay))
        setCostPerWeek(l.costPerWeek ? String(l.costPerWeek) : '')
        setCostPerMonth(l.costPerMonth ? String(l.costPerMonth) : '')
        setCostPerYear(l.costPerYear ? String(l.costPerYear) : '')
        setMinRentalDays(l.minRentalDays ? String(l.minRentalDays) : '')
        setMaxRentalDays(l.maxRentalDays ? String(l.maxRentalDays) : '')
        setLat(l.latitude)
        setLng(l.longitude)
        setExistingImages([l.mainImage ?? '', ...l.images].filter(Boolean))
        setRentalUnit(l.rentalUnit || 'day')
      }).catch(() => navigate('/my-listings'))
    }
  }, [editing, id, navigate])

  useEffect(() => () => previews.forEach(URL.revokeObjectURL), [previews])

  const validateFiles = useCallback((raw: File[]): { valid: File[]; errors: string[] } => {
    const errors: string[] = []
    const valid: File[] = []
    const remaining = MAX_IMAGES - files.length - valid.length

    for (const f of raw) {
      if (valid.length >= remaining) break
      if (!ACCEPTED_TYPES.includes(f.type)) {
        errors.push(`"${f.name}" — invalid type`)
        continue
      }
      if (f.size > MAX_FILE_SIZE) {
        errors.push(`"${f.name}" — exceeds ${MAX_FILE_SIZE_MB} MB`)
        continue
      }
      valid.push(f)
    }
    return { valid, errors }
  }, [files.length])

  const addFiles = useCallback((raw: File[]) => {
    setUploadError(null)
    const { valid, errors } = validateFiles(raw)
    if (errors.length > 0) {
      setUploadError(errors.join(', '))
      toast(errors[0], 'error')
    }
    if (valid.length === 0) return
    const merged = [...files, ...valid].slice(0, MAX_IMAGES)
    setFiles(merged)
    setPreviews(merged.map(f => URL.createObjectURL(f)))
  }, [files, validateFiles, toast])

  const removeFile = (index: number) => {
    URL.revokeObjectURL(previews[index])
    const nextFiles = files.filter((_, i) => i !== index)
    const nextPreviews = previews.filter((_, i) => i !== index)
    setFiles(nextFiles)
    setPreviews(nextPreviews)
    setUploadError(null)
  }

  const handleDragOver = (e: React.DragEvent) => { e.preventDefault(); setDragging(true) }
  const handleDragLeave = () => setDragging(false)
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault(); setDragging(false)
    addFiles(Array.from(e.dataTransfer.files))
  }

  const useMyLocation = () => {
    navigator.geolocation?.getCurrentPosition(
      pos => { setLat(+pos.coords.latitude.toFixed(5)); setLng(+pos.coords.longitude.toFixed(5)) },
      () => toast(t('common.error'), 'error'),
    )
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return
    if (!editing && files.length === 0) {
      toast(t('listings.images'), 'error')
      return
    }
    if (lat === null || lng === null) {
      toast(t('listings.pickLocation'), 'error')
      return
    }

    setBusy(true)
    try {
      const form = new FormData()
      form.append('title', title.trim())
      form.append('description', description.trim())
      form.append('categoryId', categoryId)
      form.append('locationAddress', locationAddress.trim())
      form.append('rentalUnit', rentalUnit)
      form.append('costPerDay', costPerDay || '0')
      if (costPerHour) form.append('costPerHour', costPerHour)
      if (costPerWeek) form.append('costPerWeek', costPerWeek)
      if (costPerMonth) form.append('costPerMonth', costPerMonth)
      if (costPerYear) form.append('costPerYear', costPerYear)
      if (minRentalDays) form.append('minRentalDays', minRentalDays)
      if (maxRentalDays) form.append('maxRentalDays', maxRentalDays)
      form.append('latitude', String(lat))
      form.append('longitude', String(lng))
      files.forEach(f => form.append('images', f))

      if (editing) {
        await api(`/listings/${id}`, { method: 'PUT', form })
      } else {
        await api('/listings', { method: 'POST', form })
      }
      toast(editing ? '✓ Updated' : '✓ Created')
      navigate('/my-listings')
    } catch (err: any) {
      toast(err.message ?? t('common.error'), 'error')
    } finally {
      setBusy(false)
    }
  }

  const totalImageCount = (editing ? existingImages.length : 0) + files.length
  const canAddMore = totalImageCount < MAX_IMAGES

  return (
    <form className="form-card glass-strong animate-fadeInUp" onSubmit={submit}>
      <div className="form-header">
        <h1>{editing ? t('listings.editTitle') : t('listings.createTitle')}</h1>
        {!editing && (
          <span className="form-status-badge">
            <span className="status-dot" /> {t('status.Pending')} — {t('listings.pendingNote')}
          </span>
        )}
      </div>

      {/* ── Title ── */}
      <div className="field">
        <label>{t('listings.titleField')}</label>
        <input
          className="input"
          maxLength={200}
          placeholder={lang === 'ar' ? 'مثال: كام Canon EOS R5' : 'e.g. Canon EOS R5 Camera'}
          value={title}
          onChange={e => setTitle(e.target.value)}
          required
        />
        <span className="field-hint">{title.length}/200</span>
      </div>

      {/* ── Category ── */}
      <div className="field">
        <label>{t('listings.category')}</label>
        <select className="input" value={categoryId} onChange={e => setCategoryId(e.target.value)} required>
          <option value="">—</option>
          {categories.map(c => <option key={c.id} value={c.id}>{categoryName(c)}</option>)}
        </select>
      </div>

      {/* ── Rental Unit ── */}
      <div className="field">
        <label>{t('browse.rentalUnit')}</label>
        <div className="listing-unit-grid">
          {RENTAL_UNITS.map(u => (
            <button
              key={u}
              type="button"
              className={`listing-unit-btn ${rentalUnit === u ? 'active' : ''}`}
              onClick={() => setRentalUnit(u)}
            >
              {t(unitKey(u))}
            </button>
          ))}
        </div>
      </div>

      {/* ── Price ── */}
      <div className="field">
        <label>{t(unitKey(rentalUnit))} (JOD) *</label>
        <div className="input-with-prefix">
          <span className="input-prefix">JOD</span>
          <input
            className="input input-has-prefix"
            type="number"
            min="0.01"
            step="0.01"
            placeholder="0.00"
            value={rentalUnit === 'hour' ? costPerHour : rentalUnit === 'week' ? costPerWeek : rentalUnit === 'month' ? costPerMonth : rentalUnit === 'year' ? costPerYear : costPerDay}
            onChange={e => {
              const v = e.target.value
              if (rentalUnit === 'hour') setCostPerHour(v)
              else if (rentalUnit === 'week') setCostPerWeek(v)
              else if (rentalUnit === 'month') setCostPerMonth(v)
              else if (rentalUnit === 'year') setCostPerYear(v)
              else setCostPerDay(v)
            }}
            required
          />
        </div>
      </div>

      {/* ── Duration ── */}
      <div className="row" style={{ gap: 12 }}>
        <div className="field" style={{ flex: 1 }}>
          <label>{t('browse.minDuration', { unit: unitSingular(rentalUnit) })}</label>
          <input className="input" type="number" min="1" value={minRentalDays} onChange={e => setMinRentalDays(e.target.value)} />
        </div>
        <div className="field" style={{ flex: 1 }}>
          <label>{t('browse.maxDuration', { unit: unitSingular(rentalUnit) })}</label>
          <input className="input" type="number" min="1" value={maxRentalDays} onChange={e => setMaxRentalDays(e.target.value)} />
        </div>
      </div>

      {/* ── Address ── */}
      <div className="field">
        <label>{t('listings.address')}</label>
        <input
          className="input"
          maxLength={200}
          placeholder={lang === 'ar' ? 'مثال: عمّان، الحميدية' : 'e.g. Amman, Al-Hamidia'}
          value={locationAddress}
          onChange={e => setLocationAddress(e.target.value)}
          required
        />
      </div>

      {/* ── Description ── */}
      <div className="field">
        <label>{t('listing.description')}</label>
        <textarea
          className="input"
          rows={4}
          placeholder={lang === 'ar' ? 'اكتب وصفاً تفصيلياً...' : 'Describe your item in detail...'}
          value={description}
          onChange={e => setDescription(e.target.value)}
        />
      </div>

      {/* ── Map ── */}
      <div className="field">
        <div className="between">
          <label>{t('listings.pickLocation')}</label>
          <button type="button" className="btn btn-ghost btn-sm" onClick={useMyLocation}>🎯 {t('listings.useMyLocation')}</button>
        </div>
        <MapPicker
          lat={lat}
          lng={lng}
          onChange={(a, b) => { setLat(+a.toFixed(5)); setLng(+b.toFixed(5)) }}
        />
        {(lat !== null && lng !== null) && (
          <span className="faint" style={{ direction: 'ltr', textAlign: 'center', fontSize: '0.72rem' }}>
            lat: {lat}, lng: {lng}
          </span>
        )}
      </div>

      {/* ── Image Upload ── */}
      <div className="field">
        <label className="field-label-row">
          <span>{t('listings.images')}</span>
          <span className="img-counter">{files.length + (editing ? existingImages.length : 0)}/{MAX_IMAGES}</span>
        </label>

        {canAddMore && (
          <div
            ref={dropRef}
            className={`drop-zone ${dragging ? 'drop-zone-active' : ''}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={() => {
              const inp = document.createElement('input')
              inp.type = 'file'
              inp.accept = ACCEPTED_TYPES.join(',')
              inp.multiple = true
              inp.onchange = () => inp.files && addFiles(Array.from(inp.files))
              inp.click()
            }}
          >
            <div className="drop-zone-content">
              <span className="drop-zone-icon">📸</span>
              <p className="drop-zone-text">{t('listings.dragDrop')}</p>
              <p className="drop-zone-hint">{t('listings.dragHint')}</p>
            </div>
          </div>
        )}

        {uploadError && (
          <div className="upload-error">
            <span>⚠</span> {uploadError}
          </div>
        )}

        {/* New file previews */}
        {previews.length > 0 && (
          <div className="img-grid-preview">
            {previews.map((p, i) => (
              <div key={p} className="img-preview-card">
                <img src={p} alt="" />
                {i === 0 && !editing && <span className="img-badge">{t('listings.mainImage')}</span>}
                {i === 0 && editing && <span className="img-badge">{t('listings.mainImage')}</span>}
                <span className="img-index">{i + 1}</span>
                <button type="button" className="img-remove" onClick={(e) => { e.stopPropagation(); removeFile(i) }}>✕</button>
              </div>
            ))}
          </div>
        )}

        {/* Existing images (edit mode) */}
        {previews.length === 0 && existingImages.length > 0 && (
          <div className="img-grid-preview">
            {existingImages.map((p, i) => (
              <div key={p} className="img-preview-card">
                <img src={img(p.startsWith('/') ? p : `/uploads/listings/${p}`)} alt="" />
                {i === 0 && <span className="img-badge">{t('listings.mainImage')}</span>}
                <span className="img-index">{i + 1}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Actions ── */}
      <div className="form-actions">
        <button className="btn btn-accent btn-lg" type="submit" disabled={busy}>
          {busy ? (
            <span className="btn-loading">
              <span className="spinner" /> {t('common.loading')}
            </span>
          ) : (
            <>✓ {editing ? t('listings.updateListing') : t('listings.submitListing')}</>
          )}
        </button>
        <button className="btn btn-ghost" type="button" onClick={() => navigate(-1)}>{t('common.cancel')}</button>
      </div>
    </form>
  )
}
