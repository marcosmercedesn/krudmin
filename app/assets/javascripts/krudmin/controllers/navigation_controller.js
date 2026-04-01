/**
 * =============================================================================
 * NAVIGATION STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages the sidebar navigation menu: highlights the active link and
 * handles dropdown open/close toggles.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <nav data-controller="navigation">
 *     <ul class="nav" data-navigation-target="menu">
 *       <li><a href="/admin/cars">Cars</a></li>
 *       <li>
 *         <a class="nav-dropdown-toggle" data-action="click->navigation#toggleDropdown">
 *           Settings
 *         </a>
 *         <ul><li>...</li></ul>
 *       </li>
 *     </ul>
 *   </nav>
 *
 * =============================================================================
 */

KrudminApp.register("navigation", class extends Stimulus.Controller {
  static targets = ["menu"];

  connect() {
    if (this.element.classList.contains("initialized")) return;

    this.highlightActiveLink();
    this.element.classList.add("initialized");
  }

  toggleDropdown(event) {
    var link = event.currentTarget;
    if (link.classList.contains("nav-dropdown-toggle")) {
      link.parentElement.classList.toggle("open");
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  highlightActiveLink() {
    var currentUrl = String(window.location).split("?")[0];
    if (currentUrl.charAt(currentUrl.length - 1) === "#") {
      currentUrl = currentUrl.slice(0, -1);
    }

    this.element.querySelectorAll("a").forEach(function(link) {
      if (link.href === currentUrl) {
        link.classList.add("active");

        // Open parent dropdowns
        var parent = link.parentElement;
        while (parent && parent !== this.element) {
          if (parent.tagName === "LI" || parent.tagName === "UL") {
            parent.classList.add("open");
          }
          parent = parent.parentElement;
        }
      }
    }.bind(this));
  }
});
