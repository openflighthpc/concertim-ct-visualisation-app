import Util from 'canvas/common/util/Util';

// Hint manages a hint or tooltip DOM element.  When the IRV wants to display a
// hint or tooltip the same DOM element is used.  The assumption is that only a
// single tooltip should ever be shown.
//
// This class manages showing the given message at the given coordinates and
// hiding the message.
class Hint {
  constructor(containerEl, model) {
    this.containerEl = containerEl;
    this.model = model;
    this.hintEl = $('tooltip');
    this.visible = false;
  }

  // showMessage displays the given content at the given coordinates. 
  showMessage(content, x, y) {
    this.visible          = true;
    this.hintEl.innerHTML = content;

    // adjust when near to edges of the screen
    const containerDims = Util.getElementDimensions(this.containerEl);
    const hintDims      = Util.getElementDimensions(this.hintEl);
    x = (x + hintDims.width) > containerDims.width ? x - hintDims.width : x;
    x = x < 0 ? 0 : x;
    y = (y + hintDims.height) > containerDims.height ? y - hintDims.height : y;
    y = y < 0 ? 0 : y;
    let position = 'absolute';

    const containerIsAncestor = Util.isAncestor(this.hintEl, this.containerEl);
    if (!containerIsAncestor) {
      const containerPos = this.containerEl.getCoordinates();
      x = x + containerPos.left;
      y = y + containerPos.top;
      position = 'fixed';
    }

    Util.setStyle(this.hintEl, 'position', position);
    Util.setStyle(this.hintEl, 'left', x + 'px');
    Util.setStyle(this.hintEl, 'top', y + 'px');
    Util.setStyle(this.hintEl, 'visibility', 'visible');
  }


  hide() {
    if (this.visible) {
      Util.setStyle(this.hintEl, 'visibility', 'hidden');
      this.hintEl.innerHTML = ' ';
      this.visible = false;
    }
  }
};

export default Hint;
