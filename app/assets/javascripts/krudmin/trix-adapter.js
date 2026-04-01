/**
 * =============================================================================
 * KRUDMIN TRIX ADAPTER
 * =============================================================================
 *
 * Handles initialization and cleanup for Trix rich text editors within krudmin.
 *
 * ─── WHY THIS EXISTS ────────────────────────────────────────────────────────
 *
 * Trix editors are web components (<trix-editor>) that auto-initialize when
 * inserted into the DOM. However, when new editors are added dynamically
 * (e.g., inside nested HasMany rows or Turbo Stream updates), we need to
 * ensure they attach to their hidden inputs correctly.
 *
 * This adapter also disables Trix's default file attachment behavior, since
 * krudmin's RichText field stores HTML in a plain text column — there's no
 * Active Storage backend to handle file uploads.
 *
 * ─── EVENTS ─────────────────────────────────────────────────────────────────
 *
 * Listens for:
 *   - "trix-file-accept" → prevents file attachments (drag-and-drop / paste)
 *   - "krudmin:updateControls" → no-op for Trix (auto-initializes), but kept
 *     for consistency with the adapter pattern used by Select2/datepickers
 *
 * =============================================================================
 */

(function() {
  "use strict";

  // ─── DISABLE FILE ATTACHMENTS ─────────────────────────────────────────────
  //
  // Trix supports drag-and-drop file attachments out of the box, but that
  // requires Active Storage (or a custom upload backend) to work properly.
  // Since krudmin stores RichText as plain HTML in a text column, we prevent
  // file attachments entirely to avoid broken image placeholders.
  //
  // If you need file attachments in the future, remove this listener and
  // set up an Active Storage integration.

  document.addEventListener("trix-file-accept", function(event) {
    event.preventDefault();
  });

})();
