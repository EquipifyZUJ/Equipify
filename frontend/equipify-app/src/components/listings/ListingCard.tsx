import { Link } from 'react-router-dom'
import { useI18n } from '../../i18n'
import type { ListingSummary } from '../../api/types'
import { Stars } from '../ui'
import { img } from '../../api/client'

export function ListingCard({ listing, rating }: { listing: ListingSummary; rating?: number | null }) {
  const { t } = useI18n()
  return (
    <Link to={`/listings/${listing.id}`} className="listing-card" id={`listing-card-${listing.id}`}>
      <div className="card-media">
        <img src={img(listing.mainImage)} alt={listing.title} loading="lazy" />
        <button
          className="card-fav"
          onClick={e => { e.preventDefault(); e.stopPropagation() }}
          aria-label="favorite"
        >
          ♡
        </button>
        <span className="card-price">
          {listing.costPerDay} <small>{t('listing.perDay')}</small>
        </span>
      </div>
      <div className="card-body">
        <div className="card-title">{listing.title}</div>
        <div className="card-sub">
          <span>📍 {listing.locationAddress}</span>
          {rating != null && <Stars value={Math.round(rating)} />}
        </div>
      </div>
    </Link>
  )
}
