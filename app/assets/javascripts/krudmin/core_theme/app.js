/**
 * =============================================================================
 * KRUDMIN APP — GLOBAL UTILITIES
 * =============================================================================
 *
 * This file contains global utility functions and configuration that don't
 * belong to a specific Stimulus controller:
 *
 *   - displayToast / clearToasts — used by turbo-stream-actions.js
 *   - blinkHighlight — used by turbo-stream-actions.js
 *   - Bootstrap tooltip/popover initialization
 *   - Toastr configuration
 *   - updateBelongsToLookups event handler (for Turbo Stream responses)
 *
 * All interactive behavior (sidebar toggles, navigation, card collapse,
 * search panel, etc.) lives in Stimulus controllers under
 * krudmin/controllers/.
 *
 * =============================================================================
 */

("use strict");

// ─── TOAST CONFIGURATION ──────────────────────────────────────────────────────

toastr.options = {
  closeButton: true,
  newestOnTop: true,
  preventDuplicates: true,
  timeOut: 3000,
  closeDuration: 100,
  positionClass: "toast-top-center"
};

function displayToast(type, msg, position) {
  var positionClass = position || "toast-top-center";

  switch (type) {
    case "error":
      toastr.error(msg, "", { timeOut: 5000, positionClass: positionClass });
      break;
    case "warning":
      toastr.warning(msg, "", { positionClass: positionClass });
      break;
    case "success":
      toastr.success(msg, "", { positionClass: positionClass });
      break;
    default:
      toastr.info(msg, "", { positionClass: positionClass });
      break;
  }
}

function clearToasts() {
  var container = document.getElementById("toast-container");
  if (container) container.innerHTML = "";
}

// ─── HIGHLIGHT ANIMATION ──────────────────────────────────────────────────────

function blinkHighlight(el, from, to) {
  if (!from) from = 0.5;
  if (!to) to = 1.0;

  $(el).fadeTo(100, from).fadeTo(200, to);
}

// ─── BOOTSTRAP POPOVER / TOOLTIP INIT ─────────────────────────────────────────
// These are for elements not covered by the tooltip Stimulus controller
// (e.g., elements with rel="tooltip" or rel="popover")

document.addEventListener("turbo:load", function () {
  document.querySelectorAll('[rel="tooltip"],[data-rel="tooltip"]').forEach(function (el) {
    if (!bootstrap.Tooltip.getInstance(el)) {
      new bootstrap.Tooltip(el, { placement: "bottom", delay: { show: 400, hide: 200 } });
    }
  });

  document.querySelectorAll('[rel="popover"],[data-rel="popover"],[data-bs-toggle="popover"]').forEach(function (el) {
    if (!bootstrap.Popover.getInstance(el)) {
      new bootstrap.Popover(el);
    }
  });

  // Disable moving to top for bare # links
  document.querySelectorAll('a[href="#"]:not([data-top="true"])').forEach(function (el) {
    el.addEventListener("click", function (e) { e.preventDefault(); });
  });
});

// ─── BELONGS TO LOOKUP UPDATES ────────────────────────────────────────────────
// This handler is triggered by turbo-stream-actions.js dispatch_event action
// when a modal form creates a new associated record. It refreshes the
// dropdown options for BelongsTo selects.

document.addEventListener("updateBelongsToLookups", function (e) {
  var model_element = e.detail.model_element;
  var relations = e.detail.relations;
  var _model_id = e.detail.model_id;

  var _field_names = relations.map(function () {
    return model_element + "_id";
  });

  $.get(window.location, { format: "json", fields: _field_names, search_id: _model_id }).done(function (_data) {
    var data = _data;
    var field_names = _field_names;

    field_names.forEach(function (field_name, index) {
      var formSelector = "form[data-model-element='" + relations[index] + "']";
      var targetForm = document.querySelector(formSelector);
      if (!targetForm) return;

      var model_element_name = targetForm.dataset.modelElement;
      var field_id = "#" + model_element_name + "_" + field_name;
      var targetLookup = targetForm.querySelector(field_id);
      if (!targetLookup) return;

      var field_data = data[field_name];
      var items = field_data.options;
      var label_field = field_data.collection_label_field;

      // Clear and rebuild options
      targetLookup.innerHTML = "";
      items.forEach(function (item) {
        var option = document.createElement("option");
        option.value = item.id;
        option.text = item[label_field];
        targetLookup.appendChild(option);
      });

      targetLookup.value = _model_id;
      $(targetLookup).trigger("change"); // Trigger Select2 update
    });
  });
}, false);

function toggleKrudminSearchPanel(event) {
  event.preventDefault();

  var searchPanel = document.querySelector(".search-panel");
  if (searchPanel) {
    $(searchPanel).slideToggle("fast");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}
