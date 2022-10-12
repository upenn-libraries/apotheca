import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "errors" ]

    formSubmission(event) {
        // After form submission scroll to errors.
        if (!event.detail.fetchResponse.response.redirected) {
            this.errorsTarget.scrollIntoView({ block: "center" });
        }
    }
}