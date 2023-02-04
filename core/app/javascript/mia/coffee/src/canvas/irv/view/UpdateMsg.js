/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Events from 'canvas/common/util/Events';

class UpdateMsg {
  static initClass() {
    // statics overwritten by config
    this.MESSAGE  = 'Updating...';
  }


  // msg_element is masked off and has the message added, mask_elements
  // is an array of other elements to maks off (without message)
  constructor(msgElement, maskElements) {
    this.muteEvent = this.muteEvent.bind(this);
    this.msgElement = msgElement;
    this.maskElements = maskElements;
    this.maskList = [];
  }


  show() {
    if (this.visible) { return; }

    this.visible  = true;

    let el            = this.addMask(this.msgElement);
    const msg           = document.createElement('div');
    msg.innerHTML = UpdateMsg.MESSAGE;
    msg.setAttribute('id', 'updater_msg');
    el.appendChild(msg);

    return (() => {
      const result = [];
      for (el of Array.from(this.maskElements)) {             result.push(this.addMask(el));
      }
      return result;
    })();
  }
  

  hide() {
    if (!this.visible) { return; }

    this.visible = false;
    for (var el of Array.from(this.maskList)) { el.parentElement.removeChild(el); }
    return this.maskList = [];
  }


  addMask(container_el) {
    const el = document.createElement('div');
    el.setAttribute('class', 'updater_mask');
    Events.addEventListener(el, 'click', this.muteEvent);
    Events.addEventListener(el, 'contextmenu', this.muteEvent);
    Events.addEventListener(el, 'dblclick', this.muteEvent);
    container_el.appendChild(el);
    this.maskList.push(el);
    return el;
  }


  muteEvent(ev) {
    ev.stopPropagation();
    return ev.preventDefault();
  }
};
UpdateMsg.initClass();
export default UpdateMsg;
