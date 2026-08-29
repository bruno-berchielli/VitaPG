import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel"];

  toggle() {
    this.panelTarget.hidden = !this.panelTarget.hidden;
  }

  hide() {
    this.panelTarget.hidden = true;
  }

  hideOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.hide();
  }
}
