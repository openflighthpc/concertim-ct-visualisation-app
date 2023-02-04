/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';

class Text {
  constructor(conf) {
    this.conf = conf;
    this.gfx = this.conf.gfx; 
    this.asset_text = null;
    this.x = this.conf.x;
    this.y = this.conf.y;
    this.text_colour = this.conf.fill;
    this.align = this.conf.align;
    this.font = this.conf.font;
    this.text = this.conf.text;
    this.height = this.font.size * 2;
    this.maxWidth = this.conf.maxWidth;
    this.draw();
  }

  draw() {
    return this.addText(this.x, this.y, this.text, this.font.decoration, this.font.size, this.font.fontFamily, this.align, this.text_colour);
  }

  remove() {
    if (this.asset_text) {
      this.gfx.remove(this.asset_text);
    }
    return this.asset_text = null;
  }

  addText(x,y,value,decoration,size,fontFamily,align,text_colour) {
    return this.asset_text =
      this.gfx.addText({
        x,
        y,
        caption : value,
        font    : decoration+' '+size+'px '+fontFamily,
        align,
        fill    : text_colour,
        maxWidth: this.maxWidth
      });
  }
};

export default Text;
