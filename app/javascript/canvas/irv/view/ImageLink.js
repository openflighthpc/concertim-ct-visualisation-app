/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';

class ImageLink {
  constructor(conf, parent_object) {
    this.conf = conf;
    this.parent_object = parent_object;
    this.gfx = this.conf.gfx; 
    this.asset_id = null;
    this.x = this.conf.x;
    this.y = this.conf.y;
    this.align = this.conf.align;
    this.image = this.conf.image;
    this.width = this.conf.width || this.image.width;
    this.height = this.conf.height || this.image.height;
    this.url = this.conf.url;
    this.draw();
  }

  draw() {
    if (this.image) { return this.addImage(this.x, this.y, this.image); }
  }

  parent() {
    return this.parent_object;
  }

  remove() {
    if (this.asset_id) {
      this.gfx.remove(this.asset_id);
    }
    return this.asset_id = null;
  }

  addImage(x,y,image) {
    return this.asset_id =
      this.gfx.addImg({
        x,
        y,
        img     : image
      });
  }

  select() {
    Util.setStyle(this.parent().parentEl, 'cursor', 'pointer');
    return this.asset_selected = true;
  }
  
  deselect() {
    Util.setStyle(this.parent().parentEl, 'cursor', 'auto');
    return this.asset_selected = false;
  }
  
  isHighlighted() {
    return this.asset_selected === true;
  }
};

export default ImageLink;
