/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */


import Metric from 'canvas/common/widgets/Metric';
import Easing from 'canvas/common/gfx/Easing';

class MultiMetric extends Metric {

  // draws the multimetric according to relevant modes i.e. horizontal/vertical, scaled/unscaled
  draw() {
    this.visible = true;
    if (!this.modelRefs.scaleMetrics()) {
      if (this.horizontal) {
        const w = this.width / this.value.length;
        return (() => {
          const result = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var scale = this.scale[idx];
            result.push(this.assets.push(this.parent.infoGfx.addRect({
              x      : this.x + (idx * w),
              y      : this.y,
              width  : w,
              height : this.height,
              alpha  : Metric.ALPHA,
              fill   : '#' + this.getColour(scale).toString(16)
            })));
          }
          return result;
        })();
      } else {
        const h = this.height / this.value.length;
        return (() => {
          const result1 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var scale = this.scale[idx];
            result1.push(this.assets.push(this.parent.infoGfx.addRect({
              x      : this.x,
              y      : (this.y + this.height) - ((idx + 1) * h),
              width  : this.width,
              height : h,
              alpha  : Metric.ALPHA,
              fill   : '#' + this.getColour(scale).toString(16)
            })));
          }
          return result1;
        })();
      }


    } else {
      if (this.horizontal) {
        return (() => {
          const result2 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var left1;
            var scale = this.scale[idx];
            var left  = this.x + (((left1 = this.scale[idx - 1]) != null ? left1 : 0) * this.width);
            var right = this.x + (scale * this.width);
            result2.push(this.assets.push(this.parent.infoGfx.addRect({ x: left, y: this.y, width: right - left, height: this.height, alpha: Metric.ALPHA, fill: '#' + this.getColour(scale).toString(16) })));
          }
          return result2;
        })();
      } else {
        return (() => {
          const result3 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var left2;
            var scale = this.scale[idx];
            var top    = (this.y + this.height) - (scale * this.height);
            var bottom = (this.y + this.height) - (((left2 = this.scale[idx - 1]) != null ? left2 : 0) * this.height);
            result3.push(this.assets.push(this.parent.infoGfx.addRect({ x: this.x, y: top, width: this.width, height: bottom - top, alpha: Metric.ALPHA, fill: '#' + this.getColour(scale).toString(16) })));
          }
          return result3;
        })();
      }
    }
  }


  // initialises animations required to animate the graphical assets to a new state, either show a new value or toggle between
  // scaled and non-scaled
  updateBar() {
    if (!this.modelRefs.scaleMetrics()) {
      let h, w;
      if (this.horizontal) {
        w = this.width / this.value.length;
        h = this.height;
        return (() => {
          const result = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var scale = this.scale[idx];
            result.push(this.parent.infoGfx.animate(this.assets[idx], { x: this.x + (idx * w), y: this.y, width: w, height: h, alpha: Metric.ALPHA + (Math.random() * 0.01), fill: '#' + this.getColour(scale).toString(16) }, Metric.ANIM_DURATION, Easing.Cubic.easeOut));
          }
          return result;
        })();
      } else {
        w = this.width;
        h = this.height / this.value.length;
        return (() => {
          const result1 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var scale = this.scale[idx];
            result1.push(this.parent.infoGfx.animate(this.assets[idx], { x: this.x, y: (this.y + this.height) -  ((idx + 1) * h), width: w, height: h, alpha: Metric.ALPHA + (Math.random() * 0.01), fill: '#' + this.getColour(scale).toString(16) }, Metric.ANIM_DURATION, Easing.Cubic.easeOut));
          }
          return result1;
        })();
      }

    } else {
      if (this.horizontal) {
        return (() => {
          const result2 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var left1;
            var scale = this.scale[idx];
            var left  = this.x + (((left1 = this.scale[idx - 1]) != null ? left1 : 0) * this.width);
            var right = this.x + (scale * this.width);
            result2.push(this.parent.infoGfx.animate(this.assets[idx], { x: left, y: this.y, width: right - left, height: this.height, alpha: Metric.ALPHA + (Math.random() * 0.01), fill: '#' + this.getColour(scale).toString(16) }, Metric.ANIM_DURATION, Easing.Cubic.easeOut));
          }
          return result2;
        })();
      } else {
        return (() => {
          const result3 = [];
          for (let idx = 0; idx < this.scale.length; idx++) {
            var left2;
            var scale = this.scale[idx];
            var top    = (this.y + this.height) - (scale * this.height);
            var bottom = (this.y + this.height) - (((left2 = this.scale[idx - 1]) != null ? left2 : 0) * this.height);
            result3.push(this.parent.infoGfx.animate(this.assets[idx], { x: this.x, y: top, width: this.width, height: bottom - top, alpha: Metric.ALPHA + (Math.random() * 0.01), fill: '#' + this.getColour(scale).toString(16) }, Metric.ANIM_DURATION, Easing.Cubic.easeOut));
          }
          return result3;
        })();
      }
    }
  }


  // overwrites parent class method update. Fetches values to display, translates values into colours, shows/hides graphical assets as
  // necessary and commences animations
  update() {
    let old_len, scale;
    const metrics = this.modelRefs.metricData();
    const val_obj = metrics.values[this.componentClassName][this.id];
    if (this.value != null) { old_len = this.value.length; }
    this.value  = this.getValue(val_obj);

    if (this.value != null) {
      const colour_scale = this.modelRefs.colourScale();
      const colour_map   = this.modelRefs.colourMaps()[val_obj.name != null ? val_obj.name : metrics.metricId];
      
      this.scale = [];
      for (var val of Array.from(this.value)) {
        scale = (val - colour_map.low) / colour_map.range;
        if (scale < 0) { scale = 0; }
        if (scale > 1) { scale = 1; }
        this.scale.push(scale);
      }

      if (this.active) {
        if (this.value.length === old_len) {
          this.show();
          return this.updateBar();
        } else {
          return this.draw();
        }
      } else {
        return this.hide();
      }
    } else {
      this.scale = null;
      return this.hide();
    }
  }


  // grabs the raw metric values and sorts them. This function rewrites itself on first execution to avoid re-evaluation of wether
  // the raw values are stored as an object or an array
  // @param  val   the object containing the metric values to display
  // @return       a sorted array of values
  getValue(val) {
    if (val == null) { return; }

    this.getValue = val instanceof Array ? this.getValueArray : this.getValueObject;
    return this.getValue(val);
  }


  // takes an array of values and sorts it
  // @param  val   an array of metric values
  // @return       a sorted array of metric values
  getValueArray(val) {
    const num_sort = (a, b) => a - b;

    return val.sort(num_sort);
  }


  // pulls all numeric values out of an object into a sorted array
  // @param  val   an object containing metric values
  // @return       a sorted array of metric values
  getValueObject(val) {
    if (val == null) { return; }

    const num_sort = (a, b) => a - b;

    const vals = [];
    for (var key in val) {
      var value = val[key];
      if (!isNaN(Number(value))) { vals.push(value); }
    }

    return vals.sort(num_sort);
  }
};

export default MultiMetric;
