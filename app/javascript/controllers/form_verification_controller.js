import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorBox", "errorList", "clientErrorItem"]

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
    if (this.hasClientErrorItemTarget && this.hasErrorBoxTarget) {
      this.clientErrorItemTarget.textContent = message
      this.clientErrorItemTarget.classList.remove('d-none')
      this.errorBoxTarget.classList.remove('d-none')
    }
  }

  clearErrorBanner() {
    if (this.hasClientErrorItemTarget && this.hasErrorBoxTarget) {
      this.clientErrorItemTarget.classList.add('d-none')
      this.clientErrorItemTarget.textContent = ''

      const activeErrors = this.errorListTarget.querySelectorAll('li:not(.d-none)')
      
      if (activeErrors.length === 0) {
        this.errorBoxTarget.classList.add('d-none')
      }
    }
  }
}
