/**
 * =============================================================================
 * INLINE EDIT STIMULUS CONTROLLER
 * =============================================================================
 *
 * Turns table cells into editable fields on click. Saves via PATCH request
 * and renders the Turbo Stream response from the server.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   <td data-controller="inline-edit"
 *       data-inline-edit-url-value="/admin/cars/1"
 *       data-inline-edit-model-key-value="car"
 *       data-inline-edit-attribute-value="model"
 *       data-inline-edit-field-type-value="string"
 *       data-inline-edit-field-value-value="Camry"
 *       data-inline-edit-field-options-value='[...]'
 *       data-action="click->inline-edit#edit">
 *     <span class="inline-display">Camry</span>
 *   </td>
 *
 * =============================================================================
 */

KrudminApp.register("inline-edit", class extends Stimulus.Controller {
  static values = {
    url: String,
    modelKey: String,
    attribute: String,
    fieldType: String,
    fieldValue: String,
    fieldOptions: String
  };

  edit(event) {
    if (event.target.closest("a, button, .inline-edit-form")) return;
    if (this.element.classList.contains("editing")) return;

    this.element.classList.add("editing");
    this._originalHTML = this.element.innerHTML;

    var form = document.createElement("div");
    form.className = "inline-edit-form";

    var input = this.buildInput();
    var actions = this.buildActions();

    form.appendChild(input);
    form.appendChild(actions);

    this.element.innerHTML = "";
    this.element.appendChild(form);

    input.focus();
    if (input.select) input.select();

    var self = this;

    input.addEventListener("keydown", function(e) {
      if (e.key === "Enter") { e.preventDefault(); self.save(input); }
      else if (e.key === "Escape") { e.preventDefault(); self.cancel(); }
    });

    form.querySelector(".inline-edit-save").addEventListener("click", function(e) {
      e.stopPropagation();
      self.save(input);
    });

    form.querySelector(".inline-edit-cancel").addEventListener("click", function(e) {
      e.stopPropagation();
      self.cancel();
    });
  }

  cancel() {
    if (this._originalHTML !== undefined) {
      this.element.innerHTML = this._originalHTML;
      delete this._originalHTML;
    }
    this.element.classList.remove("editing");
  }

  save(input) {
    var self = this;
    var body = new FormData();
    body.append(this.modelKeyValue + "[" + this.attributeValue + "]", input.value);
    body.append("inline_edit", "true");

    this.element.classList.add("saving");

    var csrfMeta = document.querySelector('meta[name="csrf-token"]');

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": csrfMeta ? csrfMeta.content : ""
      },
      body: body
    }).then(function(response) {
      return response.text().then(function(html) {
        if (response.ok) {
          Turbo.renderStreamMessage(html);
        } else {
          self.cancel();
          Turbo.renderStreamMessage(html);
        }
      });
    }).catch(function() {
      self.cancel();
    }).finally(function() {
      self.element.classList.remove("saving");
    });
  }

  // ─── Input builders ─────────────────────────────────────────────────────────

  buildInput() {
    var type = this.fieldTypeValue;
    var value = this.fieldValueValue || "";
    var options = this.fieldOptionsValue;

    if (type === "boolean" || type === "enum_type" || type === "belongs_to") {
      return this.buildSelect(value, options);
    }
    if (type === "date") return this.buildDateInput(value);
    if (type === "date_time") return this.buildDateTimeInput(value);
    if (type === "number" || type === "decimal" || type === "currency") {
      return this.buildNumberInput(value);
    }
    return this.buildTextInput(value);
  }

  buildTextInput(value) {
    var input = document.createElement("input");
    input.type = "text";
    input.className = "form-control form-control-sm inline-edit-input";
    input.value = value;
    return input;
  }

  buildNumberInput(value) {
    var input = document.createElement("input");
    input.type = "number";
    input.className = "form-control form-control-sm inline-edit-input";
    input.value = value;
    input.step = "any";
    return input;
  }

  buildDateInput(value) {
    var input = document.createElement("input");
    input.type = "date";
    input.className = "form-control form-control-sm inline-edit-input";
    if (value) {
      var date = new Date(value);
      if (!isNaN(date.getTime())) input.value = date.toISOString().split("T")[0];
    }
    return input;
  }

  buildDateTimeInput(value) {
    var input = document.createElement("input");
    input.type = "datetime-local";
    input.className = "form-control form-control-sm inline-edit-input";
    if (value) {
      var date = new Date(value);
      if (!isNaN(date.getTime())) input.value = date.toISOString().slice(0, 16);
    }
    return input;
  }

  buildSelect(value, optionsJSON) {
    var select = document.createElement("select");
    select.className = "form-control form-control-sm inline-edit-input";

    var blank = document.createElement("option");
    blank.value = "";
    select.appendChild(blank);

    try {
      var options = JSON.parse(optionsJSON || "[]");
      options.forEach(function(opt) {
        var option = document.createElement("option");
        option.value = opt.value;
        option.textContent = opt.label;
        if (String(opt.value) === String(value)) option.selected = true;
        select.appendChild(option);
      });
    } catch (e) { /* ignore */ }

    return select;
  }

  buildActions() {
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
});
