function initializeTooltipControls() {
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function(el) {
    if (!bootstrap.Tooltip.getInstance(el)) {
      new bootstrap.Tooltip(el);
    }
  });
}
