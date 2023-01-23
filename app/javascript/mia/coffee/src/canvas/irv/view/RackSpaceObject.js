/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from '../../../canvas/common/util/Util';
import Easing from '../../../canvas/common/gfx/Easing';

// super class to RackObject HoldingArea
class RackSpaceObject {
  static initClass() {
    this.SPACE_ALPHA          = .3;
    this.SPACE_FADE_DURATION  = 500;
    this.SPACE_FILL           = '#ff00ff';
  }

  constructor() {
    this.highlights      = [];
  }

  hideSpaces() {
    if (this.highlights.length > 0) {
      for (var oneHighlight of Array.from(this.highlights)) { this.infoLayer().animate(oneHighlight, { alpha: 0 }, RackSpaceObject.SPACE_FADE_DURATION, Easing.Cubic.easeOut, this.evSpaceHidden); }
    }
    this.highlights = [];
    return this.fadeInMetrics();
  }

  createFreeSpaceHighlight(x,y,width,height) {
    const highlight = this.infoLayer().addRect({
      x,
      y,
      width,
      height,
      fill   : RackSpaceObject.SPACE_FILL,
      alpha  : 0
    });
    this.infoLayer().animate(highlight, { alpha: RackSpaceObject.SPACE_ALPHA }, RackSpaceObject.SPACE_FADE_DURATION, Easing.Cubic.easeOut);
    return this.highlights.push(highlight);
  }

  getDeviceAt(x, y) {
    // search children in reverse order, this give presidence to children drawn last (topmost)
    if (this.imageLink && (y > this.imageLink.y) && (y < (this.imageLink.y + this.imageLink.height)) && (x > this.imageLink.x) && (x < (this.imageLink.x + this.imageLink.width))) {
      return this.imageLink;
    }
  
    let count = this.children.length;
    while (count > 0) {
      --count;
      var child = this.children[count];
      if ((y > child.y) && (y < (child.y + child.height)) && (x > child.x) && (x < (child.x + child.width)) && child.visible) {
        var subchild = child.getDeviceAt(x, y);
        if (subchild != null) { return subchild; } else { return child; }
      }
    }

    return null;
  }
};
RackSpaceObject.initClass();
export default RackSpaceObject;
