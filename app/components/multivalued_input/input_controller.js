import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "source" ]

    addInput(event) {
        var newInput = this.element.cloneNode(true)
        newInput.querySelectorAll('input').forEach( input => { input.value = null })
        var parentNode = this.element.parentNode // Parent node of controller element
        parentNode.insertBefore(newInput, this.element.nextElementSibling)
    }

    removeInput(event) {
        this.element.remove()
    }
}