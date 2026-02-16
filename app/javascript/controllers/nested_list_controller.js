import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-list"
export default class extends Controller {
  connect() {
    this.$container = $(this.element)

    this.$list      = this.$container.find('.items-list')
    this.$addLink   = this.$container.find('.add-item-link')

    this.$container.off('cocoon:after-insert.nestedList cocoon:after-remove.nestedList')

    this.$container.on('cocoon:after-insert.nestedList', () => this.handleAfterInsert())
    this.$container.on('cocoon:after-remove.nestedList', () => this.handleAfterRemove())

    if (this.$container.find('.nested-fields').length > 0) {
      this.handleAfterInsert()
    }
  }

  disconnect() {
    if (this.$container) {
      this.$container.off('.nestedList')
    }
  }

  handleAfterInsert() {
    if (this.$list && this.$list.length) this.$list.hide()
    if (this.$addLink && this.$addLink.length) this.$addLink.hide()
  }

  handleAfterRemove() {
    if (this.$list && this.$list.length) this.$list.show()
    if (this.$addLink && this.$addLink.length) this.$addLink.show()
  }
}
