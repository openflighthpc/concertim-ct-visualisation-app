/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import Metric from 'canvas/common/widgets/Metric';
import Easing from 'canvas/common/gfx/Easing';

class BarMetric extends Metric {
  
  constructor(componentClassName, id, parent, x, y, width, height, model) {
    super(componentClassName, id, parent, x, y, width, height, model);
  }


  draw() {
    const colour = '#' + this.getColour(this.scale).toString(16);

    if (!this.modelRefs.scaleMetrics()) {
      return this.assets.push(this.parent.infoGfx.addRect({ x: this.x, y: this.y, width: this.width, height: this.height, alpha: Metric.ALPHA, fill: colour }));
    } else {

      if (this.horizontal) {
        return this.assets.push(this.parent.infoGfx.addRect({ x: this.x, y: this.y, width: this.width * this.scale, height: this.height, alpha: Metric.ALPHA, fill: colour }));
      } else {
        const new_height = this.height * this.scale;
        return this.assets.push(this.parent.infoGfx.addRect({ x: this.x, y: (this.y + this.height) - new_height, width: this.width, height: new_height, alpha: Metric.ALPHA, fill: colour }));
      }
    }
  }


  updateBar() {
    let attrs;
    const scale = this.scale || 0;
    const colour = '#' + this.getColour(scale).toString(16);
    if (!this.modelRefs.scaleMetrics()) {
      attrs = {
        fill   : colour,
        width  : this.width,
        height : this.height,
        y      : this.y
      };
    } else {

      if (this.horizontal) {
        attrs = {
          fill  : colour,
          width : this.width * scale
        };

      } else {
        const new_height = this.height * scale;
        attrs = {
          fill   : colour,
          height : new_height,
          y      : (this.y + this.height) - new_height
        };
      }
    }

    return this.parent.infoGfx.animate(this.assets[0], attrs, Metric.ANIM_DURATION, Easing.Cubic.easeOut);
  }
};

export default BarMetric;
