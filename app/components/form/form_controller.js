import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "errors" ]

    // Action for unexpected network errors.
    networkError(event) {
        this.errorsTarget.innerHTML = '<div class="alert alert-danger" role="alert"><h3>Unexpected Error: ' + event.detail.error.message + '</h3></div>'
        this.errorsTarget.scrollIntoView({ block: "center" });
    }

    // Action for a completed form submission.
    formSubmission(event) {
        // If response is not being redirected, scroll to errors.
        if (!event.detail.fetchResponse.response.redirected) {
            this.errorsTarget.scrollIntoView({ block: "center" });
        }
    }
}