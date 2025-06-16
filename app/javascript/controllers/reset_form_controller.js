import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {console.log("connected")}

  reset() {
    console.log("fired")
    this.element.reset()
  }
}
