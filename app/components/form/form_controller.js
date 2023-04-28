import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    disableSubmit(event) {
        const disableWith = event.submitter.dataset.disableWith

        if (disableWith) {
            event.submitter.value = disableWith
            event.submitter.disabled = true
        }
    }
}
