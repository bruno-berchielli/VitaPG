import "@hotwired/turbo-rails";
import "./controllers";
import "../components";

// Custom properties resolve per element, so the theme attribute must live on
// <html>. Turbo only swaps <body>, so we mirror the freshly rendered body's
// data-mode back onto <html> after every render.
document.addEventListener("turbo:render", () => {
  document.documentElement.dataset.mode = document.body.dataset.mode;
});
