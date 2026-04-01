/**
 * =============================================================================
 * CARD COLLAPSE STIMULUS CONTROLLER
 * =============================================================================
 *
 * Makes form section cards collapsible with sessionStorage persistence.
 * Remembers which cards are collapsed across page navigations within
 * the same session.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <div class="card" data-controller="card-collapse"
 *        data-card-collapse-panel-value="general">
 *     <div class="card-header">
 *       <a data-action="click->card-collapse#toggle" class="card-collapser">
 *         <i data-card-collapse-target="icon" class="fa fa-chevron-up fa-lg"></i>
 *       </a>
 *     </div>
 *     <div data-card-collapse-target="body" class="card-body">...</div>
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("card-collapse", class extends Stimulus.Controller {
  static targets = ["body", "icon"];
  static values = { panel: String };

  connect() {
    if (sessionStorage.getItem(this.storageKey)) {
      this.collapse(false);
    }
  }

  toggle(event) {
    event.preventDefault();

    var isExpanded = this.iconTarget.classList.contains("fa-chevron-up");

    if (isExpanded) {
      this.collapse(true);
      sessionStorage.setItem(this.storageKey, "true");
    } else {
      this.expand(true);
      sessionStorage.removeItem(this.storageKey);
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  get storageKey() {
    var controller = document.body.dataset.controller || "";
    var action = document.body.dataset.action || "";
    return controller + "-" + action + "-" + this.panelValue;
  }

  collapse(animate) {
    if (animate) {
      $(this.bodyTarget).slideUp();
    } else {
      this.bodyTarget.style.display = "none";
    }
    this.iconTarget.classList.remove("fa-chevron-up");
    this.iconTarget.classList.add("fa-chevron-down");
  }

  expand(animate) {
    if (animate) {
      $(this.bodyTarget).slideDown();
    } else {
      this.bodyTarget.style.display = "";
    }
    this.iconTarget.classList.remove("fa-chevron-down");
    this.iconTarget.classList.add("fa-chevron-up");
  }
});
