// Auto-registers every ViewComponent sidecar Stimulus controller.
// The glob import is resolved by esbuild-rails, which maps each file path to
// a controller identifier (e.g. runs/log_viewer_component/log_viewer_component_controller.js
// becomes "runs--log-viewer-component--log-viewer-component").
import { application } from "../javascript/controllers/application";
import controllers from "./**/*_controller.js";

controllers.forEach((controller) => {
  application.register(controller.name, controller.module.default);
});
