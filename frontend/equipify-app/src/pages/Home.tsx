import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { api, img } from '../api/client'
import type { Category, ListingSummary, Paged } from '../api/types'
import { ListingCard } from '../components/listings/ListingCard'
import { useI18n } from '../i18n'

export default function Home() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const [categories, setCategories] = useState<Category[]>([])
  const [featured, setFeatured] = useState<ListingSummary[]>([])
  const [search, setSearch] = useState('')
  const [showFab, setShowFab] = useState(true)
  const lastScroll = useRef(0)

  useEffect(() => {
    api<Category[]>('/categories').then(setCategories).catch(() => {})
    api<Paged<ListingSummary>>('/listings?page=1&pageSize=8').then(p => setFeatured(p.items)).catch(() => {})
  }, [])

  useEffect(() => {
    const onScroll = () => {
      const y = window.scrollY
      setShowFab(y < lastScroll.current || y < 200)
      lastScroll.current = y
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <>
      {/* ── Hero Section ── */}
      <section className="hero">
        <h1>{t('home.heroTitle')}</h1>
        <p>{t('home.heroSub')}</p>

        {/* Search bar */}
        <form
          className="hero-search"
          onSubmit={e => {
            e.preventDefault()
            navigate(`/map?search=${encodeURIComponent(search)}`)
          }}
        >
          <input
            className="input"
            placeholder={t('home.searchPlaceholder')}
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label={t('home.searchPlaceholder')}
            id="hero-search-input"
          />
          <button className="btn btn-accent" type="submit" id="hero-search-btn">
            🔍 {t('home.cta')}
          </button>
        </form>

        {/* Two main action buttons */}
        <div className="hero-actions">
          <Link to="/map" className="action-card action-card--rent" id="action-rent">
            <div className="action-icon">🔍</div>
            <h3>{t('home.rent')}</h3>
            <p>{t('home.rentSub')}</p>
          </Link>
          <Link to="/my-listings/new" className="action-card action-card--list" id="action-list">
            <div className="action-icon">💰</div>
            <h3>{t('home.rentOut')}</h3>
            <p>{t('home.rentOutSub')}</p>
          </Link>
        </div>
      </section>

      {/* ── Category chips ── */}
      {categories.length > 0 && (
        <div className="cat-row">
          {categories.map(c => (
            <Link
              key={c.id}
              to={`/map?categoryId=${c.id}`}
              className="chip cat-chip"
              style={{ textDecoration: 'none', color: 'inherit' }}
            >
              {c.picture && <img src={img(c.picture)} alt="" loading="lazy" />}
              {c.name}
            </Link>
          ))}
        </div>
      )}

      {/* ── How it works ── */}
      <section className="how-section">
        <h2>{t('home.howTitle')}</h2>
        <div className="how-grid">
          <div className="how-card">
            <div className="how-num">1</div>
            <h3>{t('home.step1Title')}</h3>
            <p>{t('home.step1Desc')}</p>
          </div>
          <div className="how-card">
            <div className="how-num">2</div>
            <h3>{t('home.step2Title')}</h3>
            <p>{t('home.step2Desc')}</p>
          </div>
          <div className="how-card">
            <div className="how-num">3</div>
            <h3>{t('home.step3Title')}</h3>
            <p>{t('home.step3Desc')}</p>
          </div>
        </div>
      </section>

      <div className="section-divider" />

      {/* ── Featured listings ── */}
      <div className="section-head">
        <h2>{t('home.featured')}</h2>
        <Link to="/browse" className="link">{t('home.viewAll')} →</Link>
      </div>

      <div className="grid listing-grid">
        {featured.map(l => (
          <ListingCard key={l.id} listing={l} />
        ))}
      </div>

      {/* ── CTA Final ── */}
      <section className="cta-section">
        <h2>{t('home.ctaFinal')}</h2>
        <p>{t('home.ctaFinalSub')}</p>
        <Link to="/register" className="btn btn-lg">{t('nav.register')} →</Link>
      </section>

      {/* ── Floating map button ── */}
      <Link to="/map" className="explore-map-btn" id="explore-map-btn" style={{ transform: showFab ? 'translateX(-50%) translateY(0)' : 'translateX(-50%) translateY(120px)', opacity: showFab ? 1 : 0, pointerEvents: showFab ? 'auto' : 'none' }}>
        🗺️ {t('home.exploreMap')}
      </Link>
    </>
  )
}
