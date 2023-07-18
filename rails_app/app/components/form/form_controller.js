import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    disableSubmit(event) {
        const disableWith = this.element.dataset.disableWith
        event.submitter.value = disableWith
        event.submitter.disabled = true
    }
}
