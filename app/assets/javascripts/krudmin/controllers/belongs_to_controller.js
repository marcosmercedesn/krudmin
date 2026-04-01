/**
 * =============================================================================
 * BELONGS TO STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages the "Edit" button next to BelongsTo select dropdowns. When the
 * user selects an associated record, the edit link URL updates to point
 * to that record.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <div class="associated-resource-container"
 *        data-controller="belongs-to">
 *     <select data-action="change->belongs-to#updateEditUrl"
 *             data-belongs-to-target="select">
 *     <a data-belongs-to-target="editLink"
 *        data-edit-url="/admin/car_brands/__ID__/edit"
 *        class="hidden">Edit</a>
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("belongs-to", class extends Stimulus.Controller {
  static targets = ["select", "editLink"];

  connect() {
    if (this.hasSelectTarget && this.hasEditLinkTarget) {
      this.updateEditUrl();
    }
  }

  updateEditUrl() {
    if (!this.hasEditLinkTarget) return;

    var value = this.selectTarget.value;
    var editUrl = this.editLinkTarget.dataset.editUrl;

    if (editUrl) {
      this.editLinkTarget.setAttribute("href", editUrl.replace("__ID__", value));
    }

    if (value) {
      this.editLinkTarget.classList.remove("hidden");
    } else {
      this.editLinkTarget.classList.add("hidden");
    }
  }
});
