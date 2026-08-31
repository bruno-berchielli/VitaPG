import { Controller } from "@hotwired/stimulus";

// Shows S3 credentials or the local directory field depending on the provider.
export default class extends Controller {
  static targets = ["provider", "s3Fields", "localFields"];

  connect() {
    this.providerChanged();
  }

  providerChanged() {
    const local = this.providerTarget.value === "local";
    this.s3FieldsTarget.hidden = local;
    this.localFieldsTarget.hidden = !local;
  }
}
