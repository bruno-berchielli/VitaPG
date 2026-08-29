import { Controller } from "@hotwired/stimulus";

// Keeps the routine form honest about what applies to what:
// - schedule presets fill the real cron field; "custom" reveals it
// - parallel jobs only exist for the directory format
export default class extends Controller {
  static targets = ["cronSelect", "cronField", "cronInput", "format", "parallelWrap"];

  connect() {
    this.syncCronSelect();
    this.formatChanged();
  }

  syncCronSelect() {
    const current = this.cronInputTarget.value;
    const preset = [...this.cronSelectTarget.options].find((option) => option.value === current);
    this.cronSelectTarget.value = preset ? current : "custom";
    this.cronFieldTarget.hidden = Boolean(preset);
  }

  cronPresetChanged() {
    const value = this.cronSelectTarget.value;

    if (value === "custom") {
      this.cronFieldTarget.hidden = false;
      this.cronInputTarget.focus();
    } else {
      this.cronInputTarget.value = value;
      this.cronFieldTarget.hidden = true;
    }
  }

  formatChanged() {
    const directory = this.formatTarget.value === "directory";
    this.parallelWrapTarget.hidden = !directory;
  }
}
