/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import Easing from 'canvas/common/gfx/Easing';
import Profiler from 'Profiler';

class Metric {
  static initClass() {

    // statics overwritten by config
    this.ALPHA          = .5;
    this.ANIM_DURATION  = 500;
    this.FADE_DURATION  = 500;
  }


  constructor(group, id, gfx, x, y, width, height, model) {
    this.update = this.update.bind(this);
    this.show = this.show.bind(this);
    this.hide = this.hide.bind(this);
    this.toggleScale = this.toggleScale.bind(this);
    this.group = group;
    this.id = id;
    this.gfx = gfx;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.model = model;
    this.visible    = false;
    this.active     = false;
    this.horizontal = this.width > this.height;
    this.scale      = 0;

    this.subscriptions = [];
    this.subscriptions.push(this.model.scaleMetrics.subscribe(this.toggleScale));
    this.subscriptions.push(this.model.metricData.subscribe(this.update));
    this.subscriptions.push(this.model.colourMaps.subscribe(this.update));

    this.update();
  }


  destroy() {
    return Array.from(this.subscriptions).map((sub) => sub.dispose());
  }


  setActive(active) {
    this.active = active;
    if (this.active && (this.value != null)) { return this.show(); } else { return this.hide(); }
  }


  update() {
    const metrics = this.model.metricData();
    this.value  = metrics.values[this.group][this.id];

    if (this.value != null) {
      const colour_scale = this.model.colourScale();
      const colour_map   = this.model.colourMaps()[metrics.metricId];
      const {
        range
      } = colour_map;
      this.scale       = (this.value - colour_map.low) / range;
      if ((this.scale < 0) || isNaN(this.scale)) { this.scale       = 0; }
      if (this.scale > 1) { this.scale       = 1; }
      if (this.active) {
        this.show();
        return this.updateBar();
      } else {
        return this.hide();
      }
    } else {
      this.scale = null;
      return this.hide();
    }
  }


  setCoords(x, y) {
    this.x = x;
    this.y = y;
    if (this.asset != null) {
      if (!this.horizontal && this.model.scaleMetrics()) {
        return this.gfx.setAttributes(this.asset, { x: this.x, y: (this.y + this.height) - (this.height * this.scale) });
      } else {
        if (this.asset != null) { return this.gfx.setAttributes(this.asset, { x: this.x, y: this.y }); }
      }
    }
  }


  updateBar() {
    let attrs;
    const colour = '#' + this.getColour().toString(16);
    if (!this.model.scaleMetrics()) {
      attrs = {
        fill: colour,
        width: this.width,
        height: this.height,
        y: this.y
      };
    } else {

      if (this.horizontal) {
        attrs = {
          fill: colour,
          width: this.width * this.scale
        };

      } else {
        const new_height = this.height * this.scale;
        attrs = {
          fill: colour,
          height: new_height,
          y: (this.y + this.height) - new_height
        };
      }
    }

    return this.gfx.animate(this.asset, attrs, Metric.ANIM_DURATION, Easing.Quad.easeOut);
  }


  getColour() {
    const colours = this.model.colourScale();

    if ((this.scale <= 0) || isNaN(this.scale)) { return colours[0].col; }
    if (this.scale >= 1) { return colours[colours.length - 1].col; }

    let count = 0;
    const len   = colours.length;
    while (this.scale > colours[count].pos) {
      ++count;
    }
    const low  = colours[count - 1];
    const high = colours[count];
    return Util.blendColour(low.col, high.col, (this.scale - low.pos) / (high.pos - low.pos));
  }


  draw() {
    Profiler.begin(Profiler.DEBUG);
    // clear
    if (this.asset != null) { this.gfx.remove(this.asset); }
    const colour = '#' + this.getColour().toString(16);

    if (!this.model.scaleMetrics()) {
      this.asset = this.gfx.addRect({ x: this.x, y: this.y, width: this.width, height: this.height, alpha: Metric.ALPHA, fill: colour });
    } else {

      if (this.horizontal) {
        this.asset = this.gfx.addRect({ x: this.x, y: this.y, width: this.width * this.scale, height: this.height, alpha: Metric.ALPHA, fill: colour });
      } else {
        const new_height = this.height * this.scale;
        this.asset = this.gfx.addRect({ x: this.x, y: (this.y + this.height) - new_height, width: this.width, height: new_height, alpha: Metric.ALPHA, fill: colour });
      }
    }
    return Profiler.end(Profiler.DEBUG);
  }


  show() {
    if (!this.visible) {
      this.visible = true;
      return this.draw();
    }
  }


  hide() {
    if (this.visible) {
      this.visible = false;
      this.gfx.remove(this.asset);
      return this.asset = null;
    }
  }


  fadeOut() {
    if (this.asset != null) {
      this.visible = false;
      return this.gfx.animate(this.asset, { alpha: 0 }, Metric.FADE_DURATION, Easing.Quad.easeOut, this.hide);
    }
  }


  fadeIn() {
    if (!this.visible) {
      this.show();
      this.gfx.setAttributes(this.asset, { alpha: 0 });
      return this.gfx.animate(this.asset, { alpha: Metric.ALPHA }, Metric.FADE_DURATION, Easing.Quad.easeOut, this.evAnimComplete);
    }
  }


  toggleScale() {
    if (this.active && (this.value != null)) { return this.updateBar(); }
  }
};
Metric.initClass();
export default Metric;
