import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "input", "add", "remove", "template" ]

    // Add empty input, if no child inputs are found
    connect() {
        if (this.inputTargets.length === 0) {
            var newInput = this.templateTarget.content.cloneNode(true)
            this.element.appendChild(newInput)
        }
    }

    inputTargetConnected(element) {
        this.preventDeletionOfLastInput()
    }

    inputTargetDisconnected(element) {
        this.preventDeletionOfLastInput()
    }

    addInput(event) {
        var inputNode = event.target.parentNode.parentNode
        var newInput = this.templateTarget.content.cloneNode(true)
        var parentNode = inputNode.parentNode // Parent node of controller element
        parentNode.insertBefore(newInput, inputNode.nextElementSibling)
    }

    removeInput(event) {
        var inputNode = event.target.parentNode.parentNode
        inputNode.remove()
    }

    // Disable delete button for last input.
    preventDeletionOfLastInput() {
        this.inputTargets.forEach((input, index) => {
            var deleteButton = this.removeTargets[index]

            if (this.inputTargets.length == 1 && index === 0) {
                deleteButton.setAttribute("disabled", "")
            } else {
                deleteButton.removeAttribute("disabled")
            }
        })
    }
}