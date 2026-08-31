import { Controller } from "@hotwired/stimulus";

// Reveals the SSH fields only when the connection goes through a tunnel.
export default class extends Controller {
  static targets = ["mode", "sshFields"];

  connect() {
    this.modeChanged();
  }

  modeChanged() {
    this.sshFieldsTarget.hidden = this.modeTarget.value !== "ssh_tunnel";
  }
}
