import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-search"
export default class extends Controller {
  connect() {
    const $container = $(this.element) 
    const $searchField = $container.find('.search-field')
    const $button = $container.find('button');

    $button.on('click', () => {
      $searchField.prop('disabled', !$searchField.prop('disabled'));
    });
  }
}
