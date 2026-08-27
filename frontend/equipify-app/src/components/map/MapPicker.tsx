import { useEffect, useRef, useState } from 'react'
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const pinIcon = L.divIcon({
  className: '',
  html: `<div style="font-size:30px;transform:translateY(-4px);filter:drop-shadow(0 4px 8px rgba(0,0,0,.3))">📍</div>`,
  iconSize: undefined as never,
  iconAnchor: [15, 32],
})

function ClickCapture({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({ click: e => onPick(e.latlng.lat, e.latlng.lng) })
  return null
}

function Flyer({ pos }: { pos: [number, number] }) {
  const map = useMap()
  const last = useRef('')
  useEffect(() => {
    if (`${pos[0]},${pos[1]}` !== last.current) {
      last.current = `${pos[0]},${pos[1]}`
      map.flyTo(pos, Math.max(map.getZoom(), 12), { duration: 0.6 })
    }
  }, [pos, map])
  return null
}

export function MapPicker({ lat, lng, onChange }: {
  lat: number | null
  lng: number | null
  onChange: (lat: number, lng: number) => void
}) {
  const [center] = useState<[number, number]>([31.95, 35.91])

  return (
    <div className="picker-map">
      <MapContainer center={lat && lng ? [lat, lng] : center} zoom={lat && lng ? 13 : 8} style={{ height: '100%' }}>
        <TileLayer attribution="&copy; OpenStreetMap" url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <ClickCapture onPick={onChange} />
        {lat !== null && lng !== null && (
          <>
            <Flyer pos={[lat, lng]} />
            <Marker
              position={[lat, lng]}
              icon={pinIcon}
              draggable
              eventHandlers={{
                dragend: e => {
                  const p = (e.target as L.Marker).getLatLng()
                  onChange(p.lat, p.lng)
                },
              }}
            />
          </>
        )}
      </MapContainer>
    </div>
  )
}
