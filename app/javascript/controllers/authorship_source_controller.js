import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="authorship-source"
export default class extends Controller {
  static targets = ["mode", "existingBlock", "newBlock"]

  connect() {
    this.toggle()
  }

  toggle() {
    const mode = this.modeTarget.value
    const existing = mode === "existing"

    this.existingBlockTarget.classList.toggle("d-none", !existing)
    this.newBlockTarget.classList.toggle("d-none", existing)

    const authorSelect = this.existingBlockTarget.querySelector("select")
    if (authorSelect) {
      authorSelect.required = existing
      authorSelect.disabled = !existing
      if (!existing) authorSelect.value = ""
    }

    const newAuthorInputs = this.newBlockTarget.querySelectorAll("input, select, textarea")

    newAuthorInputs.forEach((input) => {
      if (!input.name.includes("[author_attributes]")) return
      input.disabled = existing
    })

    if (!existing) {
      const authorTypeSelect = this.newBlockTarget.querySelector('select[name*="[author_attributes][author_type]"]')

      if (authorTypeSelect && !authorTypeSelect.value) {
        authorTypeSelect.value = "person"
        authorTypeSelect.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }
}
