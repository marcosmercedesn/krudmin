// Custom Turbo Stream actions for Krudmin
// These extend Turbo Streams with actions needed for admin UI interactions.

(function () {
  if (typeof Turbo === "undefined" || !Turbo.StreamActions) return;

  // <turbo-stream action="toast" type="success" message="Record created">
  Turbo.StreamActions.toast = function () {
    var type = this.getAttribute("type") || "info";
    var message = this.getAttribute("message");
    var position = this.getAttribute("position") || "toast-top-right";

    if (message && typeof displayToast === "function") {
      displayToast(type, message, position);
    }
  };

  // <turbo-stream action="highlight" target="item-model-123">
  Turbo.StreamActions.highlight = function () {
    var targetId = this.getAttribute("target");
    var selector = targetId.startsWith(".") ? targetId : "#" + targetId;

    if (typeof blinkHighlight === "function") {
      blinkHighlight(selector);
    }
  };

  // <turbo-stream action="modal" target="crudFormModal" event="show">
  Turbo.StreamActions.modal = function () {
    var targetId = this.getAttribute("target");
    var eventType = this.getAttribute("event") || "show";
    var modalEl = document.getElementById(targetId);

    if (!modalEl) return;

    var modalInstance = bootstrap.Modal.getOrCreateInstance(modalEl);

    if (eventType === "hide") {
      modalInstance.hide();
    } else if (eventType === "show") {
      modalInstance.show();
    }
  };

  // <turbo-stream action="scroll_to_top">
  Turbo.StreamActions.scroll_to_top = function () {
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // <turbo-stream action="dispatch_event" event="updateBelongsToLookups" detail="{}">
  Turbo.StreamActions.dispatch_event = function () {
    var eventName = this.getAttribute("event");
    var detail = this.getAttribute("detail");

    if (eventName) {
      var parsedDetail = detail ? JSON.parse(detail) : {};
      var event = new CustomEvent(eventName, { detail: parsedDetail });
      document.dispatchEvent(event);
    }
  };

  // Turbo Stream custom action for initializing controls
  Turbo.StreamActions.init_controls = function () {

  };
})();
