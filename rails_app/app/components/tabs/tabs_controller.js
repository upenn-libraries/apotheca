import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "tab" ]
    static values = {
        defaultTab: String
    }

    tabTargetConnected(tabElement) {
        const tabTrigger = new bootstrap.Tab(tabElement)
        const anchor = window.location.hash;

        // Show tab if anchor matches tab.
        if (tabElement.dataset.bsTarget === anchor) {
            tabTrigger.show();
        }

        // Show default tab if anchor is not present.
        if (!anchor && tabElement.dataset.bsTarget.slice(1) === this.defaultTabValue) {
            tabTrigger.show();
        }

        // Updates URL anchor when tab is clicked.
        tabElement.addEventListener('click', event => {
            event.preventDefault();

            // Update history in order to change the URL in the address bar.
            let url = new URL(window.location.href);
            url.hash = event.target.dataset.bsTarget;
            history.replaceState(history.state, '', url);

            // Show tab.
            tabTrigger.show();
        })
    }
}
