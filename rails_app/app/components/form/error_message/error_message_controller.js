import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect(event) {
        this.element.scrollIntoView({behavior:"smooth"});
    }
}
