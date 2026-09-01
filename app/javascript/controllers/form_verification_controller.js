import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('focusin', this.verifyField.bind(this))
    this.element.addEventListener('input', this.verifyField.bind(this))
    this.element.addEventListener('change', this.verifyField.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('focusin', this.verifyField.bind(this))
    this.element.removeEventListener('input', this.verifyField.bind(this))
    this.element.removeEventListener('change', this.verifyField.bind(this))
  }

  verifyField(event) {
    const field = event.target
    
    if (field.dataset.verify === "pending" && event.isTrusted) {
      field.classList.remove('needs-verification')
      delete field.dataset.verify

      const unverifiedFields = this.element.querySelectorAll('[data-verify="pending"]')
      if (unverifiedFields.length === 0) {
        this.clearErrorBanner()
      }
    }
  }

  validateSubmit(event) {
    const unverifiedFields = Array.from(this.element.querySelectorAll('[data-verify="pending"]'))
                                  .filter(el => el.offsetParent !== null)
    
    if (unverifiedFields.length > 0) {
      event.preventDefault()
      event.stopImmediatePropagation()
      
      setTimeout(() => {
        const submitButtons = this.element.querySelectorAll('input[type="submit"], button[type="submit"]')
        submitButtons.forEach(btn => {
          btn.disabled = false
          btn.classList.remove('disabled') 
        })
      }, 10)
      
      this.showErrorBanner("Please review all highlighted auto-filled fields. Click on them to confirm they are correct before saving.")
      
      unverifiedFields[0].scrollIntoView({ behavior: 'smooth', block: 'center' })
      unverifiedFields[0].focus()
    } else {
      this.clearErrorBanner()
    }
  }

  showErrorBanner(message) {
    if (document.getElementById("autofill-verification-error")) return;

    let railsErrorBox = document.querySelector('.alert.alert-danger') || document.getElementById('error_explanation');

    if (railsErrorBox) {
      let ul = railsErrorBox.querySelector('ul');
      if (!ul) {
        ul = document.createElement('ul');
        railsErrorBox.appendChild(ul);
      }
      const li = document.createElement('li');
      li.id = "autofill-verification-error";
      li.textContent = message;
      ul.appendChild(li);
    } else {
      const errorHtml = `
        <div id="autofill-verification-error-box" class="alert alert-danger mt-3 mb-4">
          <ul class="mb-0">
            <li id="autofill-verification-error">${message}</li>
          </ul>
        </div>
      `;
      this.element.insertAdjacentHTML('afterbegin', errorHtml);
    }
  }

  clearErrorBanner() {
    const li = document.getElementById("autofill-verification-error");
    if (li) li.remove();
    
    const box = document.getElementById("autofill-verification-error-box");
    if (box) box.remove();
  }
}