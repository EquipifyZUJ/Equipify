import { useI18n } from '../i18n'
import { useTheme } from '../theme/ThemeProvider'
import { useAuth } from '../auth/AuthContext'
import logoDark from '../assets/logo_dark.png'
import logoLight from '../assets/logo_light.png'

const APK_URL = 'https://github.com/EquipifyZUJ/Equipify/releases/download/v1.4.0/app-release.apk'

const APP_STORE_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>`

const PLAY_STORE_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.61 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/></svg>`

const DOWNLOAD_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`

export default function Download() {
  const { t } = useI18n()
  const { theme } = useTheme()
  const { user, isAdmin } = useAuth()

  return (
    <div className="download-page">
      {/* Hero */}
      <section className="dl-hero">
        <div className="dl-hero-bg" aria-hidden />
        <div className="dl-hero-content">
          <div className="dl-app-icon">
            <img
              src={theme === 'dark' ? logoDark : logoLight}
              alt="Equipify"
              className="dl-icon-img"
            />
          </div>
          <h1 className="dl-title">Equipify</h1>
          <p className="dl-subtitle">{t('download.heroSub')}</p>
          <div className="dl-store-badges">
            <a
              href={APK_URL}
              download
              className="dl-badge dl-badge-android"
            >
              <span className="dl-badge-icon" dangerouslySetInnerHTML={{ __html: DOWNLOAD_SVG }} />
              <span className="dl-badge-text">
                <span className="dl-badge-label">{t('download.badgeAndroidLabel')}</span>
                <span className="dl-badge-store">{t('download.badgeAndroidStore')}</span>
              </span>
            </a>
            <div className="dl-badge dl-badge-gplay dl-badge-disabled">
              <span className="dl-badge-icon" dangerouslySetInnerHTML={{ __html: PLAY_STORE_SVG }} />
              <span className="dl-badge-text">
                <span className="dl-badge-label">{t('download.badgeGplayLabel')}</span>
                <span className="dl-badge-store">Google Play</span>
              </span>
              <span className="dl-coming-soon">{t('download.comingSoon')}</span>
            </div>
            <div className="dl-badge dl-badge-ios dl-badge-disabled">
              <span className="dl-badge-icon" dangerouslySetInnerHTML={{ __html: APP_STORE_SVG }} />
              <span className="dl-badge-text">
                <span className="dl-badge-label">{t('download.badgeIosLabel')}</span>
                <span className="dl-badge-store">{t('download.badgeIosStore')}</span>
              </span>
              <span className="dl-coming-soon">{t('download.comingSoon')}</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="dl-features container">
        <h2 className="dl-section-title">{t('download.featuresTitle')}</h2>
        <div className="dl-features-grid">
          <div className="dl-feature glass">
            <div className="dl-feature-icon">⚡</div>
            <h3>{t('download.f1Title')}</h3>
            <p>{t('download.f1Desc')}</p>
          </div>
          <div className="dl-feature glass">
            <div className="dl-feature-icon">🔒</div>
            <h3>{t('download.f2Title')}</h3>
            <p>{t('download.f2Desc')}</p>
          </div>
          <div className="dl-feature glass">
            <div className="dl-feature-icon">📍</div>
            <h3>{t('download.f3Title')}</h3>
            <p>{t('download.f3Desc')}</p>
          </div>
          <div className="dl-feature glass">
            <div className="dl-feature-icon">💬</div>
            <h3>{t('download.f4Title')}</h3>
            <p>{t('download.f4Desc')}</p>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="dl-cta container">
        <div className="dl-cta-card glass-strong">
          <h2>{t('download.ctaTitle')}</h2>
          <p className="muted">{t('download.ctaSub')}</p>
          <div className="dl-cta-buttons">
            <a href={APK_URL} download className="btn btn-accent btn-lg">
              {t('download.ctaDownload')}
            </a>
            {!user && !isAdmin && (
              <a href="/register" className="btn btn-ghost btn-lg">
                {t('download.ctaRegister')}
              </a>
            )}
          </div>
        </div>
      </section>
    </div>
  )
}
