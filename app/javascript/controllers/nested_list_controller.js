import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-list"
export default class extends Controller {
  connect() {
    const $container = $(this.element)
    
    const $list = $container.find('#items-list')
    const $addLink = $container.find('#add-item-link')

    $container.off('cocoon:after-insert')
    $container.off('cocoon:after-remove')

    $container.on('cocoon:after-insert', () => {
      $list?.hide()
      $addLink?.hide()
    })

    $container.on('cocoon:after-remove', () => {
      $list?.show()
      $addLink?.show()
    })

    if ($container.find('.nested-fields').length > 0) {
      $list?.hide()
      $addLink?.hide()
    }
  }
}
