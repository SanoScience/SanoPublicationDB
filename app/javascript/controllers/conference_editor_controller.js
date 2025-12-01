import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conference-editor"
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

    this.$select.off('change.conferenceEditor')
                .on('change.conferenceEditor', () => this.handleSelectChange())

    this.handleSelectChange()

    this.$container.off('cocoon:after-insert.conferenceEditor cocoon:after-remove.conferenceEditor')

    this.$container.on('cocoon:after-insert.conferenceEditor', () => this.disableEditing())
    this.$container.on('cocoon:after-remove.conferenceEditor', () => this.enableEditingAfterRemove())
  }

  disconnect() {
    if (this.$select) {
      this.$select.off('.conferenceEditor')
    }
    if (this.$container) {
      this.$container.off('.conferenceEditor')
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
    const conf = this.itemsValue.find((c) => c.id === id)

    if (!conf) {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
      return
    }

    this.$edit.show()
    this.$inputs.prop('disabled', false)

    this.$edit.find('input[name*="[id]"]').val(conf.id)

    this.setSimpleField('name', conf.name)
    this.setSimpleField('core', conf.core)
    this.setDateSelect('start_date', conf.start_date)
    this.setDateSelect('end_date', conf.end_date)
  }

  setSimpleField(attribute, value) {
    const $input = this.$edit.find(`[name*="[${attribute}]"]`)
    if ($input.length) {
      $input.val(value != null ? value : '')
    }
  }

  setDateSelect(attribute, value) {
    const $year  = this.$edit.find(`select[name*="[${attribute}(1i)]"]`)
    const $month = this.$edit.find(`select[name*="[${attribute}(2i)]"]`)
    const $day   = this.$edit.find(`select[name*="[${attribute}(3i)]"]`)

    if (!$year.length || !$month.length || !$day.length) return

    if (!value) {
      $year.val('')
      $month.val('')
      $day.val('')
      return
    }

    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return

    $year.val(date.getFullYear().toString())
    $month.val((date.getMonth() + 1).toString())
    $day.val(date.getDate().toString())
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
