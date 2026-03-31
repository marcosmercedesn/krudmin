(function() {
  "use strict";

  var CSRF_TOKEN_SELECTOR = 'meta[name="csrf-token"]';

  function csrfToken() {
    var meta = document.querySelector(CSRF_TOKEN_SELECTOR);
    return meta ? meta.getAttribute("content") : "";
  }

  function buildInput(td) {
    var fieldType = td.dataset.fieldType;
    var fieldValue = td.dataset.fieldValue || "";
    var fieldOptions = td.dataset.fieldOptions;

    if (fieldType === "boolean" || fieldType === "enum_type" || fieldType === "belongs_to") {
      return buildSelect(fieldValue, fieldOptions);
    }

    if (fieldType === "date") {
      return buildDateInput(fieldValue);
    }

    if (fieldType === "date_time") {
      return buildDateTimeInput(fieldValue);
    }

    if (fieldType === "number" || fieldType === "decimal" || fieldType === "currency") {
      return buildNumberInput(fieldValue);
    }

    return buildTextInput(fieldValue);
  }

  function buildTextInput(value) {
    var input = document.createElement("input");
    input.type = "text";
    input.className = "form-control form-control-sm inline-edit-input";
    input.value = value;
    return input;
  }

  function buildNumberInput(value) {
    var input = document.createElement("input");
    input.type = "number";
    input.className = "form-control form-control-sm inline-edit-input";
    input.value = value;
    input.step = "any";
    return input;
  }

  function buildDateInput(value) {
    var input = document.createElement("input");
    input.type = "date";
    input.className = "form-control form-control-sm inline-edit-input";
    if (value) {
      var date = new Date(value);
      if (!isNaN(date.getTime())) {
        input.value = date.toISOString().split("T")[0];
      }
    }
    return input;
  }

  function buildDateTimeInput(value) {
    var input = document.createElement("input");
    input.type = "datetime-local";
    input.className = "form-control form-control-sm inline-edit-input";
    if (value) {
      var date = new Date(value);
      if (!isNaN(date.getTime())) {
        input.value = date.toISOString().slice(0, 16);
      }
    }
    return input;
  }

  function buildSelect(value, optionsJSON) {
    var select = document.createElement("select");
    select.className = "form-control form-control-sm inline-edit-input";

    var blank = document.createElement("option");
    blank.value = "";
    blank.textContent = "";
    select.appendChild(blank);

    try {
      var options = JSON.parse(optionsJSON || "[]");
      options.forEach(function(opt) {
        var option = document.createElement("option");
        option.value = opt.value;
        option.textContent = opt.label;
        if (String(opt.value) === String(value)) {
          option.selected = true;
        }
        select.appendChild(option);
      });
    } catch (e) {
      // ignore parse errors
    }

    return select;
  }

  function buildActions() {
    var wrapper = document.createElement("span");
    wrapper.className = "inline-edit-actions";

    var saveBtn = document.createElement("button");
    saveBtn.type = "button";
    saveBtn.className = "btn btn-sm btn-success inline-edit-save";
    saveBtn.innerHTML = '<i class="fa fa-check"></i>';
    saveBtn.title = "Save";

    var cancelBtn = document.createElement("button");
    cancelBtn.type = "button";
    cancelBtn.className = "btn btn-sm btn-secondary inline-edit-cancel";
    cancelBtn.innerHTML = '<i class="fa fa-times"></i>';
    cancelBtn.title = "Cancel";

    wrapper.appendChild(saveBtn);
    wrapper.appendChild(cancelBtn);

    return wrapper;
  }

  function startEditing(td) {
    if (td.classList.contains("editing")) return;

    td.classList.add("editing");
    td._originalHTML = td.innerHTML;

    var form = document.createElement("div");
    form.className = "inline-edit-form";

    var input = buildInput(td);
    var actions = buildActions();

    form.appendChild(input);
    form.appendChild(actions);

    td.innerHTML = "";
    td.appendChild(form);

    input.focus();
    if (input.select) input.select();

    input.addEventListener("keydown", function(e) {
      if (e.key === "Enter") {
        e.preventDefault();
        saveEdit(td, input);
      } else if (e.key === "Escape") {
        e.preventDefault();
        cancelEdit(td);
      }
    });

    form.querySelector(".inline-edit-save").addEventListener("click", function(e) {
      e.stopPropagation();
      saveEdit(td, input);
    });

    form.querySelector(".inline-edit-cancel").addEventListener("click", function(e) {
      e.stopPropagation();
      cancelEdit(td);
    });
  }

  function cancelEdit(td) {
    if (td._originalHTML !== undefined) {
      td.innerHTML = td._originalHTML;
      delete td._originalHTML;
    }
    td.classList.remove("editing");
  }

  function saveEdit(td, input) {
    var url = td.dataset.updateUrl;
    var modelKey = td.dataset.modelKey;
    var attribute = td.dataset.attribute;
    var value = input.value;

    var body = new FormData();
    body.append(modelKey + "[" + attribute + "]", value);
    body.append("inline_edit", "true");

    td.classList.add("saving");

    fetch(url, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": csrfToken()
      },
      body: body
    }).then(function(response) {
      return response.text().then(function(html) {
        if (response.ok) {
          Turbo.renderStreamMessage(html);
        } else {
          cancelEdit(td);
          Turbo.renderStreamMessage(html);
        }
      });
    }).catch(function() {
      cancelEdit(td);
    }).finally(function() {
      td.classList.remove("saving");
    });
  }

  $(document).on("click", "td[data-inline-edit]", function(e) {
    if ($(e.target).closest("a, button, .inline-edit-form").length) return;

    startEditing(this);
  });
})();
