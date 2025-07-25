import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="select2"
export default class extends Controller {
  connect() {
    const $select = $(this.element)
    $select.select2()
  }
}
