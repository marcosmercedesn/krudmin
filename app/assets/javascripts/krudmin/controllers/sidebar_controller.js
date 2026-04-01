/**
 * =============================================================================
 * SIDEBAR STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages sidebar visibility toggles (desktop, mobile, brand minimizer)
 * with cookie-based persistence across page loads.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <body data-controller="sidebar">
 *     <button data-action="sidebar#toggle">Toggle</button>
 *     <button data-action="sidebar#toggleMobile">Mobile Toggle</button>
 *     <button data-action="sidebar#minimize">Minimize</button>
 *     <button data-action="sidebar#minimizeBrand">Brand Minimize</button>
 *     <button data-action="sidebar#toggleAside">Aside Toggle</button>
 *   </body>
 *
 * =============================================================================
 */

KrudminApp.register("sidebar", class extends Stimulus.Controller {
  toggle() {
    this.toggleAndPersist("sidebar-hidden");
  }

  minimize() {
    this.toggleAndPersist("sidebar-minimized");
  }

  minimizeBrand() {
    document.body.classList.toggle("brand-minimized");
    Cookies.set("brand-minimized", document.body.classList.contains("brand-minimized"));
  }

  toggleAside() {
    document.body.classList.toggle("aside-menu-hidden");
    this.resizeBroadcast();
  }

  toggleMobile() {
    document.body.classList.toggle("sidebar-mobile-show");
    this.resizeBroadcast();
  }

  closeSidebar() {
    document.body.classList.toggle("sidebar-opened");
    document.body.parentElement.classList.toggle("sidebar-opened");
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  toggleAndPersist(className) {
    document.body.classList.toggle(className);
    Cookies.set(className, document.body.classList.contains(className));
    this.resizeBroadcast();
  }

  resizeBroadcast() {
    var timesRun = 0;
    var interval = setInterval(function() {
      timesRun += 1;
      if (timesRun === 5) clearInterval(interval);
      window.dispatchEvent(new Event("resize"));
    }, 62.5);
  }
});
