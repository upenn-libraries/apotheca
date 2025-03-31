import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["popover"];
  connect() {
		console.log("popover controller connected");
    this.popoverTargets.map((target) => new bootstrap.Popover(target));
  }
}
