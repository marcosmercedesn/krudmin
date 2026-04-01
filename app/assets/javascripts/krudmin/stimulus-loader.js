/**
 * =============================================================================
 * KRUDMIN STIMULUS LOADER
 * =============================================================================
 *
 * Initializes the Stimulus application for krudmin. All Stimulus controllers
 * register themselves against `window.KrudminApp` after this file loads.
 *
 * Stimulus is loaded as a UMD build via Sprockets (vendored in
 * vendor/assets/javascripts/stimulus.js). The UMD build exposes the
 * `Stimulus` namespace on `window`, which provides:
 *
 *   - Stimulus.Application
 *   - Stimulus.Controller
 *
 * Each controller file (in krudmin/controllers/) registers itself:
 *
 *   KrudminApp.register("my-controller", class extends Stimulus.Controller {
 *     connect() { ... }
 *   });
 *
 * =============================================================================
 */

window.KrudminApp = Stimulus.Application.start();
