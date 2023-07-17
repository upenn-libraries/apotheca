import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect(event) {
        const anchor = window.location.hash;
        const elem = document.querySelector(anchor + '-tab');
        if(elem) {
            // init Bootstrap Tab object - https://getbootstrap.com/docs/5.0/components/navs-tabs/#show
            const tab = new bootstrap.Tab(anchor + '-tab');
            tab.show();
        }
    }
    updateUrl(event) {
        window.location = event.target.dataset.bsTarget;
    }
}
