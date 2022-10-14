import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "input" ]

    inputTargetConnected(element) {
        this.preventDeletionOfFirstInput(this.inputTargets)
    }

    inputTargetDisconnected(element) {
        this.preventDeletionOfFirstInput(this.inputTargets)
    }

    preventDeletionOfFirstInput(inputs) {
        inputs.forEach((input, index) => {
            var deleteButton = input.querySelector('[data-multivalued-input--input-list-target="delete"]')

            if (index === 0) {
                deleteButton.setAttribute("disabled", "")
            } else {
                deleteButton.removeAttribute("disabled")
            }
        })
    }
}