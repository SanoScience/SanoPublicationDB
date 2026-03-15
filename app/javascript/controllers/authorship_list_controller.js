import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="authorship-list"
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.$container = $(this.element)

    this.refreshPositions()

    this.$container.off("cocoon:after-insert.authorshipList cocoon:after-remove.authorshipList")
    this.$container.on("cocoon:after-insert.authorshipList", () => this.refreshPositions())
    this.$container.on("cocoon:after-remove.authorshipList", () => this.refreshPositions())

    requestAnimationFrame(() => this.refreshPositions())
  }

  disconnect() {
    if (this.$container) {
      this.$container.off(".authorshipList")
    }
  }

  moveLeft(event) {
    const item = event.currentTarget.closest('[data-authorship-list-target="item"]')
    if (!item) return

    const items = this.itemTargets
    const index = items.indexOf(item)
    if (index <= 0) return

    const previousItem = items[index - 1]
    previousItem.parentNode.insertBefore(item, previousItem)
    this.refreshPositions()
  }

  moveRight(event) {
    const item = event.currentTarget.closest('[data-authorship-list-target="item"]')
    if (!item) return

    const items = this.itemTargets
    const index = items.indexOf(item)
    if (index === -1 || index >= items.length - 1) return

    const nextItem = items[index + 1]
    nextItem.parentNode.insertBefore(nextItem, item)
    this.refreshPositions()
  }

  refreshPositions() {
    this.itemTargets.forEach((item, index) => {
      const input = item.querySelector('input[name*="[position]"]')
      if (input) input.value = index + 1
    })
  }
}