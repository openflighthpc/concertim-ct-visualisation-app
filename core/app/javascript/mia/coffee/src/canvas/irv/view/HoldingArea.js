/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import RackSpaceObject from 'canvas/irv/view/RackSpaceObject';
import  RackObject from 'canvas/irv/view/RackObject';
import  Util from 'canvas/common/util/Util';
import  Events from 'canvas/common/util/Events';
import  SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import  Easing from 'canvas/common/gfx/Easing';
import  MessageHint from 'canvas/irv/view/MessageHint';
import  RackHint from 'canvas/irv/view/RackHint';
import  ContextMenu from 'canvas/irv/view/ContextMenu';
import  ViewModel from 'canvas/irv/ViewModel';


class HoldingArea extends RackSpaceObject {
  static initClass() {

    this.EXTERNAL_BACKGROUND_COLOR  = "9C9C9C";
    this.BACKGROUND_COLOR  = "848484";
    this.BACKGROUND_ALPHA  = 0.5;
    this.COLUMNS           = 1;
    this.EXTERNAL_COLUMNS  = 3;
    this.GENERAL_STEP      = 20;
    this.MOVE_DELAY        = 250;
  }

  constructor(conf) {
    super(...arguments);
    this.executeMove = this.executeMove.bind(this);
    this.evZoomReady = this.evZoomReady.bind(this);
    this.evHoldingAreaZoomComplete = this.evHoldingAreaZoomComplete.bind(this);
    this.evZoomComplete = this.evZoomComplete.bind(this);
    this.conf = conf;
    this.parent = ko.observable();

    this.zoomPresets = [1/3,2/3,1];
    this.inverse = [1,2,3];
    this.zoomIdx = 0;
    this.factor = this.zoomPresets[this.zoomIdx];
    this.face = ViewModel.FACE_FRONT;

    this.external_x = 0;
    this.external_y = 0;
  
    this.x = this.external_x + this.conf.rackHorizontalPadding;
    this.y = this.external_y + this.conf.internalTopPadding;

    this.width  = ((this.conf.rackWidth * HoldingArea.EXTERNAL_COLUMNS) + (this.conf.rackHorizontalPadding * (HoldingArea.EXTERNAL_COLUMNS - 1)))*this.zoomPresets[0];
    this.columnWidth = this.conf.rackWidth;
    this.height = this.conf.height * this.conf.uPxHeight * this.zoomPresets[0];

    this.external_width  = this.width + (this.conf.rackHorizontalPadding * 2);
    this.external_height = this.height + this.conf.internalTopPadding + this.conf.internalBottomPadding;

    this.model = conf.model;
    this.assets = [];
    this.children = [];
    this.next_device_y = this.y;

    this.frontFacing = true;
    this.zooming = false;
    this.infoFadeDuration = this.conf.infoFadeDuration;
    this.StepX = 0;
    this.StepY = 0;

    this.rackEl = this.conf.rackEl;
    this.coordReferenceEl = this.conf.coordReferenceEl;

    this.gfxWidth = (this.conf.rackWidth * HoldingArea.EXTERNAL_COLUMNS) + (this.conf.rackHorizontalPadding * (HoldingArea.EXTERNAL_COLUMNS - 1));
    this.gfxHeight = this.conf.height * this.conf.uPxHeight;

    this.gfxBackgroundWidth = this.gfxWidth + (this.conf.rackHorizontalPadding * 2) + 500;
    this.gfxBackgroundHeight = this.gfxHeight + this.conf.internalTopPadding + this.conf.internalBottomPadding + 500;
  }

  show() {
    return this.draw();
  }

  hide() {
    let asset;
    for (asset of Array.from(this.assets)) { RackObject.HOLDING_AREA_BACKGROUND_GFX.remove(asset); }
    for (asset of Array.from(this.assets)) { RackObject.HOLDING_AREA_GFX.remove(asset); }
    RackObject.HOLDING_AREA_GFX.setDims(0,0);
    RackObject.HOLDING_AREA_INFO_GFX.setDims(0,0);
    RackObject.HOLDING_AREA_ALERT_GFX.setDims(0,0);
    RackObject.HOLDING_AREA_BACKGROUND_GFX.setDims(0,0);
    return (() => {
      const result = [];
      for (var oneNonRack of Array.from(this.children)) {
        oneNonRack.updateIncluded(false);
        result.push(oneNonRack.hide());
      }
      return result;
    })();
  }

  drawBackGround() {
    const external_config = {
                        x: this.external_x, y: this.external_y,
                        width: this.external_width, height: this.external_height,
                        fill: HoldingArea.EXTERNAL_BACKGROUND_COLOR, alpha: HoldingArea.BACKGROUND_ALPHA
                      };

    const internal_config = {
                        x: this.x, y: this.y, width: this.width, height: this.height,
                        fill: HoldingArea.BACKGROUND_COLOR, alpha: HoldingArea.BACKGROUND_ALPHA
                      };

    this.assets.push(RackObject.HOLDING_AREA_BACKGROUND_GFX.addRect(external_config));
    return this.assets.push(RackObject.HOLDING_AREA_BACKGROUND_GFX.addRect(internal_config));
  }

  isHoldingArea() {
    return true;
  }

  add(oneNonRack) {
    return this.children.push(oneNonRack);
  }

  setNonRackChassis(non_rack_chassis_array) {
    return this.children = non_rack_chassis_array;
  }

  remove(oneNonRackId) {
    let index, oneChild;
    let childToBeReturned = null;
    const iterable = this.model.nonrackDevices();
    for (index = 0; index < iterable.length; index++) {
      oneChild = iterable[index];
      if (oneChild.id === oneNonRackId) {
        this.model.nonrackDevices().splice(index, 1);
        childToBeReturned = oneChild;
        break;
      }
    }
    for (index = 0; index < this.children.length; index++) {
      oneChild = this.children[index];
      if (oneChild.id === oneNonRackId) {
        this.children.splice(index, 1);
        break;
      }
    }
    return childToBeReturned;
  }

  updateCoordinatesOfChildren() {
    this.next_device_y = HoldingArea.GENERAL_STEP;
    this.next_device_x = HoldingArea.GENERAL_STEP;
    this.lowest_device_position = 0;
    const height_limit = ((this.height/this.zoomPresets[0]) + (HoldingArea.GENERAL_STEP*this.StepY));
    return (() => {
      const result = [];
      for (var oneChild of Array.from(this.children)) {
        if ((this.next_device_y + oneChild.height) > height_limit) {
          this.next_device_y = (HoldingArea.GENERAL_STEP*this.StepY);
          this.next_device_x += this.columnWidth;
        }
        oneChild.setCoords(this.next_device_x+(HoldingArea.GENERAL_STEP*this.StepX),this.next_device_y+(HoldingArea.GENERAL_STEP*this.StepY));
        this.next_device_y += oneChild.height;

        if ((oneChild.y + oneChild.height) > this.lowest_device_position) { result.push(this.lowest_device_position = (oneChild.y + oneChild.height)); } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  draw() {
    let asset;
    for (asset of Array.from(this.assets)) { RackObject.HOLDING_AREA_BACKGROUND_GFX.remove(asset); }
    for (asset of Array.from(this.assets)) { RackObject.HOLDING_AREA_GFX.remove(asset); }
    const size_factor = (1/this.inverse[this.zoomIdx]) * this.inverse[this.conf.zoomIdx];
    RackObject.HOLDING_AREA_GFX.setDims(this.gfxWidth*size_factor, this.gfxHeight*size_factor);
    RackObject.HOLDING_AREA_INFO_GFX.setDims(this.gfxWidth*size_factor, this.gfxHeight*size_factor);
    RackObject.HOLDING_AREA_ALERT_GFX.setDims(this.gfxWidth*size_factor, this.gfxHeight*size_factor);
    RackObject.HOLDING_AREA_BACKGROUND_GFX.setDims(this.gfxBackgroundWidth*this.factor, this.gfxBackgroundHeight*this.factor);
    this.assets = [];
    this.drawBackGround();
    Util.sortByProperty(this.children, 'comparisonName', true);
    this.updateCoordinatesOfChildren();
    return (() => {
      const result = [];
      for (var oneNonRack of Array.from(this.children)) {
        oneNonRack.updateIncluded(true);
        result.push(oneNonRack.draw());
      }
      return result;
    })(); 
  }

  x_off_set() {
    return Util.getStyleNumeric(this.coordReferenceEl,'left') / this.model.scale();
  }

  getDeviceAt(x, y) {
    const x_y = this.getInternalMouseCoords();
    ({
      x
    } = x_y);
    ({
      y
    } = x_y);
    return super.getDeviceAt(x,y);
  }

  getMouseCoords() {
    const coords = Util.resolveMouseCoords(RackObject.HOLDING_AREA_GFX.cvs, this.ev);
    const x = coords.x/this.model.scale();
    const y = coords.y/this.model.scale();
    return {x, y};
  }

  getInternalMouseCoords() {
    const x_y = this.getMouseCoords();
    const x = x_y.x/this.factor;
    const y = x_y.y/this.factor;
    return {x, y};
  }

  overTheHoldingArea() {
    const x_y = this.getMouseCoords();
    const x = x_y.x + this.x;
    const y = x_y.y + this.y;
    if ((x > this.external_x) && (x < (this.external_x + this.external_width)) && (y > this.external_y) && (y < (this.external_y + this.external_height))) {
      return true;
    } else {
      return false;
    }
  }

  overInternalArea(x, y) {
    const x_y = this.getMouseCoords();
    ({
      x
    } = x_y);
    ({
      y
    } = x_y);
    if ((x > this.x) && (x < (this.x + this.width)) && (y > this.y) && (y < (this.y + this.height))) {
      return true;
    } else {
      return false;
    }
  }

  overTheEdges() {
    const x_y = this.getMouseCoords();
    const x = x_y.x + this.x;
    const y = x_y.y + this.y;
    this.edge = 0;
    if ((x > (this.x + this.width)) && (x < (this.external_x + this.external_width)) && (y > this.y) && (y < (this.y + this.height))) {
      this.edge = 4; //mouse on the right, move devices to the left
    }
    if ((x > this.x) && (x < (this.x + this.width)) && (y > this.external_y) && (y < this.y)) {
      this.edge = 3; //mouse on the top, move devices down
    }
    if ((x > this.external_x) && (x < this.x) && (y > this.y) && (y < (this.y + this.height))) {
      this.edge = 2; //mouse on the left, move devices to the right
    }
    if ((x > this.x) && (x < (this.x + this.width)) && (y > (this.y + this.height)) && (y < (this.external_y + this.external_height))) {
      this.edge = 1; //mouse at the bottom, move devices up
    }
    return this.edge;
  }
  
  move() {
    if (this.edge === 4) { //move to the left
      this.moveStepIncrementX = -1;
      this.moveStepIncrementY = 0;
    }
    if (this.edge === 3) { //move down
      this.moveStepIncrementX = 0;
      this.moveStepIncrementY = 1;
    }
    if (this.edge === 2) { //move to the right
      this.moveStepIncrementX = 1;
      this.moveStepIncrementY = 0;
    }
    if (this.edge === 1) { //move up
      this.moveStepIncrementX = 0;
      this.moveStepIncrementY = -1;
    }
    if ((this.edge > 0) && this.canBeMoved()) {
      this.moving = true;
      return setTimeout(this.executeMove, HoldingArea.MOVE_DELAY);
    }
  }

  executeMove() {
    this.draw();
    this.StepX = this.StepX + this.moveStepIncrementX;
    this.StepY = this.StepY + this.moveStepIncrementY;
    if (this.moving && this.canBeMoved()) {
      return setTimeout(this.executeMove, HoldingArea.MOVE_DELAY);
    }
  }

  canBeMoved() {
    if (this.children.length === 0) {
      return false;
    }
    if ((this.edge === 1) && (this.lowest_device_position < (this.height/this.factor))) {
      return false;
    }
    if ((this.edge === 2) && (this.children[0].x > 0)) {
      return false;
    }
    if ((this.edge === 3) && (this.children[0].y >= 0)) {
      return false;
    }
    if ((this.edge === 4) && ((this.children.last().x+this.children.last().width) < (this.width/this.factor))) {
      return false;
    }
    return true;
  }

  zoomToPreset(direction, centre_x, centre_y) {
    if (direction == null) { direction = 1; }
    if (this.zooming) { return; }

    this.zoomIdx += direction;
    // cycle through presets
    if (this.zoomIdx >= this.zoomPresets.length) { this.zoomIdx = 0; }
    if (this.zoomIdx < 0) { this.zoomIdx = this.zoomPresets.length - 1; }
    this.quickZoom(centre_x, centre_y, this.zoomPresets[this.zoomIdx]);
    return this.factor = this.zoomPresets[this.zoomIdx];
  }

  quickZoom(centre_x, centre_y, new_scale) {
    if (this.zooming) { return; }

    new_scale = new_scale * RackObject.RACK_GFX.scale;

    const dims         = this.rackEl.getCoordinates();
    dims.width  -= this.scrollAdjust;
    dims.height -= this.scrollAdjust;

    // calculate centre coords according to target scale
    centre_x = centre_x / (this.scale / new_scale);
    centre_y = centre_y / (this.scale / new_scale);

    // store current scroll
    this.scrollOffset = {
      x: this.rackEl.scrollLeft,
      y: this.rackEl.scrollTop
    };

    // calculate target coords according to top-left
    let target_x = centre_x - (dims.width / 2);
    let target_y = centre_y - (dims.height / 2);

    const target_width  = RackObject.HOLDING_AREA_GFX.width * new_scale;
    const target_height = RackObject.HOLDING_AREA_GFX.height * new_scale;

    // determine rack centreing offset at target scale
    let offset_x = (dims.width - target_width) / 2;
    let offset_y = (dims.height - target_height) / 2;
    if (offset_x < 0) { offset_x = 0; }
    if (offset_y < 0) { offset_y = 0; }

    // calculate boundaries of zoomed canvas
    const lh_bound  = -offset_x;
    const rh_bound  = (target_width - dims.width) + offset_x;
    const top_bound = -offset_y;
    const btm_bound = (target_height - dims.height) + offset_y;

    // retrict target coords to zoomed boundaries
    if (target_x > rh_bound) { target_x = rh_bound; }
    if (target_x < lh_bound) { target_x = lh_bound; }
    if (target_y > btm_bound) { target_y = btm_bound; }
    if (target_y < top_bound) { target_y = top_bound; }

    // store target offset
    this.targetOffset = {
      x: target_x,
      y: target_y
    };

    let current_offset_x = Util.getStyleNumeric(RackObject.HOLDING_AREA_GFX.cvs, 'left');
    let current_offset_y = Util.getStyleNumeric(RackObject.HOLDING_AREA_GFX.cvs, 'top');
    const lazy_factor      = 2;
  
    // only zoom if new scale is different to current and target scroll
    // is a significant change (greater than lazy factor)
    if ((new_scale === this.scale) && ((Math.abs(this.targetOffset.x - this.scrollOffset.x - current_offset_x) < lazy_factor) && (Math.abs(this.targetOffset.y - this.scrollOffset.y - current_offset_y) < lazy_factor))) {
      Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
      return;
    }

    // commence zoom
    this.zooming     = true;
    this.targetScale = new_scale;

    current_offset_x = Util.getStyleNumeric(RackObject.HOLDING_AREA_GFX.cvs, 'left');
    current_offset_y = Util.getStyleNumeric(RackObject.HOLDING_AREA_GFX.cvs, 'top');

    this.fxHoldingArea = this.createGfxLayer(this.rackEl, 0, 0, dims.width, dims.height);
    this.holdingAreaImg = this.fxHoldingArea.addImg({ img: RackObject.HOLDING_AREA_GFX.cvs, x: current_offset_x - this.scrollOffset.x, y: current_offset_y - this.scrollOffset.y });

    this.evZoomReady();

    RackObject.HOLDING_AREA_GFX.pauseAnims();

    // hide existing canvas layers
    this.rackEl.removeChild(RackObject.HOLDING_AREA_GFX.cvs);
    this.rackEl.removeChild(RackObject.HOLDING_AREA_INFO_GFX.cvs);
    this.rackEl.removeChild(RackObject.HOLDING_AREA_ALERT_GFX.cvs);

    // force immediate draw or we'll have a blank image for one frame
    return this.fxHoldingArea.redraw();
  }


  // called when info fade animation completes, sets the scale of hidden canvas layeres to the target zoom level and  commences
  // actual zoom animation
  evZoomReady() {
    const relative_scale = this.targetScale / RackObject.HOLDING_AREA_GFX.scale;

    return this.fxHoldingArea.animate(this.holdingAreaImg, {
      x      : -this.targetOffset.x,
      y      : -this.targetOffset.y,
      width  : RackObject.HOLDING_AREA_GFX.cvs.width * relative_scale,
      height : RackObject.HOLDING_AREA_GFX.cvs.height * relative_scale
    }
    , this.conf.zoomDuration, Easing.Quad.easeInOut, this.evHoldingAreaZoomComplete);
  }

  evHoldingAreaZoomComplete() {
    return this.evZoomComplete();
  }


  // called when all phases of zoom animation are complete, destroys fx layers, reveals hidden canvas layers and dispatches zoom complete
  // event
  evZoomComplete() {
    this.fxHoldingArea.destroy();
    this.updateCoordinatesOfChildren();

    this.draw();

    RackObject.HOLDING_AREA_GFX.setScale(this.targetScale);
    RackObject.HOLDING_AREA_INFO_GFX.setScale(this.targetScale);
    RackObject.HOLDING_AREA_ALERT_GFX.setScale(this.targetScale);

    this.rackEl.appendChild(RackObject.HOLDING_AREA_GFX.cvs);
    this.rackEl.appendChild(RackObject.HOLDING_AREA_INFO_GFX.cvs);
    this.rackEl.appendChild(RackObject.HOLDING_AREA_ALERT_GFX.cvs);

    this.rackEl.scrollLeft = this.targetOffset.x;
    this.rackEl.scrollTop  = this.targetOffset.y;

    RackObject.HOLDING_AREA_GFX.resumeAnims();

    this.scale = this.targetScale;
    this.zooming = false;

    return Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
  }

  // creates an instance of a SimpleRenderer layer
  // @param  container   a reference to a DOM element to which the layer will be appended
  // @param  x           float, the pixel x coordinate to position the new layer
  // @param  y           float, the pixel y coordinate to position the new layer
  // @param  width       int, the width of the layer
  // @param  height      int, the height of the new layer
  // @param  scale       optional float, the initial scale of the new layer
  createGfxLayer(container, x, y, width, height, scale) {
    if (scale == null) { scale = 1; }
    const gfx = new SimpleRenderer(container, width, height, scale, this.conf.fps);
    Util.setStyle(gfx.cvs, 'position', 'absolute');
    Util.setStyle(gfx.cvs, 'left', x + 'px');
    Util.setStyle(gfx.cvs, 'top', y + 'px');
    return gfx;
  }
};
HoldingArea.initClass();
export default HoldingArea;
