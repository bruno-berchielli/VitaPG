import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog"];

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  // Native <dialog>: a click whose target is the dialog element itself landed
  // on the backdrop, not the content.
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close();
  }
}
