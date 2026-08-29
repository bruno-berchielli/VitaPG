import { Controller } from "@hotwired/stimulus";

// Keeps the log viewport pinned to the newest line while entries stream in.
export default class extends Controller {
  connect() {
    this.scrollToBottom();
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.element, { childList: true, subtree: true });
  }

  disconnect() {
    this.observer?.disconnect();
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight;
  }
}
