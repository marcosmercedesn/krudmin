/**
 * =============================================================================
 * NESTED FIELDS STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages nested form rows for HasMany associations (replaces Cocoon gem).
 *
 * ─── HOW IT WORKS ───────────────────────────────────────────────────────────
 *
 * Rails nested attributes require fields named like:
 *   model[association_attributes][INDEX][field_name]
 *
 * A <template> element holds one blank row with "NEW_RECORD" as the index
 * placeholder. On "Add", we clone the template, replace "NEW_RECORD" with
 * a unique timestamp, and append to the <tbody>.
 *
 * On "Remove", persisted records get their _destroy flag set to "1" and are
 * hidden; new records are removed from the DOM entirely.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <div data-controller="nested-fields">
 *     <tbody data-nested-fields-target="body">...</tbody>
 *     <template data-nested-fields-target="template">...</template>
 *     <button data-action="nested-fields#add">Add</button>
 *     <!-- Per-row: -->
 *     <button data-action="nested-fields#remove">Remove</button>
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("nested-fields", class extends Stimulus.Controller {
  static targets = ["body", "template"];

  add(event) {
    event.preventDefault();

    if (!this.hasTemplateTarget || !this.hasBodyTarget) {
      console.warn("[nested-fields] Missing template or body target");
      return;
    }

    var uniqueIndex = new Date().getTime();
    var html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueIndex);

    this.bodyTarget.insertAdjacentHTML("beforeend", html);

    // Dispatch event so other Stimulus controllers can reinitialize
    this.dispatch("added", { detail: { target: this.bodyTarget } });
  }

  remove(event) {
    event.preventDefault();

    var row = event.target.closest(".nested-fields");
    if (!row) {
      console.warn("[nested-fields] Could not find .nested-fields parent");
      return;
    }

    var idInput = row.querySelector("input[name$='[id]']");
    var isPersisted = idInput && idInput.value && idInput.value !== "";

    if (isPersisted) {
      var destroyInput = row.querySelector(".destroy-flag");
      if (destroyInput) destroyInput.value = "1";
      row.style.display = "none";
    } else {
      row.remove();
    }
  }
});
