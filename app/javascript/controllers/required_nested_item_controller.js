import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="required-nested-item"
export default class extends Controller {
  connect() {
    const $container = $(this.element)

    const $nestedFields = $container.find('.nested-fields:visible')

    $container.off('cocoon:after-insert')
    $container.off('cocoon:after-remove')

    $container.on('cocoon:after-insert', () => {
      let $newNestedFields = $container.find('.nested-fields:visible')
      if ($newNestedFields.length > 1) {
        for (let i = 0; i < $newNestedFields.length; i++) {
          const $nestedField = $newNestedFields.eq(i)
          const $removeLink = $nestedField.find('.remove_fields')
          $removeLink.show()
        }
        const $lastNestedField = $newNestedFields.last()
        const $primaryCheckbox = $lastNestedField.find('.primary-checkbox')
        const $primaryField = $lastNestedField.find('.primary-field')
        $primaryCheckbox.prop('checked', false)
        $primaryField.val(false)
      }
    })

    $container.on('cocoon:after-remove', () => {
      let $newNestedFields = $container.find('.nested-fields:visible')
      if ($newNestedFields.length === 1) {
        const $nestedField = $newNestedFields.first()
        const $removeLink = $nestedField.find('.remove_fields')
        $removeLink.hide()
      }
      const $firstNestedField = $newNestedFields.first()
      const $primaryCheckbox = $firstNestedField.find('.primary-checkbox')
      const $primaryField = $firstNestedField.find('.primary-field')

      $primaryCheckbox.prop('checked', true)
      $primaryField.val(true)
    })

    if ($nestedFields.length === 1) {
      const $nestedField = $nestedFields.first()
      const $removeLink = $nestedField.find('.remove_fields')
      const $primaryCheckbox = $nestedField.find('.primary-checkbox')
      const $primaryField = $nestedField.find('.primary-field')

      $removeLink.hide()
      $primaryCheckbox.prop('checked', true)
      $primaryField.val(true)
    }
  }
}
