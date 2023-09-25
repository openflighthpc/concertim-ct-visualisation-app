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
import Events from 'canvas/common/util/Events';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import ThumbHint from 'canvas/irv/view/ThumbHint';

class ThumbNav {
  static initClass() {
    // statics overwritten by config
    this.SHADE_FILL       = '#000000';
    this.SHADE_ALPHA      = .5;
    this.MASK_FILL        = '#333377';
    this.MASK_FILL_ALPHA  = .5;

    this.MODEL_DEPENDENCIES  = { dataCentreImage: 'dcImage', rackImage: 'rackImage', scale: 'scale' };
  }


  constructor(containerEl, maxWidth, maxHeight, model) {
    // assign a zero frame rate, we'll force the renderer to redraw on demand
    let left;
    this.setDataCentreImage = this.setDataCentreImage.bind(this);
    this.setRackImage = this.setRackImage.bind(this);
    this.setImg = this.setImg.bind(this);
    this.update = this.update.bind(this);
    this.containerEl = containerEl;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.model = model;
    this.gfx = new SimpleRenderer(this.containerEl, this.width, this.height, 1, 0);
    Util.setStyle(this.gfx.cvs, 'position', 'absolute');
    Util.setStyle(this.gfx.cvs, 'left', '0px');
    Util.setStyle(this.gfx.cvs, 'top', '0px');

    this.breachGfx = new SimpleRenderer(this.containerEl, this.width, this.height, 1, 0);
    Util.setStyle(this.breachGfx.cvs, 'position', 'absolute');
    Util.setStyle(this.breachGfx.cvs, 'left', '0px');
    Util.setStyle(this.breachGfx.cvs, 'top', '0px');

    this.hint = new ThumbHint((left = $('tooltip').parentElement) != null ? left : $('tooltip').parentNode, this.model);

    this.area = {
      left   : 0,
      top    : 0,
      width  : this.maxWidth,
      height : this.maxHeight
    };

    this.area.right  = this.area.left + this.area.width;
    this.area.bottom = this.area.top + this.area.height;
    if (ThumbNav.MODEL_DEPENDENCIES.dataCentreImage) { this.model[ThumbNav.MODEL_DEPENDENCIES.dataCentreImage].subscribe(this.setDataCentreImage); }
    if (ThumbNav.MODEL_DEPENDENCIES.rackImage) { this.model[ThumbNav.MODEL_DEPENDENCIES.rackImage].subscribe(this.setRackImage); }

    this.images = {};
    this.images.dataCentre = {};
    this.images.rack = {};

    this.biggestWidth = 0;
    this.biggestHeight = 0;

    this.width = 0;
    this.height = 0;
  }

  showHint(device, x, y) {
    if (device == null) { return; }
    return this.hint.show(device, x, y);
  }


  hideHint() {
    return this.hint.hide();
  }

  setDataCentreImage(img) {
    return this.setImg(img,'dataCentre');
  }

  setRackImage(img) {
    return this.setImg(img,'rack');
  }

  setImg(img, imageKey) {
    if (img == null) { return; }

    // fit model image to available space
    const scale_x = this.maxWidth / img.width;
    const scale_y = this.maxHeight / img.height;
    this.scale  = scale_x < scale_y ? scale_x : scale_y;

    this.images[imageKey].width  = img.width * this.scale;
    this.images[imageKey].height = img.height * this.scale;

    // fit containing div to exact dimensions of new thumbnail
    Util.setStyle(this.containerEl, 'width', this.images[imageKey].width + 'px');
    Util.setStyle(this.containerEl, 'height', this.images[imageKey].height + 'px');

    const left = Util.getStyle(this.containerEl, 'left');
    const top  = Util.getStyle(this.containerEl, 'top');

    // align canvas to containing div
    Util.setStyle(this.gfx.cvs, 'left', left);
    Util.setStyle(this.gfx.cvs, 'top', top);
    Util.setStyle(this.breachGfx.cvs, 'left', left);
    Util.setStyle(this.breachGfx.cvs, 'top', top);

    // resize and update breaches
    this.gfx.setDims(this.images[imageKey].width, this.images[imageKey].height);
    this.breachGfx.setDims(this.images[imageKey].width, this.images[imageKey].height);

    // resize model image to fit
    const cvs        = document.createElement('canvas');
    cvs.width  = this.images[imageKey].width;
    cvs.height = this.images[imageKey].height;
    const ctx        = cvs.getContext('2d');
    ctx.drawImage(img, 0, 0, this.images[imageKey].width, this.images[imageKey].height);
    this.images[imageKey].img = cvs;

    if ((this.biggestWidth  === 0) || (this.biggestWidth  < this.images[imageKey].width)) { this.biggestWidth  = this.images[imageKey].width; }
    if ((this.biggestHeight === 0) || (this.biggestHeight < this.images[imageKey].height)) { this.biggestHeight = this.images[imageKey].height; }
    this.width = this.biggestWidth;
    this.height = this.biggestHeight;
    return this.update();
  }


  update(view_width, view_height, total_width, total_height, scroll_x, scroll_y) {
    // update can be called internally (setImg) with no params
    // or via the controller on scroll with new view params
    if (arguments.length > 0) {
      this.scale = this.biggestWidth / total_width;
    
      this.area = {
        left   : (scroll_x  / total_width) * this.biggestWidth,
        top    : (scroll_y / total_height) * this.biggestHeight,
        width  : (view_width / total_width) * this.biggestWidth,
        height : (view_height / total_height) * this.biggestHeight
      };

      this.area.right  = this.area.left + this.area.width;
      this.area.bottom = this.area.top + this.area.height;
    }

    // define a rectangle with another rectangle cut out of the middle
    const coords = [{ x: 0, y: 0 }, { x: this.biggestWidth, y: 0 }, { x: this.biggestWidth, y: this.biggestHeight }, { x: 0, y: this.biggestHeight }, { x: 0, y: this.area.top }, { x: this.area.left, y: this.area.top }, { x: this.area.left, y: this.area.bottom }, { x: this.area.right, y: this.area.bottom }, { x: this.area.right, y: this.area.top }, { x: 0, y: this.area.top }];

    this.gfx.removeAll();

    for (var imageKey in this.images) {
      var imageValue = this.images[imageKey];
      if (!imageValue.img) { continue; }
      this.gfx.addImg({ img: imageValue.img, x: 0, y: 0 });
    }

    this.gfx.addPoly({ fill: ThumbNav.MASK_FILL, alpha: ThumbNav.MASK_FILL_ALPHA, fx: 'source-atop', coords });
    this.mask = this.gfx.addPoly({ fill: ThumbNav.SHADE_FILL, alpha: ThumbNav.SHADE_ALPHA, coords });
    return this.gfx.redraw();
  }


  jumpTo(x, y) {
    x -= this.area.width / 2;
    y -= this.area.height / 2;

    if (x < 0) { x = 0; }
    if ((x + this.area.width) > this.width) { x = this.width - this.area.width; }
    if (y < 0) { y = 0; }
    if ((y + this.area.height) > this.height) { y = this.height - this.area.height; }

    this.area.left   = x;
    this.area.right  = x + this.area.width;
    this.area.top    = y;
    this.area.bottom = y + this.area.height;

    return this.update();
  }
};
ThumbNav.initClass();
export default ThumbNav;
