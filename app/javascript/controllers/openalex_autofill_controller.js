import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 
    "doiInput", "button", "buttonText", "spinner", "error", "success",
    
    "title", "year", "link", "category", "status",
    
    "identifiersContainer", "addIdentifierBtn",
    "oaContainer", "addOABtn", "oaCategory",
    "authorsContainer", "addAuthorBtn",
    "journalContainer", "addJournalBtn",
    "conferenceContainer", "addConferenceBtn"
  ]

  async fetchMetadata(event) {
    event.preventDefault()
    const doi = this.doiInputTarget.value.trim()
    
    if (!doi) {
      this.showError("Please enter a DOI first.")
      return
    }

    this.setLoading(true)
    this.hideMessages()

    try {
      const response = await fetch(`/api/openalex/search?doi=${encodeURIComponent(doi)}`)
      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || `HTTP error ${response.status}`)
      }

      await this.clearForm()
      await this.sleep(150)

      await this.populateFields(data) 
      this.showSuccess("Data successfully loaded from OpenAlex!")
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.setLoading(false)
    }
  }

  async clearForm() {
    const simpleTargets = [
      this.hasTitleTarget ? this.titleTarget : null,
      this.hasYearTarget ? this.yearTarget : null,
      this.hasLinkTarget ? this.linkTarget : null,
      this.hasCategoryTarget ? this.categoryTarget : null,
      this.hasStatusTarget ? this.statusTarget : null
    ]

    simpleTargets.forEach(target => {
      if (target) {
        target.value = ""
        this.triggerChange(target)
      }
    })

    const cocoonContainers = [
      this.hasAuthorsContainerTarget ? this.authorsContainerTarget : null,
      this.hasIdentifiersContainerTarget ? this.identifiersContainerTarget : null,
      this.hasOaContainerTarget ? this.oaContainerTarget : null
    ]

    cocoonContainers.forEach(container => {
      if (!container) return;
      const removeBtns = container.querySelectorAll('.nested-fields .remove_fields, .nested-fields .btn-danger');
      removeBtns.forEach(btn => btn.click());
    })

    const clearAssocEditor = (container, editClass) => {
      if (!container) return;
      
      const select = container.querySelector('.items-list select');
      if (select) {
        select.value = "";
        this.triggerChange(select);
      }
      
      const inputs = container.querySelectorAll(`.${editClass} input`);
      inputs.forEach(input => {
        if (input.type !== 'hidden') {
          input.value = "";
          this.triggerChange(input);
        }
      });

      const dynamicRemoveBtns = container.querySelectorAll('.nested-fields .remove_fields, .nested-fields .btn-danger');
      dynamicRemoveBtns.forEach(btn => btn.click());
    }

    if (this.hasJournalContainerTarget) clearAssocEditor(this.journalContainerTarget, 'journal-issue-edit');
    if (this.hasConferenceContainerTarget) clearAssocEditor(this.conferenceContainerTarget, 'conference-edit');
  }

  async populateFields(data) {
    if (data.title && this.hasTitleTarget) { this.titleTarget.value = data.title; this.triggerChange(this.titleTarget); }
    if (data.publication_year && this.hasYearTarget) { this.yearTarget.value = data.publication_year; this.triggerChange(this.yearTarget); }
    if (data.link && this.hasLinkTarget) { this.linkTarget.value = data.link; this.triggerChange(this.linkTarget); }
    if (data.category && this.hasCategoryTarget) { this.categoryTarget.value = data.category; this.triggerChange(this.categoryTarget); }
    if (data.status && this.hasStatusTarget) { this.statusTarget.value = data.status; this.triggerChange(this.statusTarget); }

    if (data.open_access) await this.populateOpenAccess(data.open_access)
    if (data.authors && data.authors.length > 0) await this.populateAuthors(data.authors)
    if (data.journal) await this.populateJournal(data.journal)
    if (data.conference) await this.populateConference(data.conference)

    if (data.identifiers && Array.isArray(data.identifiers)) {
      for (const identifier of data.identifiers) {
        if (identifier.category && identifier.value) {
          await this.populateIdentifier(identifier.category, identifier.value);
        }
      }
    }
  }

  async populateIdentifier(categoryStr, valueStr) {
    if (!this.hasIdentifiersContainerTarget || !this.hasAddIdentifierBtnTarget) return;

    this.addIdentifierBtnTarget.click();
    await this.sleep(150);

    const categories = this.identifiersContainerTarget.querySelectorAll('select[name*="[category]"]');
    const values = this.identifiersContainerTarget.querySelectorAll('input[name*="[value]"]');

    if (categories.length > 0 && values.length > 0) {
      const lastCategory = categories[categories.length - 1];
      const lastValue = values[values.length - 1];

      lastCategory.value = categoryStr;
      lastValue.value = valueStr;
      
      this.triggerChange(lastCategory);
      this.triggerChange(lastValue);
    }
  }

  async populateOpenAccess(oaData) {
    if (!this.hasOaContainerTarget || !this.hasAddOABtnTarget || !oaData || !oaData.status) return;

    this.addOABtnTarget.click();
    await this.sleep(150);

    const categories = this.oaCategoryTargets;
    if (categories.length > 0) {
      const targetCategory = categories[categories.length - 1];
      targetCategory.value = oaData.status.toLowerCase();
      this.triggerChange(targetCategory);
    }
  }

  async populateAuthors(authors) {
    if (!this.hasAuthorsContainerTarget || !this.hasAddAuthorBtnTarget) return;

    const container = this.authorsContainerTarget;

    for (let i = 0; i < authors.length; i++) {
      const author = authors[i];
      
      this.addAuthorBtnTarget.click();
      await this.sleep(150);

      const nestedFields = container.querySelectorAll('.nested-fields');
      const targetField = nestedFields[nestedFields.length - 1];
      
      if (!targetField) continue;

      const sourceSelect = targetField.querySelector('select[data-authorship-source-target="mode"]');

      if (author.match_type === 'existing') {
        if (sourceSelect) { sourceSelect.value = 'existing'; this.triggerChange(sourceSelect); }
        const authorIdSelect = targetField.querySelector('select[name$="[author_id]"]');
        if (authorIdSelect) { authorIdSelect.value = author.id; this.triggerChange(authorIdSelect); }
      } 
      else if (author.match_type === 'new') {
        if (sourceSelect) { sourceSelect.value = 'new'; this.triggerChange(sourceSelect); }
        const typeSelect = targetField.querySelector('select[name*="[author_type]"]');
        
        if (author.author_type === 'collective') {
          if (typeSelect) { typeSelect.value = 'collective'; this.triggerChange(typeSelect); }
          const collectiveInput = targetField.querySelector('input[name*="[collective_name]"]');
          if (collectiveInput) { collectiveInput.value = author.collective_name || ""; this.triggerChange(collectiveInput); }
        } else {
          if (typeSelect) { typeSelect.value = 'person'; this.triggerChange(typeSelect); }
          
          const titleInput = targetField.querySelector('input[name*="[title]"]');
          const firstNameInput = targetField.querySelector('input[name*="[first_name]"]');
          const lastNameInput = targetField.querySelector('input[name*="[last_name]"]');

          if (titleInput && author.title) { titleInput.value = author.title; this.triggerChange(titleInput); }
          if (firstNameInput) { firstNameInput.value = author.first_name || ""; this.triggerChange(firstNameInput); }
          if (lastNameInput) { lastNameInput.value = author.last_name || ""; this.triggerChange(lastNameInput); }
        }
      }
    }
  }

  async populateJournal(journalData) {
    if (!this.hasJournalContainerTarget || !journalData.title) return;
    
    const select = this.journalContainerTarget.querySelector('.items-list select');

    if (journalData.match_type === 'existing' && journalData.id) {
      if (select) {
        select.value = journalData.id;
        this.triggerChange(select);
      }
      return;
    }

    if (select) {
      select.value = "";
      this.triggerChange(select);
    }

    if (this.hasAddJournalBtnTarget) {
      this.addJournalBtnTarget.click();
      await this.sleep(150);
    }

    const dynamicFields = this.journalContainerTarget.querySelectorAll('.nested-fields');
    const targetField = dynamicFields.length > 0 
      ? dynamicFields[dynamicFields.length - 1] 
      : this.journalContainerTarget.querySelector('.journal-issue-edit');

    if (!targetField) return;

    const titleInput = targetField.querySelector('input[name*="[title]"]');
    const numInput = targetField.querySelector('input[name*="[journal_num]"]');
    const publisherInput = targetField.querySelector('input[name*="[publisher]"]');
    const volumeInput = targetField.querySelector('input[name*="[volume]"]');

    if (titleInput) { titleInput.value = journalData.title; this.triggerChange(titleInput); }
    if (numInput && journalData.journal_num) { numInput.value = journalData.journal_num; this.triggerChange(numInput); }
    if (publisherInput && journalData.publisher) { publisherInput.value = journalData.publisher; this.triggerChange(publisherInput); }
    if (volumeInput && journalData.volume) { volumeInput.value = journalData.volume; this.triggerChange(volumeInput); }
  }

  async populateConference(confData) {
    if (!this.hasConferenceContainerTarget || !confData.name) return;

    const select = this.conferenceContainerTarget.querySelector('.items-list select');

    if (confData.match_type === 'existing' && confData.id) {
      if (select) {
        select.value = confData.id;
        this.triggerChange(select);
      }
      return;
    }

    if (select) {
      select.value = "";
      this.triggerChange(select);
    }
    
    if (this.hasAddConferenceBtnTarget) {
      this.addConferenceBtnTarget.click();
      await this.sleep(150);
    }

    const dynamicFields = this.conferenceContainerTarget.querySelectorAll('.nested-fields');
    const targetField = dynamicFields.length > 0 
      ? dynamicFields[dynamicFields.length - 1] 
      : this.conferenceContainerTarget.querySelector('.conference-edit');

    if (!targetField) return;

    const nameInput = targetField.querySelector('input[name*="[name]"]');
    if (nameInput) { nameInput.value = confData.name; this.triggerChange(nameInput); }
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  triggerChange(element) {
    element.dispatchEvent(new Event('change', { bubbles: true }))
  }

  setLoading(isLoading) {
    this.buttonTarget.disabled = isLoading
    if (isLoading) {
      this.spinnerTarget.classList.remove("d-none")
      this.buttonTextTarget.textContent = "Searching..."
    } else {
      this.spinnerTarget.classList.add("d-none")
      this.buttonTextTarget.textContent = "Autofill"
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("d-none")
  }

  showSuccess(message) {
    this.successTarget.textContent = message
    this.successTarget.classList.remove("d-none")
  }

  hideMessages() {
    this.errorTarget.classList.add("d-none")
    this.successTarget.classList.add("d-none")
  }
}
