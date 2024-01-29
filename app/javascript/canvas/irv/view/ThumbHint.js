import Hint from 'canvas/irv/view/Hint';
import Util from 'canvas/common/util/Util';

// ThumbHint manages a mouse hover tooltip for the ThumbNav component.
//
// This probably ought to be folded into the ThumbNav class.
class ThumbHint {
    static CAPTION = '';


    constructor(containerEl, model) {
        this.hint = new Hint(containerEl, model);
    }


    show(device, x, y) {
        // find the containing rack
        while (device.parent != null) { device = device.parent; }

        let caption = Util.substitutePhrase(ThumbHint.CAPTION, 'device_name', device.name);
        caption = Util.cleanUpSubstitutions(caption);
        this.hint.showMessage(caption, x, y);
    }

    hide() {
        this.hint.hide();
    }

};

export default ThumbHint;
