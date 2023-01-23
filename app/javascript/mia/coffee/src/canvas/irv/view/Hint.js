/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from '../../../canvas/common/util/Util';

class Hint {
  static initClass() {
    this.PADDING  = 25;
  }

  constructor(containerEl, model) {
    this.containerEl = containerEl;
    this.model = model;
    this.hintEl = $('tooltip');
    this.visible = false;
  }

  // In this IRV general Hint, we have this 2 methods that calls the same function 'showContent'
  // to deal with the PieCountdown (shared between DCPV and IRV) using the showMessage function, to show its simple tooltip message, 
  // and the irv/RackHint or the dcpv/Hint using the show function to show the devices/racks complex tooltips contents.
  // A main Hint class shared between DCPV and IRV should be considered.

  showMessage(content, x, y) {
    return this.showContent(content, x, y);
  }

  show(content, x, y) {
    return this.showContent(content, x, y);
  }

  showContent(content, x, y) {
    this.visible          = true;
    this.hintEl.innerHTML = content;

    // adjust when near to edges of the screen
    const container_dims = Util.getElementDimensions(this.containerEl);
    const hint_dims      = Util.getElementDimensions(this.hintEl);

    x = (x + hint_dims.width) > container_dims.width ? x - hint_dims.width : x;
    y = (y + hint_dims.height) > container_dims.height ? y - hint_dims.height : y;
    this.x = x;
    this.y = y;

    Util.setStyle(this.hintEl, 'left', x + 'px');
    Util.setStyle(this.hintEl, 'top', y + 'px');
    return Util.setStyle(this.hintEl, 'visibility', 'visible');
  }


  hide() {
    if (this.visible) {
      Util.setStyle(this.hintEl, 'visibility', 'hidden');
      this.hintEl.innerHTML = ' ';
      return this.visible = false;
    }
  }

  refreshPosition() {
    const container_dims = Util.getElementDimensions(this.containerEl);
    const hint_dims      = Util.getElementDimensions(this.hintEl);
  
    this.x = (this.x + hint_dims.width) > container_dims.width ? this.x - ((this.x + hint_dims.width)-container_dims.width) - Hint.PADDING : this.x;
    this.y = (this.y + hint_dims.height) > container_dims.height ? this.y - ((this.y + hint_dims.height)-container_dims.height) - Hint.PADDING : this.y;
  
    Util.setStyle(this.hintEl, 'left', this.x + 'px');
    Util.setStyle(this.hintEl, 'top', this.y + 'px');
    return Util.setStyle(this.hintEl, 'visibility', 'visible');
  }
};
Hint.initClass();
export default Hint;
