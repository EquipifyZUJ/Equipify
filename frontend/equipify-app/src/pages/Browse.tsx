import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { api, img } from '../api/client'
import type { Category, ListingSummary, MapMarker, Paged } from '../api/types'
import { BrowseMap } from '../components/map/Maps'
import { ListingCard } from '../components/listings/ListingCard'
import { Empty, Spinner } from '../components/ui'
import { useI18n } from '../i18n'

const RENTAL_UNITS = ['hour', 'day', 'week', 'month', 'year'] as const

export default function Browse({ mapOnly = false }: { mapOnly?: boolean }) {
  const { t, lang } = useI18n()
  const categoryName = (c: Category) => lang === 'ar' && c.nameAr ? c.nameAr : c.name
  const unitSingular = (u: string) => t(`browse.unit${u.charAt(0).toUpperCase() + u.slice(1)}Singular` as any)
  const [params] = useSearchParams()

  const [search, setSearch] = useState(params.get('search') ?? '')
  const [categoryId, setCategoryId] = useState(params.get('categoryId') ?? '')
  const [rentalUnit, setRentalUnit] = useState('')
  const [minPrice, setMinPrice] = useState('')
  const [maxPrice, setMaxPrice] = useState('')
  const [minDuration, setMinDuration] = useState('')
  const [maxDuration, setMaxDuration] = useState('')
  const [page, setPage] = useState(1)
  const [categories, setCategories] = useState<Category[]>([])
  const [data, setData] = useState<Paged<ListingSummary> | null>(null)
  const [loading, setLoading] = useState(true)
  const [gridLoading, setGridLoading] = useState(false)
  const [mode, setMode] = useState<'grid' | 'map'>(mapOnly ? 'map' : 'grid')
  const [markers, setMarkers] = useState<MapMarker[]>([])
  const [filtersOpen, setFiltersOpen] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)
  const lastBoundsRef = useRef<{ west: number; south: number; east: number; north: number } | null>(null)
  const gridAbortRef = useRef<AbortController | null>(null)
  const mapAbortRef = useRef<AbortController | null>(null)
  const lastSearchRef = useRef(search)

  const hasActiveFilters = rentalUnit || minPrice || maxPrice || minDuration || maxDuration

  // Debounce search (400ms) — prevents storm of requests on every keystroke
  const [debouncedSearch, setDebouncedSearch] = useState(search)
  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search), 400)
    return () => clearTimeout(t)
  }, [search])

  // Keep debounced in sync when search cleared externally
  useEffect(() => { if (search === '' && debouncedSearch !== '') setDebouncedSearch('') }, [search, debouncedSearch])

  useEffect(() => {
    api<Category[]>('/categories').then(setCategories).catch(() => {})
  }, [])

  const load = useCallback(async () => {
    gridAbortRef.current?.abort()
    const ac = new AbortController()
    gridAbortRef.current = ac
    // Show appropriate spinner
    if (mode === 'grid') setGridLoading(true)
    if (!data) setLoading(true)
    const qs = new URLSearchParams()
    if (debouncedSearch) qs.set('search', debouncedSearch)
    if (categoryId) qs.set('categoryId', categoryId)
    if (rentalUnit) qs.set('rentalUnit', rentalUnit)
    if (minPrice) qs.set('minPrice', minPrice)
    if (maxPrice) qs.set('maxPrice', maxPrice)
    if (minDuration) qs.set('minDuration', minDuration)
    if (maxDuration) qs.set('maxDuration', maxDuration)
    qs.set('page', String(page))
    qs.set('pageSize', '12')

    try {
      const res = await api<Paged<ListingSummary>>(`/listings?${qs}`, { signal: ac.signal })
      if (!ac.signal.aborted) setData(res)
    } catch (e: any) {
      if (e?.name !== 'AbortError') setData(null)
    } finally {
      setLoading(false)
      setGridLoading(false)
    }
  }, [debouncedSearch, categoryId, rentalUnit, minPrice, maxPrice, minDuration, maxDuration, page, mode])

  const loadMarkers = useCallback(async (b: { west: number; south: number; east: number; north: number }) => {
    lastBoundsRef.current = b
    if (mode !== 'map') return
    mapAbortRef.current?.abort()
    const ac = new AbortController()
    mapAbortRef.current = ac
    try {
      const qs = new URLSearchParams({
        west: b.west.toFixed(4), south: b.south.toFixed(4),
        east: b.east.toFixed(4), north: b.north.toFixed(4),
      })
      if (categoryId) qs.set('categoryId', categoryId)
      if (debouncedSearch) qs.set('search', debouncedSearch)
      if (rentalUnit) qs.set('rentalUnit', rentalUnit)
      if (minPrice) qs.set('minPrice', minPrice)
      if (maxPrice) qs.set('maxPrice', maxPrice)
      if (minDuration) qs.set('minDuration', minDuration)
      if (maxDuration) qs.set('maxDuration', maxDuration)
      const res = await api<MapMarker[]>(`/listings/map?${qs}`, { signal: ac.signal })
      if (!ac.signal.aborted) setMarkers(res)
    } catch (e: any) {
      if (e?.name === 'AbortError') return
    }
  }, [mode, categoryId, debouncedSearch, rentalUnit, minPrice, maxPrice, minDuration, maxDuration])

  // Re-fetch markers when debounced search/filters change in map mode
  useEffect(() => {
    if (mode === 'map' && lastBoundsRef.current) {
      lastSearchRef.current = debouncedSearch
      loadMarkers(lastBoundsRef.current)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch, categoryId, rentalUnit, minPrice, maxPrice, minDuration, maxDuration])

  const resetFilters = () => {
    setRentalUnit('')
    setMinPrice('')
    setMaxPrice('')
    setMinDuration('')
    setMaxDuration('')
    setPage(1)
  }

  const unitKey = (u: string) => `browse.unit${u.charAt(0).toUpperCase() + u.slice(1)}` as any

  return (
    <>
      {/* Header bar */}
      <div className="between" style={{ marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.5rem', margin: 0 }}>{t('browse.title')}</h1>
        <div className="view-toggle">
          <button
            className={mode === 'grid' ? 'active' : ''}
            onClick={() => setMode('grid')}
            id="view-grid-btn"
          >
            ▦ {t('browse.grid')}
          </button>
          <button
            className={mode === 'map' ? 'active' : ''}
            onClick={() => setMode('map')}
            id="view-map-btn"
          >
            🗺 {t('browse.mapView')}
          </button>
        </div>
      </div>

      {/* Search bar + filter button */}
      <div className="browse-search-row">
        <div className="browse-search-input-wrap" onClick={() => searchRef.current?.focus()}>
          <span className="browse-search-icon">🔍</span>
          <input
            ref={searchRef}
            className="browse-search-input"
            placeholder={t('home.searchPlaceholder')}
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1) }}
            onKeyDown={e => { if (e.key === 'Enter') { setPage(1); load() } }}
            id="browse-search-input"
          />
          {search && (
            <button className="browse-search-clear" onClick={() => { setSearch(''); setPage(1) }}>✕</button>
          )}
        </div>
        <button
          className={`browse-filter-btn ${filtersOpen ? 'active' : ''}`}
          onClick={() => setFiltersOpen(!filtersOpen)}
          id="browse-filter-btn"
        >
          <span className="browse-filter-icon">⚙</span>
          <span>{t('browse.filters')}</span>
          {hasActiveFilters && <span className="browse-filter-badge" />}
        </button>
      </div>

      {/* Category chips */}
      <div className="browse-chips-row">
        <button
          className={`browse-chip ${!categoryId ? 'active' : ''}`}
          onClick={() => { setCategoryId(''); setPage(1) }}
        >
          {t('browse.allCategories')}
        </button>
        {categories.map(c => (
          <button
            key={c.id}
            className={`browse-chip ${categoryId === String(c.id) ? 'active' : ''}`}
            onClick={() => { setCategoryId(categoryId === String(c.id) ? '' : String(c.id)); setPage(1) }}
          >
            {categoryName(c)}
          </button>
        ))}
      </div>

      {/* Filter panel (collapsible) */}
      {filtersOpen && (
        <div className="browse-filter-panel glass-strong animate-fadeInUp">
          <div className="browse-filter-panel-grid">
            {/* Rental unit */}
            <div className="browse-filter-section">
              <span className="browse-filter-label">{t('browse.rentalUnit')}</span>
              <div className="browse-unit-chips">
                <button
                  className={`browse-chip unit-chip ${!rentalUnit ? 'active' : ''}`}
                  onClick={() => setRentalUnit('')}
                >
                  {t('browse.allUnits')}
                </button>
                {RENTAL_UNITS.map(u => (
                  <button
                    key={u}
                    className={`browse-chip unit-chip ${rentalUnit === u ? 'active' : ''}`}
                    onClick={() => setRentalUnit(rentalUnit === u ? '' : u)}
                  >
                    {t(unitKey(u))}
                  </button>
                ))}
              </div>
            </div>

            {/* Price range */}
            <div className="browse-filter-section">
              <span className="browse-filter-label">{t('browse.minPrice')} — {t('browse.maxPrice')}</span>
              <div className="browse-filter-range">
                <input
                  className="input browse-filter-input"
                  type="number"
                  min="0"
                  placeholder="0"
                  value={minPrice}
                  onChange={e => setMinPrice(e.target.value)}
                />
                <span className="browse-filter-sep">—</span>
                <input
                  className="input browse-filter-input"
                  type="number"
                  min="0"
                  placeholder="∞"
                  value={maxPrice}
                  onChange={e => setMaxPrice(e.target.value)}
                />
                <span className="browse-filter-unit">{t('common.jod')}</span>
              </div>
            </div>

            {/* Duration range — labels change based on selected unit */}
            {rentalUnit && (
              <div className="browse-filter-section">
                <span className="browse-filter-label">{t('browse.duration')}</span>
                <div className="browse-filter-range">
                  <input
                    className="input browse-filter-input"
                    type="number"
                    min="1"
                    placeholder={t('browse.minDuration', { unit: unitSingular(rentalUnit) })}
                    value={minDuration}
                    onChange={e => setMinDuration(e.target.value)}
                  />
                  <span className="browse-filter-sep">—</span>
                  <input
                    className="input browse-filter-input"
                    type="number"
                    min="1"
                    placeholder={t('browse.maxDuration', { unit: unitSingular(rentalUnit) })}
                    value={maxDuration}
                    onChange={e => setMaxDuration(e.target.value)}
                  />
                  <span className="browse-filter-unit">{unitSingular(rentalUnit)}</span>
                </div>
              </div>
            )}
          </div>

          <div className="browse-filter-actions">
            <button className="btn btn-ghost btn-sm" onClick={() => { resetFilters(); setFiltersOpen(false) }}>
              {t('browse.resetFilters')}
            </button>
            <button className="btn btn-accent btn-sm" onClick={() => { setPage(1); setFiltersOpen(false) }}>
              {t('browse.applyFilters')}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <Spinner />
      ) : mode === 'grid' ? (
        <>
          {gridLoading && <Spinner />}
          {!gridLoading && data && data.items.length === 0 && <Empty icon="🔎" text={t('browse.empty')} />}
          {!gridLoading && (
            <div className="grid listing-grid" style={{ marginTop: 20 }}>
              {data?.items.map(l => <ListingCard key={l.id} listing={l} />)}
            </div>
          )}
          {data && data.totalPages > 1 && (
            <div className="pager">
              <button className="page-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>‹</button>
              {Array.from({ length: Math.min(data.totalPages, 7) }, (_, i) => i + 1).map(n => (
                <button key={n} className={`page-btn ${n === page ? 'current' : ''}`} onClick={() => setPage(n)}>{n}</button>
              ))}
              <button className="page-btn" disabled={page >= data.totalPages} onClick={() => setPage(p => p + 1)}>›</button>
            </div>
          )}
        </>
      ) : (
        <div className="browse-split" style={{ marginTop: 0 }}>
          <div className="map-list">
            {markers.length === 0 && <Empty icon="🗺️" text={t('browse.empty')} />}
            {markers.map(m => (
              <Link key={m.id} to={`/listings/${m.id}`} className="map-row">
                <img src={img(m.image)} alt="" loading="lazy" />
                <div style={{ minWidth: 0, flex: 1 }}>
                  <strong style={{ display: 'block', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontSize: 'var(--fs-sm)' }}>
                    {m.title}
                  </strong>
                  <span className="faint" style={{ display: 'block', marginTop: 2 }}>📍 {m.locationAddress}</span>
                  <span style={{ fontWeight: 800, color: 'var(--accent)', fontSize: 'var(--fs-sm)', marginTop: 4, display: 'block' }}>
                    {m.costPerDay} {t('listing.perDay')}
                  </span>
                </div>
              </Link>
            ))}
          </div>
          <div className="map-pane">
            <BrowseMap markers={markers} onMove={loadMarkers} />
          </div>
        </div>
      )}
    </>
  )
}
