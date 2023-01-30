/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from '../../../canvas/common/util/Util';
import  Text from '../../../canvas/irv/view/Text';
import  RackObject from '../../../canvas/irv/view/RackObject';

class Link extends Text {
  static initClass() {
    this.LINK_UNDERLINE_SPACING  = 3;
    this.LINK_UNDERLINE_COLOUR  = '#2B4A6B';
    this.LINK_UNDERLINE_RATIO  = 0.85;
  }

  constructor(conf, parent_object) {
    this.conf = conf;
    this.parent_object = parent_object;
    super(this.conf);
    this.url = this.conf.url;
    this.asset_under_line = null;
    this.width = this.text.length * this.font.size * Link.LINK_UNDERLINE_RATIO;
    if (this.width > this.maxWidth) { this.width = this.maxWidth; }
  }

  parent() {
    return this.parent_object;
  }

  draw() {
    super.draw(...arguments);
    this.y -= (this.height/3);
    return this.height += this.height;
  }

  select() {
    Util.setStyle(this.parent().parentEl, 'cursor', 'pointer');
    return this.asset_under_line = 
      RackObject.INFO_GFX.addLine({
        x       : this.x-(this.width/2),
        y       : this.y+(this.height/3)+Link.LINK_UNDERLINE_SPACING,
        x2      : this.x+(this.width/2),
        y2      : this.y+(this.height/3)+Link.LINK_UNDERLINE_SPACING,
        stroke  : Link.LINK_UNDERLINE_COLOUR
      });
  }

  deselect() {
    Util.setStyle(this.parent().parentEl, 'cursor', 'auto');
    if (this.asset_under_line != null) {
      RackObject.INFO_GFX.remove(this.asset_under_line);
    }
    return this.asset_under_line = null;
  }

  isHighlighted() {
    return (this.asset_under_line != null);
  }
};
Link.initClass();
export default Link;
