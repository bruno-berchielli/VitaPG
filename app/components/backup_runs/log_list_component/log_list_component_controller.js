import { Controller } from "@hotwired/stimulus";

// Keeps the log viewport pinned to the newest line while entries stream in,
// and keeps the entry count and empty placeholder in sync with them.
export default class extends Controller {
  static targets = ["viewport", "list", "count", "empty"];
  static values = { one: String, other: String };

  connect() {
    this.refresh();
    this.observer = new MutationObserver(() => this.refresh());
    this.observer.observe(this.listTarget, { childList: true });
  }

  disconnect() {
    this.observer?.disconnect();
  }

  refresh() {
    const count = this.listTarget.children.length;
    const template = count === 1 ? this.oneValue : this.otherValue;

    this.countTarget.textContent = template.replace("{count}", count);
    this.emptyTarget.hidden = count > 0;
    this.viewportTarget.scrollTop = this.viewportTarget.scrollHeight;
  }
}
