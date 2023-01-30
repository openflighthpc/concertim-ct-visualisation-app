/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
class Tooltip {
  constructor() {
    this.connectToolTip();
  }

  connectToolTip() {
    let tip;
    const tooltip_els = $$('.toolTip');

    if ((tooltip_els.length <= 0) || (typeof Tip === 'undefined' || Tip === null)) { return; }
    return tip = new Tips(tooltip_els, {
      onShow(toolTip) {
        return toolTip.tween('opacity', 1);
      },
      
      onHide(toolTip) {
        return toolTip.tween('opacity', 0);
      }
    }
    );
  }
};

export default Tooltip;
