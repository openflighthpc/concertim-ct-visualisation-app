/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Primitives = {};

// base class
Primitives.Asset = class {

  constructor(def) {
    this.id    = def.id;
    this.x     = def.x;
    this.y     = def.y;
    this.alpha = def.alpha;
    this.fx    = def.fx;
  }


  adjustStrokeBoundaries(bounds, scale) {
    const scaled_stroke  = this.strokeWidth * scale;
    const half_stroke    = scaled_stroke / 2;

    bounds.x      -= half_stroke;
    bounds.y      -= half_stroke;
    bounds.width  += scaled_stroke;
    bounds.height += scaled_stroke;

    return bounds;
  }
};

Primitives.Line = class extends Primitives.Asset {

  constructor(def,scale,ctx) {
    this.def = def;
    this.ctx = ctx;
    super(this.def);
    this.width  = this.def.x2 - this.def.x;
    this.height = 1;
  }

  draw(scale) {
    this.ctx.beginPath();
    this.ctx.globalAlpha = this.alpha;
    this.ctx.strokeStyle = this.def.stroke;
    this.ctx.moveTo(this.def.x*scale, this.def.y*scale);
    this.ctx.lineTo(this.def.x2*scale,this.def.y2*scale);
    return this.ctx.stroke();
  }

  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * scale, height: this.height * scale };
  }
};

Primitives.Arrow = class extends Primitives.Asset {

  constructor(def,scale,ctx) {
    this.def = def;
    this.ctx = ctx;
    super(this.def);
    this.tip_height = 10;
    this.y1_5   = def.y1_5;
    this.x2     = def.x2;
    this.y2     = def.y2;
    this.width  = this.x2 - this.x;
    this.height = this.y2 - this.y;
  }

  draw(scale) {
    this.ctx.beginPath();
    this.ctx.globalAlpha = this.alpha;
    this.ctx.strokeStyle = this.def.fill;
    this.ctx.moveTo(this.x*scale, this.y*scale);
    if (this.y1_5 !== 0) {
      this.ctx.lineTo(this.x*scale,this.y1_5*scale);
      this.y += this.y1_5 - this.y;
    }
    if (this.x2 !== 0) {
      this.ctx.lineTo((this.x2)*scale,this.y*scale);
    }
    this.ctx.lineTo((this.x2)*scale,(this.y2-this.tip_height)*scale);

    this.ctx.moveTo((this.x2)*scale,(this.y2)*scale);
    this.ctx.lineTo((this.x2-this.tip_height)*scale,(this.y2-this.tip_height)*scale);
    this.ctx.moveTo((this.x2)*scale,(this.y2)*scale);
    this.ctx.lineTo((this.x2+this.tip_height)*scale,(this.y2-this.tip_height)*scale);
    this.ctx.lineTo((this.x2-this.tip_height)*scale,(this.y2-this.tip_height)*scale);

    return this.ctx.stroke();
  }

  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * scale, height: this.height * scale };
  }
};

Primitives.Circle = class extends Primitives.Asset {

  constructor(def,scale,ctx) {
    this.ctx = ctx;
    super(def);
    this.width  = def.width;
    this.fill = def.fill;
    this.stroke      = def.stroke;
  }


  draw(scale) {
    this.ctx.beginPath();
    this.ctx.globalAlpha              = this.alpha;
    this.ctx.globalCompositeOperation = this.fx;
    this.ctx.arc(this.x, this.y, this.width, 0, 2 * Math.PI);
    this.ctx.fillStyle = this.fill;
    this.ctx.fill();
    this.ctx.strokeStyle = this.stroke;
    return this.ctx.stroke();
  }


  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * 2 * scale, height: this.width * 2 * scale };
  }
};


Primitives.Rect = class extends Primitives.Asset {

  constructor(def) {
    super(def);
    this.width  = def.width;
    this.height = def.height;
  }


  draw(scale) {
    this.ctx.beginPath();
    this.ctx.globalAlpha              = this.alpha;
    this.ctx.globalCompositeOperation = this.fx;
    return this.ctx.rect(this.x * scale, this.y * scale, this.width * scale, this.height * scale);
  }


  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * scale, height: this.height * scale };
  }
};


Primitives.FilledRect = class extends Primitives.Rect {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.fill = def.fill;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.fillStyle = this.fill;
    return this.ctx.fill();
  }
};


Primitives.LineRect = class extends Primitives.Rect {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    return this.ctx.stroke();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.FullRect = class extends Primitives.Rect {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.fill        = def.fill;
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.fillStyle = this.fill;
    this.ctx.fill();
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    return this.ctx.stroke();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.Poly = class extends Primitives.Asset {

  constructor(def) {
    super(def);

    let min_x = Number.MAX_VALUE;
    let min_y = Number.MAX_VALUE;
    let max_x = -Number.MAX_VALUE;
    let max_y = -Number.MAX_VALUE;

    this.coords = def.coords;

    for (var coords of Array.from(def.coords)) {
      if (coords.x < min_x) { min_x = coords.x; }
      if (coords.y < min_y) { min_y = coords.y; }
      if (coords.x > max_x) { max_x = coords.x; }
      if (coords.y > max_y) { max_y = coords.y; }
    }

    this.offsetX = min_x;
    this.offsetY = min_y;
    this.width   = max_x - min_x;
    this.height  = max_y - min_y;
  }


  draw(scale) {
    this.ctx.globalAlpha              = this.alpha;
    this.ctx.globalCompositeOperation = this.fx;
    this.ctx.beginPath();
    this.ctx.moveTo((this.x + this.coords[0].x) * scale, (this.y + this.coords[0].y) * scale);

    let count = 1;
    const len   = this.coords.length;
    while (count < len) {
      this.ctx.lineTo((this.x + this.coords[count].x) * scale, (this.y + this.coords[count].y) * scale);
      ++count;
    }

    return this.ctx.closePath();
  }


  getBoundaries(scale) {
    return { x: (this.x + this.offsetX) * scale, y: (this.y + this.offsetY) * scale, width: this.width * scale, height: this.height * scale };
  }
};


Primitives.FilledPoly = class extends Primitives.Poly {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.fill = def.fill;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.fillStyle = this.fill;
    return this.ctx.fill();
  }
};


Primitives.LinePoly = class extends Primitives.Poly {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    return this.ctx.stroke();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.FullPoly = class extends Primitives.Poly {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.fill        = def.fill;
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    this.ctx.stroke();
    this.ctx.fillStyle = this.fill;
    return this.ctx.fill();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.Ellipse = class extends Primitives.Asset {

  constructor(def) {
    super(def);
    this.width  = def.width;
    this.height = def.height;
  }


  draw(scale) {
    this.ctx.beginPath();
    this.ctx.globalAlpha              = this.alpha;
    this.ctx.globalCompositeOperation = this.fx;
    this.ctx.save();
    const v_scale = this.height / this.width;
    this.ctx.scale(1, v_scale);
    const radius = (this.width * scale) / 2;
    this.ctx.beginPath();
    this.ctx.arc((this.x * scale) + radius, ((this.y * scale) / v_scale) + radius, radius, 0, Math.PI * 2);
    return this.ctx.restore();
  }


  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * scale, height: this.height * scale };
  }
};


Primitives.FilledEllipse = class extends Primitives.Ellipse {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.fill = def.fill;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.fillStyle = this.fill;
    return this.ctx.fill();
  }
};


Primitives.LineEllipse = class extends Primitives.Ellipse {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def, scale, this.ctx);
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    return this.ctx.stroke();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.FullEllipse = class extends Primitives.Ellipse {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def, scale, this.ctx);
    this.stroke      = def.stroke;
    this.strokeWidth = def.strokeWidth;
    this.fill        = def.fill;
  }


  draw(scale) {
    super.draw(...arguments);
    this.ctx.strokeStyle = this.stroke;
    this.ctx.lineWidth   = this.strokeWidth * scale;
    this.ctx.stroke();
    this.ctx.fillStyle = this.fill;
    return this.ctx.fill();
  }


  getBoundaries(scale) {
    return this.adjustStrokeBoundaries(super.getBoundaries(...arguments), scale);
  }
};


Primitives.Image = class extends Primitives.Asset {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    super(def);
    this.img         = def.img;
    this.width       = def.width;
    this.height      = def.height;
    this.sliceX      = def.sliceX;
    this.sliceY      = def.sliceY;
    this.sliceWidth  = def.sliceWidth;
    this.sliceHeight = def.sliceHeight;
  }


  draw(scale) {
    this.ctx.globalAlpha              = this.alpha;
    this.ctx.globalCompositeOperation = this.fx;
    if ((this.img != null) && (this.img !== "pending")) { return this.ctx.drawImage(this.img, this.sliceX, this.sliceY, this.sliceWidth, this.sliceHeight, this.x * scale, this.y * scale, this.width * scale, this.height * scale); }
  }
    //@ctx.drawImage(@img, @x * scale, @y * scale, @width * scale, @height * scale)


  getBoundaries(scale) {
    return { x: this.x * scale, y: this.y * scale, width: this.width * scale, height: this.height * scale };
  }
};


Primitives.Text = (function() {
  const Cls = class extends Primitives.Asset {
    static initClass() {

      this.TRUNCATION_SUFFIX = '...';
    }


    constructor(def, scale, ctx) {
      this.ctx = ctx;
      super(def);
      this.font     = def.font;
      this.fill     = def.fill;
      this.align    = def.align;
      this.caption  = def.caption;
      this.maxWidth = def.maxWidth;
      this.ctx.font = this.font;
      this.width    = this.ctx.measureText(this.caption).width;
      this.height   = Number(this.font.substring(0, this.font.indexOf('px')));

      this.maxLineWidth = def.maxLineWidth;
      this.maxLineAmount = def.maxLineAmount;
      this.lineHeight = def.lineHeight;
    }


    draw(scale) {
      this.ctx.globalAlpha              = this.alpha;
      this.ctx.globalCompositeOperation = this.fx;
      this.ctx.font                     = this.font;
      this.ctx.textAlign                = this.align;
      this.ctx.fillStyle                = this.fill;

      const caption = this.maxWidth ? this.truncate(scale,this.caption,this.maxWidth) : this.caption;

      if (this.maxLineWidth) {
        const words = this.caption.split(' ');
        let line = '';
        let n = 0;
        let line_index = 0;
        while (n < words.length) {
          var testLine = line + words[n] + ' ';
          var metrics = this.ctx.measureText(testLine);
          var testWidth = metrics.width;
          if ((testWidth > this.maxLineWidth) && (n > 0)) {
            if ((this.maxLineAmount != null) && (line_index === (this.maxLineAmount - 1))) {
              this.ctx.fillText(this.truncate(scale,testLine,this.maxLineWidth), this.x*scale, this.y*scale);
              return;
            } else {
              this.ctx.fillText(line, this.x*scale, this.y*scale);
            }
            line = words[n] + ' ';
            this.y += this.lineHeight;
            line_index += 1;
          } else {
            line = testLine;
          }
          n++;
        }
        return this.ctx.fillText(line, this.x*scale, this.y*scale);
      } else {
        this.text = caption;
        this.ctx.fillText(caption, this.x * scale, this.y * scale);
        return this.width = this.ctx.measureText(caption).width;
      }
    }


    getBoundaries(scale) {
      switch (this.align) {
        case 'left':
          return { x: this.x * scale, y: (this.y * scale) - this.height - this.offsetHeight(), width: this.width, height: this.height };
        case 'right':
          return { x: (this.x * scale) - this.width, y: (this.y * scale) - this.height - this.offsetHeight(), width: this.width, height: this.height };
        case 'center':
          return { x: (this.x * scale) - (this.width / 2), y: (this.y * scale) - this.height - this.offsetHeight(), width: this.width, height: this.height };
      }
    }


    truncate(scale, caption, max_line_with) {
      let {
        width
      } = this.ctx.measureText(caption);
      let truncated          = false;
      const relative_max_width = max_line_with * scale;

      while ((width > relative_max_width) && (caption.length > 0)) {
        truncated = true;
        caption   = caption.substr(0, caption.length - 1);
        ({
          width
        } = this.ctx.measureText(caption + Primitives.Text.TRUNCATION_SUFFIX));
      }

      if (truncated) { return caption + Primitives.Text.TRUNCATION_SUFFIX; } else { return caption; }
    }


    offsetHeight() {
      // hack: height of text isn't reported accurately so we need to offset a proportional amount
      return -this.height / 5;
    }
  };
  Cls.initClass();
  return Cls;
})();


Primitives.LabelText = class extends Primitives.Text {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    this.bgFill        = def.bgFill;
    this.bgStroke      = def.bgStroke;
    this.bgStrokeWidth = def.bgStrokeWidth;
    this.bgPadding     = def.bgPadding;
    this.bgAlpha       = def.bgAlpha;
    super(def, scale, this.ctx);
  }


  draw(scale) {
    let x;
    super.draw(...arguments);

    this.ctx.beginPath();
    const double_pad = this.bgPadding * 2;
    switch (this.align) {
      case 'left':
        x = (this.x * scale) - this.bgPadding;
        break;
      case 'right':
        x = (this.x * scale) - this.width - this.bgPadding;
        break;
      default:
        x = (this.x * scale) - (this.width / 2) - this.bgPadding;
    }
    
    this.ctx.rect(x, (this.y * scale) - this.height - this.bgPadding - this.offsetHeight(), this.width + double_pad, this.height + double_pad);

    this.ctx.globalAlpha = this.bgAlpha;

    if (this.bgFill) {
      this.ctx.fillStyle = this.bgFill;
      this.ctx.fill();
    }

    if (this.bgStroke) {
      this.ctx.strokeStyle = this.bgStroke;
      this.ctx.lineWidth = this.bgStrokeWidth;
      this.ctx.stroke();
    }

    return super.draw(...arguments);
  }


  getBoundaries() {
    const bounds = super.getBoundaries(...arguments);

    const double_pad = this.bgPadding * 2;

    bounds.x      -= this.bgPadding;
    bounds.y      -= this.bgPadding;
    bounds.width  += double_pad;
    bounds.height += double_pad;
    return bounds;
  }
};


Primitives.ShadowText = class extends Primitives.Text {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    this.shadowColour  = def.shadowColour;
    this.shadowOffsetX = def.shadowOffsetX;
    this.shadowOffsetY = def.shadowOffsetY;
    this.shadowBlur    = def.shadowBlur;
    super(def, scale, this.ctx);
  }


  draw(scale) {
    this.ctx.shadowColor   = this.shadowColour;
    this.ctx.shadowOffsetX = this.shadowOffsetX;
    this.ctx.shadowOffsetY = this.shadowOffsetY;
    this.ctx.shadowBlur    = this.shadowBlur;

    super.draw(...arguments);

    this.ctx.shadowBlur    = 0;
    this.ctx.shadowOffsetX = 0;
    return this.ctx.shadowOffsetY = 0;
  }
};

Primitives.BorderText = class extends Primitives.Text {

  constructor(def, scale, ctx) {
    this.ctx = ctx;
    this.borderColour = def.borderColour;
    this.borderWidth  = def.borderWidth;
    super(def, scale, this.ctx);
  }


  draw(scale) {
    this.ctx.font        = this.font;
    this.ctx.strokeStyle = this.borderColour;
    this.ctx.lineWidth   = this.borderWidth;
    this.ctx.strokeText(this.caption, this.x * scale, this.y * scale);

    super.draw(...arguments);

    this.ctx.strokeStyle = null;
    return this.ctx.lineWidth   = 0;
  }
};

export default Primitives;
