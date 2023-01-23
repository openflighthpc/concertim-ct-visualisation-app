/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import RackObject from '../../../canvas/irv/view/RackObject';
import AssetManager from '../../../canvas/irv/util/AssetManager';
import Events from '../../../canvas/common/util/Events';
import BarMetric from '../../../canvas/common/widgets/BarMetric';
import VHMetric from '../../../canvas/irv/view/VHMetric';
import Highlight from '../../../canvas/irv/view/Highlight';
import Breacher from '../../../canvas/irv/view/Breacher';
import ViewModel from '../../../canvas/irv/ViewModel';
import Profiler from 'Profiler';

class Machine extends RackObject {
  constructor(def, parent) {
    let dim_image, natural_ratio, rotated_ratio;
    this.draw = this.draw.bind(this);
    this.setSingleMetricVisibility = this.setSingleMetricVisibility.bind(this);
    this.setVHMetricVisibility = this.setVHMetricVisibility.bind(this);
    this.setBreaching = this.setBreaching.bind(this);
    super(def, 'devices', parent);
    
    this.images       = {};
    if (def.template.images.front != null) { this.images.front = AssetManager.CACHE[RackObject.IMAGE_PATH + def.template.images.front]; }
    if (def.template.images.rear != null) { this.images.rear  = AssetManager.CACHE[RackObject.IMAGE_PATH + def.template.images.rear]; }

    // swap images if rear mounted
    if (!this.frontFacing) {
      const tmp           = this.images.front;
      this.images.front = this.images.rear;
      this.images.rear  = tmp;
    }

    this.images.both = this.images.front;

    // rotate images if necessary
    const slot_ratio = this.parent().slotWidth / this.parent().slotHeight;

    // find the orientation which best fits the slot dimensions and rotate images if necessary
    if (this.images.front != null) {
      natural_ratio = (this.images.front.width / this.template.width) / (this.images.front.height / this.template.height);
      rotated_ratio = (this.images.front.height / this.template.height) / (this.images.front.width / this.template.width);
      if  (Math.abs(slot_ratio - rotated_ratio) < Math.abs(slot_ratio - natural_ratio)) { this.images.front = this.rotateImage(this.images.front); }
      dim_image     = this.images.front;
    }

    if (this.images.rear != null) {
      natural_ratio = (this.images.rear.width / this.template.width) / (this.images.rear.height / this.template.height);
      rotated_ratio = (this.images.rear.height / this.template.height) / (this.images.rear.width / this.template.width);
      if  (Math.abs(slot_ratio - rotated_ratio) < Math.abs(slot_ratio - natural_ratio)) { this.images.rear  = this.rotateImage(this.images.rear); }
      dim_image     = this.images.rear;
    }

    this.x      = 0;
    this.y      = 0;
    this.width  = (dim_image != null) ? dim_image.width : this.parent().slotWidth;
    this.height = (dim_image != null) ? dim_image.height : this.parent().slotHeight;

    this.pluggable   = this.parent().complex;
    this.virtualHost = def.type === "VirtualHost";
    this.visible     = false;
    this.row         = def.row;
    this.column      = def.column;
    this.slot_id     = null;
    this.type        = def.type;
    this.selected    = false;
    this.assets      = [];

    if (RackObject.MODEL.metricLevel !== undefined) {
      this.metric   = new BarMetric(this.group, this.id, this, this.x, this.y, this.width, this.height, RackObject.MODEL);
      if (this.virtualHost) { this.vhMetric = new VHMetric(this.group, this.id, this, this.x, this.y, this.width, this.height, RackObject.MODEL); }
      
      if (RackObject.MODEL.showingFullIrv()) { this.subscriptions.push(RackObject.MODEL.metricLevel.subscribe((this.virtualHost ? this.setVHMetricVisibility : this.setSingleMetricVisibility))); }
      this.subscriptions.push(RackObject.MODEL.breaches.subscribe(this.setBreaching));

      this.setBreaching(RackObject.MODEL.breaches());
      this.setIncluded();
    } else {
      this.included = true;
    }

    this.facing = this.parent().facing;
  }

  destroy() {
    if (this.breach != null) { this.breach.destroy(); }
    if (this.highlight != null) { this.highlight.destroy(); }
    if (this.metric != null) { this.metric.destroy(); }
    if (this.vhMetric != null) { this.vhMetric.destroy(); }
    return super.destroy();
  }

  rotateImage(img) {
    const cvs        = document.createElement('canvas');
    cvs.width  = img.height;
    cvs.height = img.width;

    const ctx = cvs.getContext('2d');
    if (this.template.rotateClockwise) {
      ctx.rotate(Math.PI / 2);
      ctx.drawImage(img, 0, -img.height);
    } else {
      ctx.rotate(-Math.PI / 2);
      ctx.drawImage(img, -img.width, 0);
    }
    return cvs;
  }

  showDrag() {
    if (this.highlightDragging != null) {
      this.highlightDragging.destroy();
      delete this.highlightDragging; 
    }
  
    return this.highlightDragging = new Highlight(Highlight.MODE_DRAG, this.x, this.y, this.width, this.height, this.rackInfoGfx);
  }
  
  
  hideDrag() {
    if (this.highlightDragging != null) {
      this.highlightDragging.destroy();
      return delete this.highlightDragging; 
    }
  }

  setCoords(x, y) {
    this.x = x;
    this.y = y;
    this.y -= this.height;
    if (this.metric != null) { this.metric.setCoords(this.x, this.y); }
    if (this.vhMetric != null) { return this.vhMetric.setCoords(this.x, this.y); }
  }

  setCoordsBasedOnRowAndCol() {
    const x = (this.parent().x + this.parent().template.padding.left + (this.column * this.parent().slotWidth));
    const y = (this.parent().y + this.parent().template.padding.top  + ((this.parent().template.rows - this.row - 1) * this.parent().slotHeight));
    return this.setCoords(x, y);
  }

  updateSlot() {
    const data = {slot_id:this.slot_id};
    this.conf = {action:'update_slot', data};
    return this.create_request();
  }

  select() {
    if ((this.highlight == null) && !!this.visible) {
      const highlight_border = RackObject.MODEL.showingFullIrv() && RackObject.MODEL.overLBC();
      if (this.breaching) {
        const offset     = Breacher.STROKE_WIDTH;
        const double_off = offset * 2;
        this.highlight = new Highlight(Highlight.MODE_SELECT, this.x + offset, this.y + offset, this.width - double_off, this.height - double_off, this.alertGfx, 'rect', {}, highlight_border);
      } else {
        this.highlight = new Highlight(Highlight.MODE_SELECT, this.x, this.y, this.width, this.height, this.alertGfx, 'rect', {}, highlight_border);
      }
      if (this.fullDepth() || this.noDeviceBlocking()) {
        return this.selectOtherInstances();
      }
    }
  }


  deselect() {
    if (this.highlight != null) {
      this.highlight.destroy();
      delete this.highlight;
      return this.deselectOtherInstances();
    }
  }

  draw() {
    Profiler.begin(Profiler.DEBUG, this.name);
    // clear
    for (var asset of Array.from(this.assets)) { this.gfx.remove(asset); }
    this.assets = [];

    if (this.breach != null) {
      this.breach.destroy();
      this.breach = null;
    }

    this.face = this.parent().face;

    this.img = this.images[this.face];
    this.visible = (this.img != null) || !this.pluggable || (this.face === ViewModel.FACE_FRONT) || (this.face === ViewModel.FACE_REAR);
    if (RackObject.MODEL.showingFullIrv()) { this.setMetricVisibility(); }
    if (this.img != null) {
      this.assets.push(this.gfx.addImg({ img: this.img, x: this.x, y: this.y, alpha: this.included ? 1 : RackObject.EXCLUDED_ALPHA }));
      // add a fade if in metric view mode
      if  ((RackObject.MODEL.viewMode !== undefined) && (RackObject.MODEL.viewMode() === ViewModel.VIEW_MODE_METRICS)) {
        this.assets.push(this.gfx.addRect({ fx: 'source-atop', x: this.x, y: this.y, width: this.width, height: this.height, fill: RackObject.METRIC_FADE_FILL, alpha: RackObject.METRIC_FADE_ALPHA })); 
      }
    }

    if (this.breaching) { this.breach = new Breacher(this.group, this.id, this.alertGfx, this.x, this.y, this.width, this.height, RackObject.MODEL, !this.placedInHoldingArea()); }
    return Profiler.end(Profiler.DEBUG);
  }


  placedInHoldingArea() {
    return this.parent().placedInHoldingArea();
  }

  depth() {
    return this.parent().depth();
  }

  rack() {
    return this.parent().rack();
  }

  uStart() {
    return this.parent().uStart();
  }

  // this function rewrites itself on first execution to avoid subsequent re-evaluation
  setMetricVisibility() {
    this.setMetricVisibility = this.virtualHost ? this.setVHMetricVisibility : this.setSingleMetricVisibility;
    return this.setMetricVisibility();
  }


  setSingleMetricVisibility() {
    const metric_level     = RackObject.MODEL.metricLevel();
    const view_mode        = RackObject.MODEL.viewMode();
    const active_selection = RackObject.MODEL.activeSelection();
    const selected         = RackObject.MODEL.selectedDevices();
    const active_filter    = RackObject.MODEL.activeFilter();
    const filtered         = RackObject.MODEL.filteredDevices();

    let visible = ((metric_level === this.group) || ((metric_level === ViewModel.METRIC_LEVEL_ALL) && (this.children.length === 0))) && this.viewableDevice() && (view_mode !== ViewModel.VIEW_MODE_IMAGES) && (!active_selection || selected[this.group][this.id]) && (!active_filter || filtered[this.group][this.id]);
    if ((this.placedInHoldingArea() === true) && (RackObject.MODEL.showHoldingArea() === false)) { visible = false; }

    return this.metric.setActive(visible);
  }

  setVHMetricVisibility() {
    const metric_level     = RackObject.MODEL.metricLevel();
    const view_mode        = RackObject.MODEL.viewMode();
    const active_selection = RackObject.MODEL.activeSelection();
    const selected         = RackObject.MODEL.selectedDevices();
    const active_filter    = RackObject.MODEL.activeFilter();
    const filtered         = RackObject.MODEL.filteredDevices();

    const visible = this.viewableDevice() && (view_mode !== ViewModel.VIEW_MODE_IMAGES) && (!active_selection || selected[this.group][this.id]) && (!active_filter || filtered[this.group][this.id]);

    this.metric.setActive(visible && ((metric_level === this.group) || (metric_level === ViewModel.METRIC_LEVEL_ALL)));
    return this.vhMetric.setActive(visible && (metric_level === ViewModel.METRIC_LEVEL_VHOSTS));
  }


  setBreaching(breaches) {
    if ((breaches[this.group] != null) && breaches[this.group][this.id]) {
      if (!this.breaching) {
        this.breaching = true;
        if (this.visible) { return this.breach    = new Breacher(this.group, this.id, this.alertGfx, this.x, this.y, this.width, this.height, RackObject.MODEL, !this.placedInHoldingArea()); }
      }
    } else {
      this.breaching = false;
      if (this.breach != null) {
        this.breach.destroy();
        return this.breach = null;
      }
    }
  }
};

export default Machine;
