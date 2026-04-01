/**
 * =============================================================================
 * BULK ACTIONS STIMULUS CONTROLLER
 * =============================================================================
 *
 * Manages bulk selection checkboxes and batch action submission (destroy,
 * activate, deactivate) on the index page.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <div data-controller="bulk-actions">
 *     <input type="checkbox" data-action="bulk-actions#selectAll"
 *            data-bulk-actions-target="selectAll">
 *     <input type="checkbox" data-action="bulk-actions#selectItem"
 *            data-bulk-actions-target="item" value="123">
 *     <div data-bulk-actions-target="bar" class="d-none">
 *       <span data-bulk-actions-target="count"></span>
 *       <button data-action="bulk-actions#perform"
 *               data-url="/admin/cars/bulk_destroy"
 *               data-confirm="Are you sure?">Destroy</button>
 *     </div>
 *   </div>
 *
 * =============================================================================
 */

KrudminApp.register("bulk-actions", class extends Stimulus.Controller {
  static targets = ["selectAll", "item", "bar", "count"];

  connect() {
    this._turboHandler = this.clearSelections.bind(this);
    document.addEventListener("turbo:before-stream-render", this._turboHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this._turboHandler);
  }

  selectAll(event) {
    var checked = event.target.checked;
    this.itemTargets.forEach(function(checkbox) {
      checkbox.checked = checked;
    });
    this.updateBar();
  }

  selectItem() {
    this.updateBar();
  }

  perform(event) {
    event.preventDefault();

    var button = event.currentTarget;
    var url = button.dataset.url;
    var confirmMessage = button.dataset.confirm;
    var confirmIcon = button.dataset.confirmIcon || "warning";
    var ids = this.selectedIds;

    if (ids.length === 0) return;

    var self = this;

    function doSubmit() {
      self.submitForm(url, ids);
    }

    if (confirmMessage && typeof swal !== "undefined") {
      swal({
        title: confirmMessage,
        icon: confirmIcon,
        buttons: true,
        dangerMode: confirmIcon === "warning"
      }).then(function(confirmed) {
        if (confirmed) doSubmit();
      });
    } else if (confirmMessage) {
      if (confirm(confirmMessage)) doSubmit();
    } else {
      doSubmit();
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  get selectedIds() {
    var ids = [];
    this.itemTargets.forEach(function(cb) {
      if (cb.checked) ids.push(cb.value);
    });
    return ids;
  }

  updateBar() {
    var ids = this.selectedIds;
    var allItems = this.itemTargets;

    if (this.hasBarTarget) {
      if (ids.length > 0) {
        this.barTarget.classList.remove("d-none");
      } else {
        this.barTarget.classList.add("d-none");
      }
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = ids.length;
    }

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = allItems.length > 0 && ids.length === allItems.length;
      this.selectAllTarget.indeterminate = ids.length > 0 && ids.length < allItems.length;
    }
  }

  submitForm(url, ids) {
    var form = document.createElement("form");
    form.method = "POST";
    form.action = url;
    form.style.display = "none";
    form.setAttribute("data-turbo", "true");

    var csrfToken = document.querySelector("meta[name='csrf-token']");
    if (csrfToken) {
      var tokenInput = document.createElement("input");
      tokenInput.type = "hidden";
      tokenInput.name = "authenticity_token";
      tokenInput.value = csrfToken.content;
      form.appendChild(tokenInput);
    }

    ids.forEach(function(id) {
      var input = document.createElement("input");
      input.type = "hidden";
      input.name = "ids[]";
      input.value = id;
      form.appendChild(input);
    });

    document.body.appendChild(form);
    form.requestSubmit();
  }

  clearSelections() {
    var self = this;
    setTimeout(function() {
      self.itemTargets.forEach(function(cb) { cb.checked = false; });
      if (self.hasSelectAllTarget) self.selectAllTarget.checked = false;
      self.updateBar();
    }, 100);
  }
});
