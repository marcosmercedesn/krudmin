/**
 * =============================================================================
 * DATEPICKER STIMULUS CONTROLLER
 * =============================================================================
 *
 * Wraps the daterangepicker jQuery plugin. Initializes on connect,
 * destroys on disconnect.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <!-- Date only: -->
 *   <input data-controller="datepicker"
 *          data-datepicker-time-value="false"
 *          data-date-format="MM/DD/YYYY"
 *          class="form-control datepicker">
 *
 *   <!-- Date + time: -->
 *   <input data-controller="datepicker"
 *          data-datepicker-time-value="true"
 *          class="form-control datetimepicker">
 *
 * =============================================================================
 */

KrudminApp.register("datepicker", class extends Stimulus.Controller {
  static values = {
    time: { type: Boolean, default: false }
  };

  connect() {
    var defaults = {
      singleDatePicker: true,
      showDropdowns: true,
      autoApply: true,
      cancelClass: "btn-danger",
      autoUpdateInput: false
    };

    var format = this.element.dataset.dateFormat ||
      (this.timeValue ? KRUDMIN_OPTIONS.DEFAULT_DATETIME_FORMAT : KRUDMIN_OPTIONS.DEFAULT_DATE_FORMAT);

    var options = Object.assign({}, defaults, {
      locale: { format: format }
    });

    if (this.timeValue) {
      options.timePicker = true;
    }

    var element = this.element;

    $(element).daterangepicker(options, function(inputValue) {
      element.value = inputValue.format(format);
    });

    if (!this.timeValue) {
      $(element).on("apply.daterangepicker", function() {
        $(element).trigger("change");
      });
    }
  }

  disconnect() {
    var picker = $(this.element).data("daterangepicker");
    if (picker) picker.remove();
  }
});
