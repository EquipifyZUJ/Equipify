import type { ReactNode } from 'react'
import { useI18n } from '../i18n'

export function Modal({ open, title, onClose, children }: {
  open: boolean
  title?: string
  onClose: () => void
  children: ReactNode
}) {
  const { t } = useI18n()
  if (!open) return null
  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal>
      <div className="modal glass-strong" onClick={e => e.stopPropagation()}>
        <div className="between" style={{ marginBottom: 12 }}>
          <h3>{title}</h3>
          <button className="btn btn-ghost btn-sm" onClick={onClose}>{t('common.close')}</button>
        </div>
        {children}
      </div>
    </div>
  )
}

export function ConfirmModal({ open, text, title, confirmLabel, onConfirm, onClose }: {
  open: boolean
  text: string
  title?: string
  confirmLabel?: string
  onConfirm: () => void
  onClose: () => void
}) {
  const { t } = useI18n()
  return (
    <Modal open={open} onClose={onClose} title={title ?? text}>
      <p style={{ margin: '4px 0 16px', color: 'var(--muted)' }}>{text}</p>
      <div className="row" style={{ justifyContent: 'flex-end', gap: 10 }}>
        <button className="btn btn-ghost" onClick={onClose}>{t('common.cancel')}</button>
        <button
          className="btn btn-danger"
          onClick={async () => {
            await onConfirm()
            onClose()
          }}
        >{confirmLabel ?? t('common.confirm')}</button>
      </div>
    </Modal>
  )
}

export function Spinner() {
  return <div className="spinner" aria-label="loading" />
}

export function Empty({ icon = '🗂️', text }: { icon?: string; text: string }) {
  return (
    <div className="empty glass">
      <div className="big">{icon}</div>
      {text}
    </div>
  )
}

export function Stars({ value, onChange }: { value: number; onChange?: (v: number) => void }) {
  return (
    <span className="stars">
      {[1, 2, 3, 4, 5].map(n =>
        onChange ? (
          <button key={n} type="button" className={`star-btn ${n <= value ? 'on' : ''}`} onClick={() => onChange(n)}>★</button>
        ) : (
          <span key={n} style={{ opacity: n <= value ? 1 : 0.25 }}>★</span>
        ),
      )}
    </span>
  )
}
