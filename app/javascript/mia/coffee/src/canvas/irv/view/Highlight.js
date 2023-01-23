/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Easing from '../../../canvas/common/gfx/Easing';

class Highlight {
  static initClass() {

    // statics overwritten by config
    this.SELECTED_FILL           = '#ffba00';
    this.SELECTED_BORDER_COLOUR  = '#0000FF';
    this.SELECTED_BORDER_WIDTH   = 20;
    this.SELECTED_ANIM_DURATION  = 1000;
    this.SELECTED_MAX_ALPHA      = .7;
    this.SELECTED_MIN_ALPHA      = .3;

    this.DRAGGED_FILL           = '#ffffff';
    this.DRAGGED_ANIM_DURATION  = 1000;
    this.DRAGGED_MAX_ALPHA      = .7;
    this.DRAGGED_MIN_ALPHA      = .3;

    // constants and run-time assigned statics
    this.MODE_SELECT = 'select';
    this.MODE_DRAG = 'drag';
  }


  constructor(mode, x, y, width, height, gfx, shape, coords, border) {
    let stroke;
    this.evSelectFadedOut = this.evSelectFadedOut.bind(this);
    this.evSelectFadedIn = this.evSelectFadedIn.bind(this);
    this.evDragFadedOut = this.evDragFadedOut.bind(this);
    this.evDragFadedIn = this.evDragFadedIn.bind(this);
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.gfx = gfx;
    if (shape == null) { shape = 'rect'; }
    this.shape = shape;
    if (coords == null) { coords = {}; }
    this.coords = coords;
    if (border == null) { border = false; }
    this.border = border;
    switch (mode) {
      case Highlight.MODE_SELECT:
        if (this.shape === 'rect') {
          let stroke_width;
          if (this.border) {
            stroke       = Highlight.SELECTED_BORDER_COLOUR;
            stroke_width = Highlight.SELECTED_BORDER_WIDTH;
          } else {
            stroke       = 1;
            stroke_width = 1;
          }
          this.rect = this.gfx.addRect({fill: Highlight.SELECTED_FILL, x: this.x, y: this.y, stroke, strokeWidth: stroke_width, width: this.width, height: this.height, alpha: Highlight.SELECTED_MAX_ALPHA});
        } else if (this.shape === 'poly') {
          this.rect = this.gfx.addPoly({ fill: Highlight.SELECTED_FILL, x: this.x, y: this.y, stroke: 1, strokeWidth: 1, coords: this.coords, alpha: Highlight.SELECTED_MAX_ALPHA });
        }
        this.evSelectFadedIn();
        break;
      case Highlight.MODE_DRAG:
        if (this.shape === 'rect') {
          this.rect = this.gfx.addRect({ fill: Highlight.DRAGGED_FILL, x: this.x, y: this.y, width: this.width, height: this.height, alpha: Highlight.DRAGGED_MAX_ALPHA });
        } else if (this.shape === 'poly') {
          this.rect = this.gfx.addPoly({ fill: Highlight.DRAGGED_FILL, x: this.x, y: this.y, stroke: 1, strokeWidth: 1, coords: this.coords, alpha: Highlight.SELECTED_MAX_ALPHA });
        }
        this.evDragFadedIn();
        break;
    }
  }


  evSelectFadedOut() {
    return this.gfx.animate(this.rect, { alpha: Highlight.SELECTED_MAX_ALPHA }, Highlight.SELECTED_ANIM_DURATION, Easing.Quint.easeOut, this.evSelectFadedIn);
  }


  evSelectFadedIn() {
    return this.gfx.animate(this.rect, { alpha: Highlight.SELECTED_MIN_ALPHA }, Highlight.SELECTED_ANIM_DURATION, Easing.Quint.easeIn, this.evSelectFadedOut);
  }


  evDragFadedOut() {
    return this.gfx.animate(this.rect, { alpha: Highlight.DRAGGED_MAX_ALPHA }, Highlight.DRAGGED_ANIM_DURATION, Easing.Quint.easeOut, this.evDragFadedIn);
  }


  evDragFadedIn() {
    return this.gfx.animate(this.rect, { alpha: Highlight.DRAGGED_MIN_ALPHA }, Highlight.DRAGGED_ANIM_DURATION, Easing.Quint.easeIn, this.evDragFadedOut);
  }


  destroy() {
    return this.gfx.remove(this.rect);
  }
};
Highlight.initClass();
export default Highlight;
