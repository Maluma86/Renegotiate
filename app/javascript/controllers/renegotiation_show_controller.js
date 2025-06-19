import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("🔌 renegotiations_controller connected")
    this.updateCalculatedRange()
    this.updateArrowButtonStates()
  }
  static targets = [ "acceptBtn", "modal", "closeModal" ]

  connect() {
    this.acceptBtnTarget?.addEventListener("click", () => this.accept())
    this.closeModalTarget?.addEventListener("click", () => this.hideModal())
    this.modalTarget?.addEventListener("click", e => {
      if (e.target === this.modalTarget) this.hideModal()
    })
  }

  accept() {
    this.acceptBtnTarget.disabled = true
    fetch(this.acceptBtnTarget.dataset.acceptUrl, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
        "Accept": "application/json"
      }
    })
      .then(r => r.json())
      .then(data => {
        if (data.success || data.error === "Already confirmed") {
          this.acceptBtnTarget.textContent = "Renegotiation Accepted"
          this.showModal()
        } else {
          this.acceptBtnTarget.disabled = false
          alert(data.error || "Error confirming renegotiation.")
        }
      })
      .catch(() => {
        this.acceptBtnTarget.disabled = false
        alert("Network error.")
      })
  }

  showModal() {
    this.modalTarget.style.display = "flex"
  }

  hideModal() {
    this.modalTarget.style.display = "none"
  }
}
