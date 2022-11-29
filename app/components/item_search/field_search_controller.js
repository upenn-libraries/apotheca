import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "row" ]

    addInputSet(event) {
        const row = document.querySelector('.field-search-set');
        const newRow = row.cloneNode(true);
        newRow.querySelectorAll('input').forEach(input => { input.value = null });
        row.parentNode.insertBefore(newRow, null);

    }

    removeInputSet(event) {
        if(this.rowTargets.length === 1) {
            console.log('will not remove last row');
            return false;
        }
        event.target.parentNode.parentNode.remove();
    }
}
