(function() {
  "use strict";

  var CSRF_TOKEN_SELECTOR = 'meta[name="csrf-token"]';

  function csrfToken() {
    var meta = document.querySelector(CSRF_TOKEN_SELECTOR);
    return meta ? meta.getAttribute("content") : "";
  }

  function buildUrl(href) {
    var url = new URL(href, window.location.origin);
    url.searchParams.set("remote_modal", "true");
    return url.toString();
  }

  function fetchModal(url) {
    fetch(url, {
      method: "GET",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": csrfToken()
      }
    }).then(function(response) {
      if (response.ok) {
        return response.text().then(function(html) {
          Turbo.renderStreamMessage(html);
        });
      }
    });
  }

  $(document).on("click", "a[data-remote-modal]", function(e) {
    e.preventDefault();

    var href = this.getAttribute("href");
    if (!href || href === "#") return;

    fetchModal(buildUrl(href));
  });
})();
