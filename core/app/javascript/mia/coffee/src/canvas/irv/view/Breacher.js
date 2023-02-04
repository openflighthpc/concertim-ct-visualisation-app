/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Easing from 'canvas/common/gfx/Easing';

class Breacher {
  static initClass() {
    this.STROKE_WIDTH   = 5;
    this.STROKE         = '#ff0000';
    this.ALPHA_MAX      = 1;
    this.ALPHA_MIN      = .5;
    this.ANIM_DURATION  = 900;
  }


  constructor(group, id, gfx, x, y, width, height, model, reportBreachZones) {
    this.fadeToMax = this.fadeToMax.bind(this);
    this.fadeToMin = this.fadeToMin.bind(this);
    this.group = group;
    this.id = id;
    this.gfx = gfx;
    this.model = model;
    if (reportBreachZones == null) { reportBreachZones = true; }
    this.reportBreachZones = reportBreachZones;
    const offset = Breacher.STROKE_WIDTH / 2;

    this.asset = this.gfx.addRect({
      x           : x + offset,
      y           : y + offset,
      width       : width - Breacher.STROKE_WIDTH,
      height      : height - Breacher.STROKE_WIDTH,
      alpha       : Breacher.ALPHA_MIN,
      stroke      : Breacher.STROKE,
      strokeWidth : Breacher.STROKE_WIDTH});

    // delay animation start by a random amount to desynchronise breachers (looks cooler)
    this.delay = setTimeout(this.fadeToMax, Math.ceil(Math.random() * Breacher.ANIM_DURATION * 2));
  
    if (!this.reportBreachZones) { return; }

    const breaches              = this.model.breachZones();
    if (breaches[this.group][this.id] == null) { breaches[this.group][this.id] = []; }
    breaches[this.group][this.id].push({ x, y, width, height });
    this.model.breachZones(breaches);

    this.x      = x;
    this.y      = y;
    this.width  = width;
    this.height = height;
  }


  fadeToMax() {
    return this.gfx.animate(this.asset, { alpha: Breacher.ALPHA_MAX }, Breacher.ANIM_DURATION, Easing.Cubic.easeOut, this.fadeToMin);
  }


  fadeToMin() {
    return this.gfx.animate(this.asset, { alpha: Breacher.ALPHA_MIN }, Breacher.ANIM_DURATION, Easing.Cubic.easeOut, this.fadeToMax);
  }


  destroy() {
    this.gfx.remove(this.asset);
    clearTimeout(this.delay);

    if (!this.reportBreachZones) { return; }

    const breach_zones = this.model.breachZones();
    const breaches     = breach_zones[this.group][this.id];
    if (breaches != null) {
      for (let idx = 0; idx < breaches.length; idx++) {
        var breach = breaches[idx];
        if ((breach.x === this.x) && (breach.y === this.y) && (breach.width === this.width) && (breach.height === this.height)) {
          breaches.splice(idx, 1);
          if (breaches.length === 0) { delete breach_zones[this.group][this.id]; }
          break;
        }
      }
    }

    return this.model.breachZones(breach_zones);
  }
};
Breacher.initClass();
export default Breacher;
