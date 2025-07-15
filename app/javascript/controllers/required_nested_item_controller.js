import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="required-nested-item"
export default class extends Controller {
  connect() {
    const $container = $(this.element)

    const $nestedFields = $container.find('.nested-fields')

    $container.off('cocoon:after-insert')
    $container.off('cocoon:after-remove')

    $container.on('cocoon:after-insert', () => {
      let $newNestedFields = $container.find('.nested-fields')
      if ($newNestedFields.length > 1) {
        for (let i = 0; i < $newNestedFields.length; i++) {
          const $nestedField = $newNestedFields.eq(i)
          const $removeLink = $nestedField.find('.remove_fields')
          $removeLink.show()
        }
      }
    })

    $container.on('cocoon:after-remove', () => {
      let $newNestedFields = $container.find('.nested-fields')
      if ($newNestedFields.length === 1) {
        const $nestedField = $newNestedFields.first()
        const $removeLink = $nestedField.find('.remove_fields')
        $removeLink.hide()
      }
    })

    if ($nestedFields.length === 1) {
      const $nestedField = $nestedFields.first()
      const $removeLink = $nestedField.find('.remove_fields')
      $removeLink.hide()
    }
  }
}
