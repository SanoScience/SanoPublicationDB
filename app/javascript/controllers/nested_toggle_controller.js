import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-toggle"
export default class extends Controller {
  connect() {
    const $container = $(this.element)

    const $toggle = $container.find('.links.max-one-association')

    $container.off('cocoon:after-insert')
    $container.off('cocoon:after-remove')

    $container.on('cocoon:after-insert', () => {
      $toggle.hide()
    })

    $container.on('cocoon:after-remove', () => {
      $toggle.show()
    })

    if ($container.find('.nested-fields').length > 0) {
      $toggle.hide()
    }
  }
}
