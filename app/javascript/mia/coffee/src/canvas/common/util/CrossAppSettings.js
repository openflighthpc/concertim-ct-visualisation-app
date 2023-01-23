/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

class CrossAppSettings {
  static initClass() {
    // statics overwritten by config
    this.LIFESPAN_MINS  = 20000;

    // constants and run-time assigned statics
    this.COOKIE_NAME  = 'shared_settings';
  }


  static set(namespace, settings_obj) {
    const settings        = JSON.stringify(settings_obj);
    return window.localStorage.setItem(namespace, settings);
  }
    //expiration      = new Date((new Date()).getTime() + (CrossAppSettings.LIFESPAN_MINS * 60 * 1000))
    //cookie_str      = escape(settings) + '; expires=' + expiration.toUTCString()
    //document.cookie = CrossAppSettings.COOKIE_NAME + "=" + cookie_str
    //console.log settings, expiration


  static get(namespace) {
    const val = JSON.parse(window.localStorage.getItem(namespace));
    if (val != null) { return val; } else { return {}; }
    const cookie_str = document.cookie;
    let start_idx  = cookie_str.indexOf(' ' + CrossAppSettings.COOKIE_NAME + '=');
    if (start_idx === -1) { start_idx  = cookie_str.indexOf(CrossAppSettings.COOKIE_NAME + '='); }

    if (start_idx === -1) { return {}; }

    start_idx = cookie_str.indexOf('=', start_idx) + 1;
    let end_idx   = cookie_str.indexOf(';',start_idx);
    if (end_idx === -1) { end_idx   = cookie_str.length; }

    return JSON.parse(unescape(cookie_str.substring(start_idx, end_idx)));
  }


  static clear(namespace) {
    window.localStorage.clear(namespace);
    return;
    const cookie_str = document.cookie;
    return document.cookie = CrossAppSettings.COOKIE_NAME + "=deleted; expires=" + new Date(0).toUTCString();
  }
};
CrossAppSettings.initClass();
export default CrossAppSettings;
