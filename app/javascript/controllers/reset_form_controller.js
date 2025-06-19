import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  reset(event) {
    // Only clear on successful 2xx response
    if (!event.detail.success) return

    // Empty & refocus the textarea
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}
