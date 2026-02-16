import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="open-access"
export default class extends Controller {
  connect() {
    const $container = $(this.element)

    const $categorySelect = $container.find('#publication_open_access_extension_attributes_category')
    const $goldOaFields = $container.find('#gold-oa-fields')
    
    $categorySelect.off('change')

    $categorySelect.on('change', () => {
      const category = $categorySelect.val()
      if (category === 'gold') {
        $goldOaFields.show()
      } else {
        $goldOaFields.hide()
        $goldOaFields.find('input').val('')
      }
    })
  }
}
