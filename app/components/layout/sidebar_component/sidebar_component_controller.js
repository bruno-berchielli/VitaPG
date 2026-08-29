import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  toggle() {
    this.menuTarget.hidden = !this.menuTarget.hidden;
  }

  hide() {
    this.menuTarget.hidden = true;
  }

  hideOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.hide();
  }
}
