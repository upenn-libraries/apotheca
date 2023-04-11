import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    confirm(event) {
        const message = this.element.dataset.confirm ;
        if(!confirm(message)) {
            event.preventDefault();
            // stop stimulus action chain for 'click' event
            event.stopImmediatePropagation();
        }
    }

    disableSubmit() {
        const disableWith = this.element.dataset.disableWith
        // disable submit button after event fires
        setTimeout(()=> {
            this.element.disabled = true
            this.element.value = disableWith
        },0)
    }
}
