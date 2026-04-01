/**
 * =============================================================================
 * SEARCH PANEL STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages the search panel visibility on the index page.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <button data-action="search-panel#show">Search</button>
 *   <button data-action="search-panel#toggle">Toggle</button>
 *
 *   <div data-controller="search-panel"
 *        data-search-panel-target="panel"
 *        class="search-panel hidden">
 *     ...
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("search-panel", class extends Stimulus.Controller {
  static targets = ["panel"];

  show() {
    if (this.hasPanelTarget) {
      $(this.panelTarget).show("fast");
      this.scrollToTop();
    }
  }

  toggle() {
    if (this.hasPanelTarget) {
      $(this.panelTarget).slideToggle("fast");
      this.scrollToTop();
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
});
