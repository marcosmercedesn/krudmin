/**
 * =============================================================================
 * REMOTE MODAL STIMULUS CONTROLLER
 * =============================================================================
 *
 * Loads modal content via fetch and renders it as a Turbo Stream response.
 * Attached to links that should open modals.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <a href="/admin/cars/1/edit"
 *      data-controller="remote-modal"
 *      data-action="click->remote-modal#open">Edit</a>
 *
 * =============================================================================
 */

KrudminApp.register("remote-modal", class extends Stimulus.Controller {
  open(event) {
    event.preventDefault();

    var href = this.element.getAttribute("href");
    if (!href || href === "#") return;

    var url = new URL(href, window.location.origin);
    url.searchParams.set("remote_modal", "true");

    var csrfMeta = document.querySelector('meta[name="csrf-token"]');

    fetch(url.toString(), {
      method: "GET",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": csrfMeta ? csrfMeta.content : ""
      }
    }).then(function(response) {
      if (response.ok) {
        return response.text().then(function(html) {
          Turbo.renderStreamMessage(html);
        });
      }
    });
  }
});
