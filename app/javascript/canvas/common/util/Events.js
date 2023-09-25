/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

// Cross browser event handling. Each method is re-written during initial invokation
// to avoid re-evaluating feature detection
class Events {

  static addEventListener(element, event, listener, use_capture) {
    if (use_capture == null) { use_capture = false; }
    if (element.addEventListener) {
      this.addEventListener = function(element, event, listener, use_capture) {
        if (use_capture == null) { use_capture = false; }
        return element.addEventListener(event, listener, use_capture);
      };
    } else {
      this.addEventListener = function(element, event, listener, use_capture) {
        if (use_capture == null) { use_capture = false; }
        return element.attachEvent('on' + event, listener);
      };
    }

    return this.addEventListener(element, event, listener, use_capture);
  }


  static removeEventListener(element, event, listener, use_capture) {
    if (use_capture == null) { use_capture = false; }
    if (element.removeEventListener) {
      this.removeEventListener = function(element, event, listener, use_capture) {
        if (use_capture == null) { use_capture = false; }
        return element.removeEventListener(event, listener, use_capture);
      };
    } else {
      this.removeEventListener = function(element, event, listener, use_capture) {
        if (use_capture == null) { use_capture = false; }
        return element.detachEvent('on' + event, listener);
      };
    }

    return this.removeEventListener(element, event, listener, use_capture);
  }


  static dispatchEvent(element, event, data) {
    if (element.addEventListener) {
      this.dispatchEvent = function(element, event, data) {
        const ev      = document.createEvent('HTMLEvents');
        ev.data = data;
        ev.initEvent(event, true, true);
        return element.dispatchEvent(ev);
      };
    } else {
      this.dispatchEvent = function(element, event, data) {
        const ev      = document.createEventObject();
        ev.data = data;
        return element.fireEvent('on' + event, ev);
      };
    }

    return this.dispatchEvent(element, event, data);
  }
};

export default Events;
