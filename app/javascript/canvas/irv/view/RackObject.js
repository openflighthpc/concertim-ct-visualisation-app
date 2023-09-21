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
// super class to Rack, Chassis, and Machine


import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import Easing from 'canvas/common/gfx/Easing';
import RackSpaceObject from 'canvas/irv/view/RackSpaceObject';
import ViewModel from 'canvas/irv/ViewModel';
import Profiler from 'Profiler'

class RackObject extends RackSpaceObject {
  static initClass() {
    // statics overwritten by config
    this.BLANK_FILL         = '#557744';
    this.METRIC_FADE_FILL   = '#ffffff';
    this.METRIC_FADE_ALPHA  = .1;
    this.IMAGE_PATH         = '';
    this.EXCLUDED_ALPHA     = 0.5;
    this.U_PX_HEIGHT        = 50;

    // run-time assigned statics
    this.RACK_GFX   = null;
    this.INFO_GFX   = null;
    this.RACK_INFO_GFX   = null;
    this.ALERT_GFX  = null;
    this.MODEL      = null;
    this.HOLDING_AREA_GFX  = null;
  }

  constructor(def, group, parent1) {
    super(...arguments);
    this.create_request = this.create_request.bind(this);
    this.sendConfirmation = this.sendConfirmation.bind(this);
    this.setLayers = this.setLayers.bind(this);
    this.group = group;
    this.parent = parent1;
    this.gfx           = RackObject.RACK_GFX;
    this.infoGfx       = RackObject.INFO_GFX;
    this.rackInfoGfx   = RackObject.RACK_INFO_GFX;
    this.alertGfx      = RackObject.ALERT_GFX;
    this.focused       = def.focused || false;

    this.id            = def.id;
    this.name          = def.name;
    this.comparisonName = this.name.toLowerCase();

    this.parent = ko.observable(this.parent);
    this.parent.subscribe(this.setLayers);

    this.setLayers();

    this.availableSpaces = [];

    this.template      = def.template;
    this.children      = [];
    this.subscriptions = [];
    this.frontFacing   = (def.facing === 'f') || (def.facing == null);
    this.bothView      = (def.bothView != null) ? def.bothView : ((this.parent() != null) ? this.parent().bothView : null);

    let parent = this.parent();
    while (parent != null) {
      if (parent.frontFacing !== undefined) { this.frontFacing = parent.frontFacing; }
      parent       = parent.parent();
    }

    console.log(RackObject.MODEL)
    if (RackObject.MODEL.deviceLookup()[this.group][this.id] == null) {
      def.instances = [];
      RackObject.MODEL.deviceLookup()[this.group][this.id] = def;
    }

    RackObject.MODEL.deviceLookup()[this.group][this.id].instances.push(this);
  }

  // Function to validate if this device is viewable from the current_face of the rack.
  // If a device is full depth, is always viewable
  // If a device is placed in the current face, the is also always viewable
  // If a device is not placed in the current face, but has not other device blocking/covering it, then is viewable.
  viewableDevice() {
    if (this.fullDepth() || this.placedInCurrentFace() || this.noDeviceBlocking()) {
      return true;
    } else {
      return false;
    }
  }

  // Validates if device is full depth
  fullDepth() {
    if (this.depth() === 2) {
      return true;
    } else {
      return false;
    }
  }

  // Validates if device is placed in the current face of the rack
  placedInCurrentFace() {
    const current_face = this.currentFace();
    
    if (((current_face === 'front') && (this.facing === 'f')) || ((current_face === 'rear') && (this.facing === 'b'))) {
      return true;
    } else {
      return false;
    }
  }

  // Check if there is a device in the way blocking the current one.
  // The nonRack function could have been used here at the beginning of the if, but since the rack object
  // its also used in the rest of the conditions, we better get the rack once, and use it in all the conditions.
  noDeviceBlocking() {
    const rack = this.rack();
    const uStart = this.uStart();
    if ((rack === null) || ((this.facing === 'b') && (rack.uOccupiedFront[uStart] === undefined)) || ((this.facing === 'f') && (rack.uOccupiedRear[uStart] === undefined))) {
      return true;
    } else {
      return false;
    }
  }

  // Validates if device is non rack (has no rack associated)
  nonRack() {
    return this.rack() === null;
  }

  // If the model.face is both, then this device's rack current face is stored in @bothView
  // otherwise, the current face is the model.face
  currentFace() {
    let current_face;
    if (RackObject.MODEL.face() === ViewModel.FACE_BOTH) {
      current_face = this.bothView;
    } else {
      current_face = RackObject.MODEL.face();
    }

    return current_face;
  }

  infoLayer() {
    return RackObject.RACK_INFO_GFX;
  }

  fadeInMetrics() {
    if ((this.metric != null ? this.metric.active : undefined) === true) {
      return this.metric.fadeIn();
    } else {
      return Array.from(this.children).map((child) => child.fadeInMetrics());
    }
  }

  fadeOutMetrics() {
    if ((this.metric != null ? this.metric.active : undefined) === true) {
      return this.metric.fadeOut();
    } else {
      return Array.from(this.children).map((child) => child.fadeOutMetrics());
    }
  }

  hasFocus() {
    return this.focused || false;
  }

  clearFocus() {
    return this.focused = false;
  }

  setFocus() {
    return this.focused = true;
  }

  facingFront() {
    return this.facing === 'f';
  }

  facingRear() {
    return this.facing === 'b';
  }

  showNameLabel(visible) {
    if (this.nameLabel == null) { return; }
    if (visible) {
      this.nameLabel.draw()
    } else {
      this.nameLabel.remove()
    }
  }

  getNearestSpace(x, y) {
    let nearest;
    let min_dist = Number.MAX_VALUE;
    for (var space of Array.from(this.availableSpaces)) {
      var dist_x, dist_y;
      if (Math.abs(space.left - x) < Math.abs(space.right - x)) {
        dist_x = space.left - x;
      } else {
        dist_x = space.right - x;
      }
      if (Math.abs(space.top - y) > Math.abs(space.bottom - y)) {
        dist_y = space.top - y;
      } else {
        dist_y = space.bottom - y;
      }
      var dist = Math.pow(dist_x, 2) + Math.pow(dist_y, 2);

      if (dist < min_dist) {
        nearest    = space;
        min_dist   = dist;
        space.dist = dist;
      }
    }

    return nearest;
  }

  selectOtherInstances() {
    if (RackObject.MODEL.deviceLookup()[this.group][this.id] != null) {
      return (() => {
        const result = [];
        for (var oneInstance of Array.from(RackObject.MODEL.deviceLookup()[this.group][this.id].instances)) {
          if (this !== oneInstance) { result.push(oneInstance.select()); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }
  }

  deselectOtherInstances() {
    if (RackObject.MODEL.deviceLookup()[this.group][this.id] != null) {
      return (() => {
        const result = [];
        for (var oneInstance of Array.from(RackObject.MODEL.deviceLookup()[this.group][this.id].instances)) {
          if (this !== oneInstance) { result.push(oneInstance.deselect()); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }
  }

  destroy() {
    const device_lookup = RackObject.MODEL.deviceLookup();

    if ((device_lookup[this.group][this.id] != null) && (device_lookup[this.group][this.id].instances != null)) {
      const {
        instances
      } = device_lookup[this.group][this.id];
      const idx       = Util.arrayIndexOf(instances, this);
    
      if (idx !== -1) { instances.splice(idx, 1); }
    }

    for (var sub of Array.from(this.subscriptions)) { sub.dispose(); }
    for (var child of Array.from(this.children)) { child.destroy(); }
    for (var asset of Array.from(this.assets)) { RackObject.RACK_GFX.remove(asset); }
    delete RackObject.MODEL.deviceLookup()[this.group][this.id];
    return this.assets = [];
  }

  create_request(ev) {
    return new Request.JSON({
      headers    : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url: '/api/v1/irv/'+this.group+'/'+this.id+'/'+this.conf.action+'/',
      onSuccess: this.sendConfirmation,
      onFail: this.loadError,
      onError: this.loadError,
      data: this.conf.data
    }).send();
  }

  sendConfirmation(config) {
    if (this.conf.action === "update_position") {
      return this.sendMessageMovingDevice(config.success);
    } else if (this.conf.action === "update_slot") {
      return this.sendMessageMovingBlade(config.success);
    }
  }

  sendMessageMovingDevice(config_success) {
    if (config_success === true) {
      let name_to_show, type_to_show;
      if (this.complex) {
        name_to_show = this.name; 
        type_to_show = "Chassis";
      } else { 
        name_to_show = this.children[0].name;
        type_to_show = "Device";
      }
      Events.dispatchEvent(RackObject.RACK_GFX.containerEl, 'getModifiedRackIds');
    } else {
      alert_dialog("Device "+this.conf.action+" error!");
    }
  }

  sendMessageMovingBlade(config_success) {
    if (config_success === true) {
      const name_to_show = this.name; 
      Events.dispatchEvent(RackObject.RACK_GFX.containerEl, 'getModifiedRackIds');
    } else {
      alert_dialog("Blade "+this.conf.action+" error!");
    }
  }

  loadError(failee) {
    return console.log("RackObject ERROR::: ",this,failee);
  }

  placedInCurrentView() {
    const current_view = (this.bothView != null) ? this.bothView : RackObject.MODEL.face();
    if (this.depth() === 1) {
      return ((current_view === "front") && this.facingFront()) || ((current_view === "rear") && this.facingRear());
    } else {
      return true;
    }
  }

  deviceLookup() {
    return RackObject.MODEL.deviceLookup();
  }

  getBlanker(width, height) {
    // create blank image where none has been supplied. Might be good to cache these
    // (using dims as a lookup) to reduce processing and memory usage a little
    const cvs        = document.createElement('canvas');
    cvs.width  = width;
    cvs.height = height;

    const ctx = cvs.getContext('2d');
    ctx.beginPath();
    ctx.fillStyle = RackObject.BLANK_FILL;
    ctx.fillRect(0, 0, cvs.width, cvs.height);
    return cvs;
  }

  placedInHoldingArea() {
    if ((this.parent() != null) && (this.parent().placedInHoldingArea() === true)) {
      return true;
    } else {
      return false;
    }
  }

  hide() {
    this.hideMetric();
    this.visible = false;
    for (var asset of Array.from(this.assets)) { this.gfx.remove(asset); }
    this.assets = [];
    return Array.from(this.children).map((child) => child.hide());
  }

  hideMetric() {
    if (this.metric != null) { return this.metric.hide(); }
  }

  draw() {
    Profiler.begin(Profiler.DEBUG, this.draw, this.name);
    for (var child of Array.from(this.children)) { child.draw(); }
    return Profiler.end(Profiler.DEBUG, this.draw);
  }


  // determins wether rack object should be included. 
  // Returns true if this instance or any single child is included in the filter and selection and metricdata (for those that exist)
  // If a device is not included, it will be grayed out
  setIncluded() {
    let child_included = false;
    for (var child of Array.from(this.children)) {
      if (child.setIncluded()) { child_included = true; }
    }
    return this.included = child_included || ((this.noAciveSelection() || this.isInActiveSelection()) && (this.noAciveFilter() || this.isInActiveFilter()) && (this.noMetricSelection() || this.isInMetricSelection()));
  }

  noAciveSelection() {
    return !RackObject.MODEL.activeSelection();
  }

  isInActiveSelection() {
    return (RackObject.MODEL.selectedDevices()[this.group] != null) && RackObject.MODEL.selectedDevices()[this.group][this.id];
  }

  noMetricSelection() {
    return (RackObject.MODEL.metricData().selection == null);
  }

  isInMetricSelection() {
    return RackObject.MODEL.metricData().selection[this.group][this.id];
  }

  noAciveFilter() {
    return !RackObject.MODEL.activeFilter();
  }

  isInActiveFilter() {
    return RackObject.MODEL.filteredDevices()[this.group][this.id];
  }


  updateIncluded(new_value) {
    this.included = new_value;
    return Array.from(this.children).map((child) =>
      child.updateIncluded(new_value));
  }

  // detects if this rack object or any of it's children are positioned within a specified box.
  // Inclusive selections (object touches box) and exlusive selections (object is contained by box)
  // Box object requires properties: top, bottom, left, right
  selectWithin(box, inclusive) {
    let child, group, i, subselection, test_contained_h, test_contained_v;
    const groups   = RackObject.MODEL.groups();
    const selected = {};
    for (group of Array.from(groups)) { selected[group] = {}; }

    if (inclusive) {
      const test_left        = (box.left >= this.x) && (box.left <= (this.x + this.width));
      const test_right       = (box.right >= this.x) && (box.right <= (this.x + this.width));
      test_contained_h = (box.left < this.x) && (box.right > (this.x + this.width));
      const test_top         = (box.top >= this.y) && (box.top <= (this.y + this.height));
      const test_bottom      = (box.bottom >= this.y) && (box.bottom <= (this.y + this.height));
      test_contained_v = (box.top < this.y) && (box.bottom > (this.y + this.height));

      if ((test_left || test_right || test_contained_h) && (test_top || test_bottom || test_contained_v)) {
        selected[this.group][this.id] = true;
        for (child of Array.from(this.children)) {
          subselection = child.selectWithin(box, inclusive);
          for (group of Array.from(groups)) {
            for (i in subselection[group]) {
              if (!isNaN(Number(subselection[group][i]))) { selected[group][i] = true; }
            }
          }
        }
      }
    } else {
      test_contained_h = (box.left <= this.x) && (box.right >= (this.x + this.width));
      test_contained_v = (box.top <= this.y) && (box.bottom >= (this.y + this.height));
    
      if (test_contained_h && test_contained_v) {
        selected[this.group][this.id] = true;
      }

      for (child of Array.from(this.children)) {
        subselection = child.selectWithin(box, inclusive);
        for (group of Array.from(groups)) {
          for (i in subselection[group]) {
            if (!isNaN(Number(subselection[group][i]))) { selected[group][i] = true; }
          }
        }
      }
    }

    return selected;
  }


  isHighlighted() {
    return (this.highlight != null);
  }

  getInstances() {
    return this.deviceLookup()[this.group][this.id].instances;
  }

  setLayers() {
    if (this.placedInHoldingArea()) {
      this.gfx       = RackObject.HOLDING_AREA_GFX;
      this.infoGfx   = RackObject.HOLDING_AREA_INFO_GFX;
      this.alertGfx  = RackObject.HOLDING_AREA_ALERT_GFX;
      this.rackInfoGfx   = RackObject.HOLDING_AREA_INFO_GFX;
    } else {
      this.gfx       = RackObject.RACK_GFX;
      this.infoGfx   = RackObject.INFO_GFX;
      this.alertGfx  = RackObject.ALERT_GFX;
      this.rackInfoGfx = RackObject.RACK_INFO_GFX;
    }
    if (this.children != null) {
      return Array.from(this.children).map((child) => child.setLayers());
    }
  }
};
RackObject.initClass();
export default RackObject;
