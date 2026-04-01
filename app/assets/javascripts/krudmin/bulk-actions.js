(function() {
  function getBar() {
    return document.querySelector("[data-bulk-actions-bar]");
  }

  function getSelectedIds() {
    var checkboxes = document.querySelectorAll("[data-bulk-select='item']:checked");
    var ids = [];
    for (var i = 0; i < checkboxes.length; i++) {
      ids.push(checkboxes[i].value);
    }
    return ids;
  }

  function updateBar() {
    var bar = getBar();
    if (!bar) return;

    var ids = getSelectedIds();
    var countEl = bar.querySelector("[data-bulk-count]");

    if (ids.length > 0) {
      bar.classList.remove("d-none");
      if (countEl) countEl.textContent = ids.length;
    } else {
      bar.classList.add("d-none");
    }

    var selectAll = document.querySelector("[data-bulk-select='all']");
    if (selectAll) {
      var allItems = document.querySelectorAll("[data-bulk-select='item']");
      selectAll.checked = allItems.length > 0 && ids.length === allItems.length;
      selectAll.indeterminate = ids.length > 0 && ids.length < allItems.length;
    }
  }

  function handleSelectAll(e) {
    var checked = e.target.checked;
    var checkboxes = document.querySelectorAll("[data-bulk-select='item']");
    for (var i = 0; i < checkboxes.length; i++) {
      checkboxes[i].checked = checked;
    }
    updateBar();
  }

  function handleItemSelect() {
    updateBar();
  }

  function submitBulkAction(url, confirmMessage, confirmIcon, confirmClass) {
    var ids = getSelectedIds();
    if (ids.length === 0) return;

    function doSubmit() {
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

      for (var i = 0; i < ids.length; i++) {
        var input = document.createElement("input");
        input.type = "hidden";
        input.name = "ids[]";
        input.value = ids[i];
        form.appendChild(input);
      }

      document.body.appendChild(form);
      form.requestSubmit();
    }

    if (confirmMessage && typeof swal !== "undefined") {
      swal({
        title: confirmMessage,
        icon: confirmIcon || "warning",
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

  function handleBulkActionClick(e) {
    var button = e.target.closest("[data-bulk-action]");
    if (!button) return;

    e.preventDefault();
    var url = button.getAttribute("data-bulk-url");
    var confirmMessage = button.getAttribute("data-turbo-confirm");
    var confirmIcon = button.getAttribute("data-confirm-icon");
    var confirmClass = button.getAttribute("data-confirm-class");

    // Remove turbo-confirm so Turbo doesn't also trigger it
    button.removeAttribute("data-turbo-confirm");
    submitBulkAction(url, confirmMessage, confirmIcon, confirmClass);
    button.setAttribute("data-turbo-confirm", confirmMessage);
  }

  function clearSelections() {
    var checkboxes = document.querySelectorAll("[data-bulk-select='item'], [data-bulk-select='all']");
    for (var i = 0; i < checkboxes.length; i++) {
      checkboxes[i].checked = false;
    }
    updateBar();
  }

  function bindEvents() {
    document.addEventListener("change", function(e) {
      if (e.target.matches("[data-bulk-select='all']")) {
        handleSelectAll(e);
      } else if (e.target.matches("[data-bulk-select='item']")) {
        handleItemSelect();
      }
    });

    document.addEventListener("click", function(e) {
      if (e.target.closest("[data-bulk-action]")) {
        handleBulkActionClick(e);
      }
    });

    document.addEventListener("turbo:before-stream-render", function() {
      // Clear selections after any turbo stream update
      setTimeout(clearSelections, 100);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bindEvents);
  } else {
    bindEvents();
  }
})();
