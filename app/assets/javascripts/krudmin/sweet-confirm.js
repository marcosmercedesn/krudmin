// Turbo-compatible SweetAlert confirmation
// Uses Turbo.setConfirmMethod to integrate SweetAlert with Turbo's native confirmation system.
// Views should use data-turbo-confirm="message" instead of data-sweet-confirm="message".

(function() {
  if (typeof Turbo !== "undefined" && Turbo.setConfirmMethod) {
    Turbo.setConfirmMethod(function(message, element) {
      return new Promise(function(resolve) {
        var icon = (element && element.dataset.confirmIcon) || "warning";
        var title = (element && element.dataset.title) || "Confirm";
        var className = "sweet-" + ((element && element.dataset.confirmClass) || "warning");

        swal({
          title: title,
          text: message,
          icon: icon,
          className: className,
          buttons: true
        }).then(function(result) {
          resolve(result);
        });
      });
    });
  }
})();
