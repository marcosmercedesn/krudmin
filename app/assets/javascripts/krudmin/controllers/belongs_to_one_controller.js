/**
 * =============================================================================
 * BELONGS TO ONE STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages the add/remove UI for HasOne and BelongsToOne inline nested forms.
 * Shows the "Add" button if no associated record exists, and "Delete" button
 * if one does. Handles form field insertion and destruction.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <div data-controller="belongs-to-one"
 *        data-belongs-to-one-model-id-value="42"
 *        data-belongs-to-one-form-fields-value="<html...>">
 *     <div data-belongs-to-one-target="fields">
 *       <div class="editable-attributes">...</div>
 *     </div>
 *     <input data-belongs-to-one-target="destroyFlag" type="hidden" class="destroy_model_check">
 *     <a data-action="belongs-to-one#add" data-belongs-to-one-target="addButton" class="hidden">Add</a>
 *     <a data-action="belongs-to-one#remove" data-belongs-to-one-target="removeButton" class="hidden">Delete</a>
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("belongs-to-one", class extends Stimulus.Controller {
  static targets = ["fields", "destroyFlag", "addButton", "removeButton"];
  static values = { modelId: String, formFields: String };

  connect() {
    if (this.modelIdValue) {
      this.showRemoveButton();
    } else {
      this.showAddButton();
    }
  }

  add(event) {
    event.preventDefault();

    var fieldsContainer = this.fieldsTarget.querySelector(".editable-attributes");

    if (!fieldsContainer) {
      this.fieldsTarget.innerHTML = this.formFieldsValue;
    } else {
      var domElement = new DOMParser().parseFromString(this.formFieldsValue, "text/html");
      var newAttributes = domElement.querySelector(".editable-attributes");
      if (newAttributes) {
        fieldsContainer.innerHTML = newAttributes.innerHTML;
      }
    }

    if (fieldsContainer) fieldsContainer.style.display = "";

    if (this.hasDestroyFlagTarget) {
      this.destroyFlagTarget.value = "false";
    }

    this.showRemoveButton();

    // Dispatch event so other controllers can reinitialize
    this.dispatch("added", { detail: { target: this.fieldsTarget } });
  }

  remove(event) {
    event.preventDefault();

    var fieldsContainer = this.fieldsTarget.querySelector(".editable-attributes");
    if (fieldsContainer) fieldsContainer.innerHTML = "";

    if (this.hasDestroyFlagTarget) {
      this.destroyFlagTarget.value = "true";
    }

    this.showAddButton();
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  showAddButton() {
    if (this.hasAddButtonTarget) this.addButtonTarget.classList.remove("hidden");
    if (this.hasRemoveButtonTarget) this.removeButtonTarget.classList.add("hidden");
  }

  showRemoveButton() {
    if (this.hasAddButtonTarget) this.addButtonTarget.classList.add("hidden");
    if (this.hasRemoveButtonTarget) this.removeButtonTarget.classList.remove("hidden");
  }
});
