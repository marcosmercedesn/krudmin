/**
 * =============================================================================
 * TOOLTIP STIMULUS CONTROLLER
 * =============================================================================
 *
 * Initializes Bootstrap tooltips. Automatically connects/disconnects when
 * elements appear in or leave the DOM (e.g., via Turbo Stream).
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <span data-controller="tooltip" data-bs-toggle="tooltip" title="Help">?</span>
 *
 * =============================================================================
 */

KrudminApp.register("tooltip", class extends Stimulus.Controller {
  connect() {
    if (!bootstrap.Tooltip.getInstance(this.element)) {
      this._tooltip = new bootstrap.Tooltip(this.element);
    }
  }

  disconnect() {
    if (this._tooltip) {
      this._tooltip.dispose();
      this._tooltip = null;
    }
  }
});
