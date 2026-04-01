/**
 * =============================================================================
 * SELECT2 STIMULUS CONTROLLER
 * =============================================================================
 *
 * Wraps the Select2 jQuery plugin. Automatically initializes on connect and
 * destroys on disconnect (important for Turbo cache).
 *
 * Select2 itself is a jQuery plugin, so jQuery is still required for this
 * controller. The controller manages the lifecycle; Select2 handles the UI.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <select data-controller="select2"
 *           data-select2-remote-value="false"
 *           class="form-control select2">
 *
 *   <!-- Remote search: -->
 *   <select data-controller="select2"
 *           data-select2-remote-value="true"
 *           data-select2-field-value="car_brand_id"
 *           class="form-control select2">
 *
 *   <!-- Tags: -->
 *   <select data-controller="select2"
 *           data-select2-mode-value="tags"
 *           class="form-control taglist">
 *
 *   <!-- Multiple: -->
 *   <select data-controller="select2"
 *           data-select2-mode-value="multiple"
 *           class="form-control" multiple>
 *
 * =============================================================================
 */

KrudminApp.register("select2", class extends Stimulus.Controller {
  static values = {
    remote: { type: Boolean, default: false },
    field: String,
    mode: String  // "tags", "multiple", or blank for standard
  };

  connect() {
    $.fn.select2.defaults.set("theme", "bootstrap");

    if (this.remoteValue) {
      this.initRemote();
    } else if (this.modeValue === "tags") {
      $(this.element).select2({ tags: true, width: "100%" });
    } else if (this.modeValue === "multiple") {
      $(this.element).select2({ multiple: true, width: "100%" });
    } else {
      $(this.element).select2({ width: "100%" });
    }
  }

  disconnect() {
    if ($(this.element).data("select2")) {
      $(this.element).select2("destroy");
    }
  }

  initRemote() {
    var element = this.element;
    var field = this.fieldValue;

    $(element).select2({
      width: "100%",
      ajax: {
        url: window.location,
        dataType: "json",
        delay: 300,
        data: function(params) {
          return {
            search_term: params.term,
            fields: field,
            request_mode: "search",
            format: "json"
          };
        },
        processResults: function(data) {
          var textProperty = data[field].collection_label_field;

          var items = data[field].options.map(function(item) {
            return { id: item.id, text: item[textProperty] };
          });

          return { results: items };
        }
      }
    });
  }
});
