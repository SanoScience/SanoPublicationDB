import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="journal-issue-editor"
export default class extends Controller {
  static values = {
    items: Array,
  }
  
  connect() {
    this.$container = $(this.element)
    this.$list      = this.$container.find('.items-list')
    this.$edit      = this.$container.find('.edit-fields')
    this.$select    = this.$list.find('select')

    if (!this.$edit.length || !this.$select.length) return

    this.$inputs = this.$edit.find(':input')

    const hasId = !!this.$edit.find('input[name*="[id]"]').val()

    if (hasId) {
      this.$edit.show()
      this.$inputs.prop('disabled', false)
    } else {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
    }

    this.$select.off('change.journalIssueEditor')
                .on('change.journalIssueEditor', () => this.handleSelectChange())

    this.handleSelectChange()

    this.$container.off('cocoon:after-insert.journalIssueEditor cocoon:after-remove.journalIssueEditor')

    this.$container.on('cocoon:after-insert.journalIssueEditor', () => this.disableEditing())
    this.$container.on('cocoon:after-remove.journalIssueEditor', () => this.enableEditingAfterRemove())
  }

  disconnect() {
    if (this.$select) {
      this.$select.off('.journalIssueEditor')
    }
    if (this.$container) {
      this.$container.off('.journalIssueEditor')
    }
  }

  handleSelectChange() {
    if (!this.hasItemsValue || !this.$select.length || !this.$edit.length) return

    const val = this.$select.val()

    if (!val) {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
      return
    }

    const id   = parseInt(val, 10)
    const item = this.itemsValue.find((i) => i.id === id)

    if (!item) {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
      return
    }

    this.$edit.show()
    this.$inputs.prop('disabled', false)

    this.$edit.find('input[name*="[id]"]').val(item.id)

    this.setSimpleField('title',        item.title)
    this.setSimpleField('journal_num',  item.journal_num)
    this.setSimpleField('publisher',    item.publisher)
    this.setSimpleField('volume',       item.volume)
    this.setSimpleField('impact_factor', item.impact_factor)
  }

  setSimpleField(attribute, value) {
    const $input = this.$edit.find(`[name*="[${attribute}]"]`)
    if ($input.length) {
      $input.val(value != null ? value : '')
    }
  }

  disableEditing() {
    if (this.$select && this.$select.length) {
      this.$select.prop('disabled', true)
    }
    if (this.$edit && this.$edit.length) {
      this.$edit.hide()
      if (this.$inputs) this.$inputs.prop('disabled', true)
    }
  }

  enableEditingAfterRemove() {
    if (this.$select && this.$select.length) {
      this.$select.prop('disabled', false)
    }
    this.handleSelectChange()
  }
}
