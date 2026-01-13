import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="association-editor"
export default class extends Controller {
  static values = {
    items: Array,
    simpleFields: Array,
    dateFields: Array,
  }

  connect() {
    this.$container = $(this.element)
    this.$list      = this.$container.find('.items-list')
    this.$edit      = this.$container.find('.edit-fields')
    this.$addLink   = this.$container.find('.add-item-link')
    this.$select    = this.$list.find('select')

    if (!this.$edit.length || !this.$select.length) return

    this.initialId = this.$select.val() || null
    this.$destroyToggle = this.$edit.find('.association-destroy-toggle')

    this.$inputs       = this.$edit.find(':input').not('[name*="[_destroy]"]').not('.id-field').not('.association-destroy-toggle')
    this.$destroyField = this.$edit.find('input[name*="[_destroy]"]')

    const hasId = !!this.$edit.find('input[name*="[id]"]').val()

    if (hasId) {
      this.$edit.show()
      this.$inputs.prop('disabled', false)
    } else {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
    }

    this.$select
      .off('change.associationEditor')
      .on('change.associationEditor', () => this.handleSelectChange())
    
    this.handleSelectChange()

    this.$container.off('cocoon:after-insert.associationEditor cocoon:after-remove.associationEditor')

    this.$container.on('cocoon:after-insert.associationEditor', () => this.disableEditing())
    this.$container.on('cocoon:after-remove.associationEditor', () => this.enableEditingAfterRemove())
  }

  disconnect() {
    if (this.$select) {
      this.$select.off('.associationEditor')
    }
    if (this.$container) {
      this.$container.off('.associationEditor')
    }
  }

  toggleDestroy(event) {
    event.preventDefault()

    if (!this.$edit.length || !this.$destroyField.length) return

    const $btn    = $(event.currentTarget)
    const isMarked = this.$destroyField.val() === '1'

    if (isMarked) {
      // CANCEL
      this.$destroyField.val('0')

      this.$inputs.prop('disabled', false)
      if (this.$select && this.$select.length) {
        this.$select.prop('disabled', false)
      }
      if (this.$addLink && this.$addLink.length) {
        this.$addLink.find('a,button')
          .removeClass('disabled')
          .prop('disabled', false)
      }

      $btn
        .removeClass('btn-secondary')
        .addClass('btn-danger')
        .text('Delete')
    } else {
      // DELETE
      this.$destroyField.val('1')

      this.$inputs.prop('disabled', true)
      if (this.$select && this.$select.length) {
        this.$select.prop('disabled', true)
      }
      if (this.$addLink && this.$addLink.length) {
        this.$addLink.find('a,button')
          .addClass('disabled')
          .prop('disabled', true)
      }

      $btn
        .removeClass('btn-danger')
        .addClass('btn-secondary')
        .text('Cancel')
    }
  }

  handleSelectChange() {
    if (!this.hasItemsValue || !this.$select.length || !this.$edit.length) return

    const val = this.$select.val()

    if (!val) {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
      this.resetDestroyState()
      this.updateDestroyVisibility(null)
      return
    }

    const id   = parseInt(val, 10)
    const item = this.itemsValue.find((i) => i.id === id)

    if (!item) {
      this.$edit.hide()
      this.$inputs.prop('disabled', true)
      this.resetDestroyState()
      this.updateDestroyVisibility(null)
      return
    }

    this.$edit.show()
    this.$inputs.prop('disabled', false)

    this.$edit.find('input[name*="[id]"]').val(item.id)

    if (this.hasSimpleFieldsValue) {
      this.simpleFieldsValue.forEach((attr) => {
        this.setSimpleField(attr, item[attr])
      })
    }

    if (this.hasDateFieldsValue) {
      this.dateFieldsValue.forEach((attr) => {
        this.setDateSelect(attr, item[attr])
      })
    }

    this.resetDestroyState()
    this.updateDestroyVisibility(item.id)
  }

  resetDestroyState() {
    if (this.$destroyField && this.$destroyField.length) {
      this.$destroyField.val('0')
    }
    if (this.$destroyToggle && this.$destroyToggle.length) {
      this.$destroyToggle
        .removeClass('btn-secondary')
        .addClass('btn-danger')
        .text('Delete')
    }
  }

  updateDestroyVisibility(currentId) {
    if (!this.$destroyToggle || !this.$destroyToggle.length) return

    if (!this.initialId) {
      this.$destroyToggle.addClass('d-none')
      return
    }

    if (currentId && String(currentId) === String(this.initialId)) {
      this.$destroyToggle.removeClass('d-none')
    } else {
      this.$destroyToggle.addClass('d-none')
    }
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
