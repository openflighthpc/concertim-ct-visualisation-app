/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Hint from '../../../canvas/irv/view/Hint';
import  Util from '../../../canvas/common/util/Util';

class ThumbHint extends Hint {
  static initClass() {


    this.CAPTION  = '';
  }


  constructor(container_el, model) {
    super(container_el, model);
  }


  show(device, x, y) {
    // find the containing rack
    while (device.parent != null) { device = device.parent; }

    let caption = Util.substitutePhrase(ThumbHint.CAPTION, 'device_name', device.name);
    caption = Util.cleanUpSubstitutions(caption);

    return super.show(caption, x, y);
  }
};
ThumbHint.initClass();
export default ThumbHint;
