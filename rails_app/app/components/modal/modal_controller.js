import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ['body']

    copy() {
            navigator.clipboard.writeText(this.bodyTarget.innerText);
    }
}