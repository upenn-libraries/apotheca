import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    // make disable_with data-attribute available to Controller by defining Stimulus static values hash
    static values = {
        disableWith: String
    }

    submitButton() {
        return this.element.querySelector("input[type='submit']")
    }

    // disable submit button after submit event fires
    disableSubmit(event) {
        let submit = this.submitButton()
        submit.disabled = true
        submit.value = this.disableWithValue
    }
}