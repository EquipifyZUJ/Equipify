import { useEffect, useMemo } from 'react'
import { MapContainer, Marker, Popup, TileLayer, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import type { MapMarker } from '../../api/types'
import { useTheme } from '../../theme/ThemeProvider'

const TILE_LIGHT = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
const TILE_ATTR = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'

const priceIcon = (price: number | null, isDark: boolean) =>
  L.divIcon({
    className: '',
    html: `<div class="map-marker${isDark ? ' map-marker--dark' : ''}">${price !== null ? `${price} JOD` : '📍'}</div>`,
    iconSize: undefined as never,
    iconAnchor: [34, 14],
  })

function BoundsReporter({ onMove }: { onMove: (b: { west: number; south: number; east: number; north: number }) => void }) {
  const map = useMapEvents({
    moveend: () => {
      const b = map.getBounds()
      onMove({ west: b.getWest(), south: b.getSouth(), east: b.getEast(), north: b.getNorth() })
    },
  })
  useEffect(() => {
    const b = map.getBounds()
    onMove({ west: b.getWest(), south: b.getSouth(), east: b.getEast(), north: b.getNorth() })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  return null
}

export function BrowseMap({ markers, onMove }: {
  markers: MapMarker[]
  onMove: (b: { west: number; south: number; east: number; north: number }) => void
}) {
  const center = useMemo<[number, number]>(() => [31.95, 35.91], [])
  const { theme } = useTheme()
  const isDark = theme === 'dark'

  return (
    <MapContainer center={center} zoom={9} style={{ height: '100%' }} scrollWheelZoom>
      <TileLayer
        key={isDark ? 'dark' : 'light'}
        attribution={TILE_ATTR}
        url={TILE_LIGHT}
      />
      <BoundsReporter onMove={onMove} />
      {markers.map(m => (
        <Marker key={m.id} position={[m.latitude, m.longitude]} icon={priceIcon(m.costPerDay, isDark)}>
          <Popup>
            <a href={`/listings/${m.id}`}><strong>{m.title}</strong></a>
            <br />{m.locationAddress}
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  )
}

export function MiniMap({ lat, lng, title }: { lat: number; lng: number; title: string }) {
  const { theme } = useTheme()
  const isDark = theme === 'dark'

  return (
    <MapContainer center={[lat, lng]} zoom={13} style={{ height: '100%' }} scrollWheelZoom={false} dragging={false}>
      <TileLayer
        key={isDark ? 'dark' : 'light'}
        attribution={TILE_ATTR}
        url={TILE_LIGHT}
      />
      <Marker position={[lat, lng]} icon={priceIcon(null, isDark)}>
        <Popup>{title}</Popup>
      </Marker>
    </MapContainer>
  )
}
