import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="author-type"
export default class extends Controller {
  static targets = [
    "select",
    "personFields",
    "collectiveFields",
    "title",
    "firstName",
    "lastName",
    "collectiveName"
  ]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.selectTarget.value
    const isPerson = type === "person"
    const isCollective = type === "collective"

    this.personFieldsTarget.classList.toggle("d-none", !isPerson)
    this.collectiveFieldsTarget.classList.toggle("d-none", !isCollective)

    if (this.hasTitleTarget) {
      if (!isPerson) this.titleTarget.value = ""
    }

    if (this.hasFirstNameTarget) {
      this.firstNameTarget.required = isPerson
      if (!isPerson) this.firstNameTarget.value = ""
    }

    if (this.hasLastNameTarget) {
      this.lastNameTarget.required = isPerson
      if (!isPerson) this.lastNameTarget.value = ""
    }

    if (this.hasCollectiveNameTarget) {
      this.collectiveNameTarget.required = isCollective
      if (!isCollective) this.collectiveNameTarget.value = ""
    }
  }
}