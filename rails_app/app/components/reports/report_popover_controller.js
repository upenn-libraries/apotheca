import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["popover"];
  connect() {
    this.popoverTargets.map((target) => new bootstrap.Popover(target));
  }
}
