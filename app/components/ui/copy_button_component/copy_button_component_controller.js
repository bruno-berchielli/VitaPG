import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["idle", "done"];
  static values = { text: String };

  async copy() {
    await navigator.clipboard.writeText(this.textValue);
    this.idleTarget.hidden = true;
    this.doneTarget.hidden = false;
    setTimeout(() => {
      this.idleTarget.hidden = false;
      this.doneTarget.hidden = true;
    }, 1500);
  }
}
