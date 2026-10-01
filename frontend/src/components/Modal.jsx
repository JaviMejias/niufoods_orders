import { useEffect, useId, useRef } from 'react'
import './Modal.css'

export default function Modal({ title, children, onClose }) {
  const dialogRef = useRef(null)
  const closeButtonRef = useRef(null)
  const pointerStartedOutside = useRef(false)
  const titleId = useId()

  useEffect(() => {
    const dialog = dialogRef.current
    const trigger = document.activeElement
    const previousOverflow = document.body.style.overflow

    dialog.showModal()
    closeButtonRef.current.focus({ preventScroll: true })
    document.body.style.overflow = 'hidden'

    return () => {
      dialog.close()
      document.body.style.overflow = previousOverflow
      if (trigger?.isConnected) trigger.focus({ preventScroll: true })
    }
  }, [])

  function isOutside(event) {
    if (event.target !== event.currentTarget) return false

    const bounds = event.currentTarget.getBoundingClientRect()
    return event.clientX < bounds.left || event.clientX > bounds.right ||
      event.clientY < bounds.top || event.clientY > bounds.bottom
  }

  return (
    <dialog
      className="modal"
      ref={dialogRef}
      aria-labelledby={titleId}
      onCancel={(event) => {
        event.preventDefault()
        onClose()
      }}
      onPointerDown={(event) => {
        pointerStartedOutside.current = isOutside(event)
      }}
      onPointerUp={(event) => {
        if (pointerStartedOutside.current && isOutside(event)) onClose()
        pointerStartedOutside.current = false
      }}
    >
      <header className="modal__header">
        <h2 id={titleId}>{title}</h2>
        <button
          className="modal__dismiss"
          type="button"
          ref={closeButtonRef}
          aria-label="Cerrar modal"
          onClick={onClose}
        >
          <span aria-hidden="true">×</span>
        </button>
      </header>
      <div className="modal__body">{children}</div>
      <footer className="modal__footer">
        <button className="load-more-button" type="button" onClick={onClose}>
          Cerrar
        </button>
      </footer>
    </dialog>
  )
}
