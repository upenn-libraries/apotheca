import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect(event) {
        const anchor = window.location.hash;
        const elem = document.querySelector(anchor + '-tab');
        if(elem) {
            const tab = new bootstrap.Tab(anchor + '-tab');
            tab.show()
        }
    }
    updateUrl(event) {
        window.location = event.target.dataset.bsTarget;
    }
}
