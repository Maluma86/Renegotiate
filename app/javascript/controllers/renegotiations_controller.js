// app/javascript/controllers/renegotiations_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="renegotiations"
export default class extends Controller {
  static targets = [
    "currentPrice", "targetDiscount", "minDiscount", "calculatedRange",
    "arrowBtn", "discountTargetsForm", "saveTargetsBtn", "newTargetsBtn",
    "loadingMessage", "successMessage", "errorMessage"
  ]

  connect() {
    console.log("🔌 renegotiations_controller connected")
    this.updateCalculatedRange()
    this.updateArrowButtonStates()
  }

  get currentPrice() {
    const text = this.currentPriceTarget.textContent.trim()
    const numeric = text.replace(/[€$,]/g, "")
    return parseFloat(numeric) || 0
  }

  calculateDiscountedPrice(originalPrice, discountPercentage) {
    if (!discountPercentage || discountPercentage < 0) return originalPrice
    const amount = originalPrice * (discountPercentage / 100)
    return originalPrice - amount
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat("en-EU", {
      style: "currency", currency: "EUR",
      minimumFractionDigits: 2, maximumFractionDigits: 2
    }).format(amount)
  }

  updateCalculatedRange() {
    const targetPct = parseFloat(this.targetDiscountTarget.value) || 0
    const minPct    = parseFloat(this.minDiscountTarget.value)    || 0
    const targetPrice = this.calculateDiscountedPrice(this.currentPrice, targetPct)
    const minPrice    = this.calculateDiscountedPrice(this.currentPrice, minPct)
    const lower = Math.min(targetPrice, minPrice)
    const higher = Math.max(targetPrice, minPrice)

    this.calculatedRangeTarget.textContent =
      `${this.formatCurrency(lower)} - ${this.formatCurrency(higher)}`

    this.calculatedRangeTarget.classList.remove('calculation-empty')
    if (targetPct > 0 || minPct > 0) {
      this.calculatedRangeTarget.classList.add('calculation-active')
    } else {
      this.calculatedRangeTarget.classList.remove('calculation-active')
    }
  }

  validateInput(input) {
    const val = parseFloat(input.value)
    if (val < 0) input.value = 0
    if (val > 100) input.value = 100
    if (parseFloat(input.value) > 0) input.classList.add('has-value')
    else input.classList.remove('has-value')
  }

  onTargetDiscountInput() {
    this.validateInput(this.targetDiscountTarget)
    this.updateCalculatedRange()
  }

  onMinDiscountInput() {
    this.validateInput(this.minDiscountTarget)
    this.updateCalculatedRange()
  }

  onFocus(event) {
    event.target.select()
  }

  onArrowClick(event) {
    event.preventDefault()
    console.log("↕️ arrow clicked for", event.currentTarget.dataset.target)
    const btn = event.currentTarget
    const inputEl = document.getElementById(btn.dataset.target)
    const isUp = btn.classList.contains('arrow-up')
    if (inputEl && !inputEl.disabled) {
      const current = parseFloat(inputEl.value) || 0
      const step = parseFloat(inputEl.step) || 0.5
      const updated = isUp ? current + step : Math.max(0, current - step)
      inputEl.value = Math.min(100, Math.max(0, updated))
      inputEl.dispatchEvent(new Event('input', { bubbles: true }))
      inputEl.focus()
    }
    this.updateArrowButtonStates()
  }

  updateArrowButtonStates() {
    this.arrowBtnTargets.forEach(btn => {
      const inputEl = document.getElementById(btn.dataset.target)
      btn.disabled = !inputEl || inputEl.disabled
    })
  }

  onSubmit(event) {
    event.preventDefault()
    console.log("💾 Saving discount targets via Stimulus onSubmit")
    const url = this.discountTargetsFormTarget.action
    const formData = new FormData(this.discountTargetsFormTarget)
    this.showLoading()

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      body: formData
    })
      .then(res => res.json())
      .then(data => data.success ? this.handleSaveSuccess(data) : this.handleSaveError(data.error))
      .catch(() => this.handleSaveError('Network error. Please try again.'))
  }

  onNewTargets(event) {
    event.preventDefault()
    const url = this.newTargetsBtnTarget.dataset.unlockUrl
    if (!url) { alert('Unlock URL missing.'); return }
    this.showLoading()

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
      .then(res => res.json())
      .then(data => data.success ? this.unlockTargets() : this.handleSaveError('Failed to unlock targets.'))
      .catch(() => this.handleSaveError('Failed to unlock targets.'))
  }

  handleSaveSuccess(data) {
    this.hideLoading()
    this.showSuccess(data.message)
    this.lockTargets()
  }

  handleSaveError(message) {
    this.hideLoading()
    this.showError(message)
  }

  lockTargets() {
    this.targetDiscountTarget.disabled = true
    this.minDiscountTarget.disabled = true
    this.saveTargetsBtnTarget.style.display = 'none'
    this.newTargetsBtnTarget.closest('.new-targets-section').style.display = 'inline-block'
    this.updateArrowButtonStates()
  }

  unlockTargets() {
    this.targetDiscountTarget.disabled = false
    this.minDiscountTarget.disabled = false
    this.newTargetsBtnTarget.closest('.new-targets-section').style.display = 'none'
    this.saveTargetsBtnTarget.style.display = 'inline-block'
    this.updateArrowButtonStates()
    this.clearMessages()
  }

  showLoading() {
    this.clearMessages()
    this.loadingMessageTarget.style.display = 'block'
    this.saveTargetsBtnTarget.disabled = true
  }

  hideLoading() {
    this.loadingMessageTarget.style.display = 'none'
    this.saveTargetsBtnTarget.disabled = false
  }

  showSuccess(msg) {
    this.successMessageTarget.textContent = msg
    this.successMessageTarget.style.display = 'inline-block'
  }

  showError(msg) {
    this.errorMessageTarget.textContent = msg
    this.errorMessageTarget.style.display = 'block'
  }

  clearMessages() {
    [
      this.loadingMessageTarget,
      this.successMessageTarget,
      this.errorMessageTarget
    ].forEach(el => el.style.display = 'none')
  }
}
