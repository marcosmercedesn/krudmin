/**
 * =============================================================================
 * KRUDMIN NESTED FIELDS CONTROLLER
 * =============================================================================
 *
 * Replaces the Cocoon gem for managing nested form rows (HasMany associations).
 * This is a vanilla JS solution — no Stimulus framework required.
 *
 * ─── HOW IT WORKS ───────────────────────────────────────────────────────────
 *
 * Rails nested attributes require a specific naming convention for form fields:
 *
 *   model[association_attributes][INDEX][field_name]
 *   e.g. car[passengers_attributes][0][name]
 *
 * When the user clicks "Add", we:
 *   1. Clone the HTML from a <template> tag (which contains one blank row)
 *   2. Replace a placeholder timestamp in all field names/IDs with a unique
 *      index (Date.now()) so Rails treats it as a new record
 *   3. Append the new row to the <tbody>
 *   4. Dispatch a "krudmin:updateControls" event so that Select2, datepickers,
 *      Summernote, etc. reinitialize on the new fields
 *
 * When the user clicks "Remove", we:
 *   1. Find the hidden `_destroy` input inside that row and set it to "1"
 *      (this tells Rails' accepts_nested_attributes_for to delete the record)
 *   2. Hide the row visually
 *   - For NEW rows (not yet persisted), we remove the DOM entirely instead
 *
 * ─── DATA ATTRIBUTES ────────────────────────────────────────────────────────
 *
 * The system uses data attributes on HTML elements to wire everything up:
 *
 *   [data-nested-fields="container"]
 *       Marks the wrapping element for the entire nested fields group.
 *       Must contain the <template> and the <tbody>.
 *
 *   [data-nested-target="body"]
 *       The <tbody> element where rows live and new rows get appended.
 *
 *   [data-nested-target="template"]
 *       The <template> element containing the blank row HTML.
 *       Field names inside use a placeholder like "NEW_RECORD" that
 *       gets replaced with a unique timestamp on each "Add".
 *
 *   [data-nested-action="add"]
 *       The "Add" button. Clicking it clones the template and appends a row.
 *
 *   [data-nested-action="remove"]
 *       The "Remove" button on each row. Marks the row for destruction.
 *
 * ─── EXAMPLE HTML STRUCTURE ─────────────────────────────────────────────────
 *
 *   <div data-nested-fields="container">
 *     <table>
 *       <tbody data-nested-target="body">
 *         <!-- existing rows rendered by Rails -->
 *         <tr class="nested-fields">
 *           <td><input name="car[passengers_attributes][0][name]"></td>
 *           <td>
 *             <input type="hidden" name="car[passengers_attributes][0][_destroy]"
 *                    class="destroy-flag" value="false">
 *             <button data-nested-action="remove">Remove</button>
 *           </td>
 *         </tr>
 *       </tbody>
 *     </table>
 *
 *     <template data-nested-target="template">
 *       <tr class="nested-fields">
 *         <td><input name="car[passengers_attributes][NEW_RECORD][name]"></td>
 *         <td>
 *           <input type="hidden" name="car[passengers_attributes][NEW_RECORD][_destroy]"
 *                  class="destroy-flag" value="false">
 *           <button data-nested-action="remove">Remove</button>
 *         </td>
 *       </tr>
 *     </template>
 *
 *     <button data-nested-action="add">Add</button>
 *   </div>
 *
 * ─── INTEGRATION WITH KRUDMIN ───────────────────────────────────────────────
 *
 * After adding a new row, the controller dispatches the "krudmin:updateControls"
 * custom event. This is the same event that the rest of krudmin listens for to
 * reinitialize rich controls (Select2 dropdowns, datepickers, Summernote editors,
 * tooltips). See app.js → initKrudminScriptsForControls().
 *
 * =============================================================================
 */

(function() {
  "use strict";

  // ─── CONSTANTS ──────────────────────────────────────────────────────────────
  //
  // The placeholder string used inside <template> field names.
  // When we clone a template row, every occurrence of this string gets replaced
  // with a unique timestamp so Rails sees it as a distinct new record.

  var PLACEHOLDER = "NEW_RECORD";

  // ─── ADD ROW ────────────────────────────────────────────────────────────────
  //
  // Called when the user clicks [data-nested-action="add"].
  //
  // Steps:
  //   1. Walk up the DOM to find the nearest [data-nested-fields="container"]
  //   2. Inside it, find the <template> and the <tbody>
  //   3. Clone the template's innerHTML
  //   4. Replace the PLACEHOLDER with a unique index (timestamp)
  //   5. Append the new HTML to the <tbody>
  //   6. Fire "krudmin:updateControls" so rich widgets reinitialize

  function addRow(event) {
    event.preventDefault();

    var button    = event.target.closest("[data-nested-action='add']");
    var container = button.closest("[data-nested-fields='container']");
    var template  = container.querySelector("[data-nested-target='template']");
    var body      = container.querySelector("[data-nested-target='body']");

    if (!template || !body) {
      console.warn("[nested-fields] Missing template or body in container", container);
      return;
    }

    // Generate a unique index for the new record.
    // Using Date.now() guarantees uniqueness within the same form submission.
    // Rails only cares that each nested record has a distinct key — it doesn't
    // need to be sequential.
    var uniqueIndex = new Date().getTime();

    // Clone the template content and replace all placeholder strings.
    // The template contains field names like:
    //   car[passengers_attributes][NEW_RECORD][name]
    // We replace "NEW_RECORD" → "1711929600000" (unique timestamp).
    var html = template.innerHTML.replace(new RegExp(PLACEHOLDER, "g"), uniqueIndex);

    // Insert the new row at the end of the <tbody>.
    body.insertAdjacentHTML("beforeend", html);

    // Tell the rest of krudmin to reinitialize controls (Select2, datepickers, etc.)
    // on the new DOM elements we just added.
    dispatchUpdateControls(body);
  }

  // ─── REMOVE ROW ─────────────────────────────────────────────────────────────
  //
  // Called when the user clicks [data-nested-action="remove"].
  //
  // Two cases:
  //   A) PERSISTED record (has an [id] hidden input with a value):
  //      → Set the _destroy hidden field to "1" so Rails deletes it on save
  //      → Hide the <tr> visually (the form still submits the _destroy flag)
  //
  //   B) NEW record (no id, or id is blank):
  //      → Just remove the <tr> from the DOM entirely — nothing to tell Rails

  function removeRow(event) {
    event.preventDefault();

    var button = event.target.closest("[data-nested-action='remove']");
    var row    = button.closest(".nested-fields");

    if (!row) {
      console.warn("[nested-fields] Could not find .nested-fields parent for remove button");
      return;
    }

    // Check if this is a persisted record by looking for a hidden input named [...][id]
    // with a non-empty value. Rails adds this for existing records.
    var idInput = row.querySelector("input[name$='[id]']");
    var isPersisted = idInput && idInput.value && idInput.value !== "";

    if (isPersisted) {
      // Mark for destruction: set the _destroy hidden field to "1".
      // Rails' accepts_nested_attributes_for will delete this record on save.
      var destroyInput = row.querySelector(".destroy-flag");
      if (destroyInput) {
        destroyInput.value = "1";
      }

      // Hide the row so the user sees it as "removed", but the form data
      // (including _destroy=1) still gets submitted.
      row.style.display = "none";
    } else {
      // New record that was never saved — just remove it from the DOM.
      row.remove();
    }
  }

  // ─── UPDATE CONTROLS EVENT ──────────────────────────────────────────────────
  //
  // Dispatches the "krudmin:updateControls" custom event that the rest of the
  // krudmin JS listens for. This triggers reinitialization of:
  //   - Select2 dropdowns
  //   - Date/time pickers
  //   - Summernote rich text editors
  //   - Bootstrap tooltips
  //
  // See: app/assets/javascripts/krudmin/core_theme/app.js → updateKrudminControlsOn()

  function dispatchUpdateControls(targetElement) {
    var event = new CustomEvent("krudmin:updateControls", {
      detail: {
        selector: targetElement,
        event: null
      }
    });

    document.dispatchEvent(event);
  }

  // ─── EVENT DELEGATION ───────────────────────────────────────────────────────
  //
  // We use event delegation on the document so this works for:
  //   - Elements that exist on page load
  //   - Elements added dynamically (e.g. inside modals loaded via Turbo)
  //
  // This is the same pattern used elsewhere in krudmin (bulk-actions.js,
  // inline-edit.js, sweet-confirm.js).

  function bindEvents() {
    document.addEventListener("click", function(event) {
      // "Add" button clicked
      var addButton = event.target.closest("[data-nested-action='add']");
      if (addButton) {
        addRow(event);
        return;
      }

      // "Remove" button clicked
      var removeButton = event.target.closest("[data-nested-action='remove']");
      if (removeButton) {
        removeRow(event);
        return;
      }
    });
  }

  // ─── INITIALIZE ─────────────────────────────────────────────────────────────

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bindEvents);
  } else {
    bindEvents();
  }
})();
