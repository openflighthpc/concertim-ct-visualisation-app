/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Metric from './Metric';
import Easing from '../gfx/Easing';

class EllipticalMetric extends Metric {
  
  constructor(group, id, parent, x, y, width, height, model) {
    super(group, id, parent, x, y, width, height, model);
  }

  
  draw() {
    const scale  = this.model[Metric.MODEL_DEPENDENCIES.scaleMetrics]() ? this.scale : 1;
    const colour = '#' + this.getColour(this.scale).toString(16);

    this.assets.push(this.parent.infoGfx.addEllipse({
      x      : this.x,
      y      : this.y,
      width  : this.width,
      height : this.height,
      fill   : colour,
      alpha  : Metric.ALPHA
    }));

    if (this.horizontal) {
      const bite_width = this.width * (1 - scale);

      return this.assets.push(this.parent.infoGfx.addRect({
        fx     : 'destination-out',
        x      : (this.x + this.width) - bite_width,
        y      : this.y,
        width  : bite_width,
        height : this.height,
        fill   : '#000000'
      }));
    } else {
      return this.assets.push(this.parent.infoGfx.addRect({
        fx     : 'destination-out',
        x      : this.x,
        y      : this.y,
        width  : this.width,
        height : this.height * (1 - scale),
        fill   : '#000000'
      }));
    }
  }


  updateBar() {
    const colour = '#' + this.getColour(this.scale).toString(16);
    this.parent.infoGfx.animate(this.assets[0], { fill: colour, width: this.width + Math.random(), height: this.height }, Metric.ANIM_DURATION, Easing.Cubic.easeOut);

    if (this.model[Metric.MODEL_DEPENDENCIES.scaleMetrics]()) {
      if (this.horizontal) {
        const bite_width = this.width * (1 - this.scale);
        return this.parent.infoGfx.animate(this.assets[1], { x: (this.x + this.width) - bite_width, width: bite_width }, Metric.ANIM_DURATION, Easing.Cubic.easeOut);
      } else {
        return this.parent.infoGfx.animate(this.assets[1], { y: this.y, height: this.height * (1 - this.scale) }, Metric.ANIM_DURATION, Easing.Cubic.easeOut);
      }
    } else {
      let attrs;
      if (this.horizontal) {
        attrs = { width: 0, height: this.height };
      } else {
        attrs = { width: this.width, height: 0 };
      }

      return this.parent.infoGfx.animate(this.assets[1], attrs, Metric.ANIM_DURATION, Easing.Cubic.easeOut);
    }
  }
};

export default EllipticalMetric;
