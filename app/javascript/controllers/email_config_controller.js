import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-config"
export default class extends Controller {
  toggle(event) {
    const mailgunSettings = document.getElementById("mailgunSettings")
    const emailDisabledWarning = document.getElementById("emailDisabledWarning")

    if (event.target.checked) {
      mailgunSettings.classList.remove("d-none")
      emailDisabledWarning.classList.add("d-none")
    } else {
      mailgunSettings.classList.add("d-none")
      emailDisabledWarning.classList.remove("d-none")
    }
  }
}
