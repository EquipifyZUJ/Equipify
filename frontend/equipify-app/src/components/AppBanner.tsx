import { useState, useEffect } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useI18n } from '../i18n'
import { useTheme } from '../theme/ThemeProvider'

export function AppBanner() {
  const { t } = useI18n()
  const { theme } = useTheme()
  const location = useLocation()
  const [dismissed, setDismissed] = useState(() => sessionStorage.getItem('app-banner-dismissed') === '1')
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const mq = window.matchMedia('(max-width: 768px)')
    setIsMobile(mq.matches)
    const handler = (e: MediaQueryListEvent) => setIsMobile(e.matches)
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [])

  useEffect(() => { setDismissed(false) }, [location.pathname])

  if (dismissed || !isMobile) return null

  return (
    <div className="app-banner">
      <div className="app-banner-inner">
        <div className="app-banner-icon">
          <img
            src={theme === 'dark' ? '/src/assets/logo_dark.png' : '/src/assets/logo_light.png'}
            alt="Equipify"
          />
        </div>
        <div className="app-banner-text">
          <div className="app-banner-title">{t('banner.title')}</div>
          <div className="app-banner-sub">{t('banner.sub')}</div>
        </div>
        <Link to="/download" className="app-banner-btn">
          {t('banner.cta')}
        </Link>
        <button
          className="app-banner-close"
          aria-label={t('common.close')}
          onClick={() => { setDismissed(true); sessionStorage.setItem('app-banner-dismissed', '1') }}
        >
          ✕
        </button>
      </div>
    </div>
  )
}
