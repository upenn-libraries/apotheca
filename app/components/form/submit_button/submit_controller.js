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
}
