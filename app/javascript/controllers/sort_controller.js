import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sort"
export default class extends Controller {
  submit(event) {
    const sortValue = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set("sort", sortValue)
    window.location = url.toString()
  }
}
