/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import Util from 'canvas/common/util/Util';
import Easing from 'canvas/common/gfx/Easing';

class Metric {
  static initClass() {
    // statics overwritten by config
    this.ALPHA          = .5;
    this.ANIM_DURATION  = 500;
    this.FADE_DURATION  = 500;

    this.MODEL_DEPENDENCIES  = { scaleMetrics: "scaleMetrics", metricData: "metricData", colourMaps: "colourMaps", colourScale: "colourScale" };
  }


  constructor(group, id, parent, x, y, width, height, model) {
    this.update = this.update.bind(this);
    this.show = this.show.bind(this);
    this.hide = this.hide.bind(this);
    this.evToggleScale = this.evToggleScale.bind(this);
    this.group = group;
    this.id = id;
    this.parent = parent;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.model = model;
    this.visible    = false;
    this.active     = false;
    this.horizontal = this.width > this.height;
    this.scale      = 0;
    this.assets     = [];

    // create model reference store
    this.modelRefs = {};
    for (var key in Metric.MODEL_DEPENDENCIES) { var value = Metric.MODEL_DEPENDENCIES[key]; this.modelRefs[key] = this.model[value]; }

    this.subscriptions = [];
    this.subscriptions.push(this.modelRefs.scaleMetrics.subscribe(this.evToggleScale));
    this.subscriptions.push(this.modelRefs.metricData.subscribe(this.update));
    this.subscriptions.push(this.modelRefs.colourMaps.subscribe(this.update));
    if (Metric.MODEL_DEPENDENCIES.stat != null) { this.subscriptions.push(this.modelRefs.stat.subscribe(this.update)); }

    this.update();
  }


  // public method, destroys graphics and unsbuscribes from model
  destroy() {
    for (var asset of Array.from(this.assets)) { this.parent.infoGfx.remove(asset); }
    return Array.from(this.subscriptions).map((sub) => sub.dispose());
  }


  updateBar() {}
    // stub to be overwritten


  draw() {}
    // stub to be overwritten


  // public method, hides or shows the metric
  setActive(active) {
    this.active = active;
    if (this.active && (this.value != null)) { return this.show(); } else { return this.hide(); }
  }


  // overwrites parent class method update. Fetches values to display, translates values into colours, shows/hides graphical assets as
  // necessary and commences animations
  update() {
    const metrics = this.modelRefs.metricData();
    const val_obj = (metrics.byGroup != null ? metrics.byGroup : metrics.values)[this.group][this.id];
    this.value  = this.getValue(val_obj);

    if (this.value != null) {
      const colour_scale = this.modelRefs.colourScale();
      const colour_map   = this.modelRefs.colourMaps()[val_obj.name != null ? val_obj.name : metrics.metricId];
      this.scale       = (this.value - colour_map.low) / colour_map.range;
      if (this.scale < 0) { this.scale       = 0; }
      if (this.scale > 1) { this.scale       = 1; }
      this.name        = val_obj.name;

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


  // grabs a single metric value. This function rewrites itself on first execution to avoid re-evaluation
  // @param  val   object containing the metric values, can be a float or object of values
  // @return       float, the metric value
  getValue(val) {
    this.getValue = (this.modelRefs.stat != null) ? this.getValueComplex : this.getValueSimple;
    return this.getValue(val);
  }


  // returns the metric value
  // @param  val   float, the metric value to return
  // @return       float, the metric value
  getValueSimple(val) {
    return val;
  }


  // returns a metric value from an object of values. Uses the metric statistic model value to access the metric, defaulting to value
  // if it doesn't exist
  // @param  val   an object containing metric values
  // @return       float, the metric value
  getValueComplex(val) {
    let left;
    if (val == null) { return; }
    return (left = val[this.modelRefs.stat()]) != null ? left : val.value;
  }


  // moves the metric to a new location, updating the coordinates of all associated assets
  // @param  x   the new x coordinate
  // @param  y   the new y coordinate
  setCoords(x, y) {
    if ((this.assets.length > 0) && ((x !== this.x) || (y !== this.y))) {
      const dx = x - this.x;
      const dy = y - this.y;

      for (var asset of Array.from(this.assets)) {
        this.parent.infoGfx.setAttributes(asset, {
          x: dx + this.parent.infoGfx.getAttribute(asset, 'x'),
          y: dy + this.parent.infoGfx.getAttribute(asset, 'y')
        });
      }
    }

    this.x = x;
    return this.y = y;
  }


  // changes the physical size of the metric
  // @param  width   float, the new width of the metric
  // @param  height  float, the new height of the metric
  setSize(width, height) {
    if ((width === this.width) && (height === this.height)) { return; }

    this.width  = width;
    return this.height = height;
  }

    //@draw() if @visible and @active


  // translates a metric value into a colour
  // @param  scale   float, a value representing at which point between the colour scale the value occurs where 0 represnts the colour scale
  //                 low value and 1 represents the colour scale high value. Numbers below zero or above one are treated as zero or one
  //                 respectively
  // @return         int, a decimal value represnting the colour
  getColour(scale) {
    const colours = this.model.getColoursArray();
    if ((scale <= 0) || isNaN(scale)) { return colours[0].col; }
    if (scale >= 1) { return colours[colours.length - 1].col; }

    let count = 0;
    const len   = colours.length;
    while (scale > colours[count].pos) { ++count; }
    const low  = colours[count - 1];
    const high = colours[count];
    return Util.blendColour(low.col, high.col, (scale - low.pos) / (high.pos - low.pos));
  }


  // shows the metric
  show() {
    if (!this.visible) {
      this.visible = true;
      return this.draw();
    }
  }


  // hides the metric
  hide() {
    if (this.visible) {
      this.visible = false;
      for (var asset of Array.from(this.assets)) { this.parent.infoGfx.remove(asset); }
      return this.assets = [];
    }
  }


  // public method, initialises an animation to fade out the metric
  fadeOut() {
    if (this.assets.length > 0) {
      this.visible = false;
      return this.parent.infoGfx.animate(this.assets[0], { alpha: 0 }, Metric.FADE_DURATION, Easing.Quad.easeOut, this.hide);
    }
  }


  // public method, initialises an animation to fade the metric in
  fadeIn() {
    if (!this.visible) {
      this.show();
      this.parent.infoGfx.setAttributes(this.assets[0], { alpha: 0 });
      return this.parent.infoGfx.animate(this.assets[0], { alpha: Metric.ALPHA }, Metric.FADE_DURATION, Easing.Quad.easeOut, this.evAnimComplete);
    }
  }


  // scaleMetrics model value subscriber
  evToggleScale() {
    if (this.active && (this.value != null)) { return this.updateBar(); }
  }
};
Metric.initClass();
export default Metric;
