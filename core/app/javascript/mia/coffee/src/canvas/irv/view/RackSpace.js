/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// the RackSpace instanciates the racks and coordinates global operations and
// animations such as zooming and flipping between front and rear views

import CanvasSpace from 'canvas/common/CanvasSpace';
import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import CrossAppSettings from 'canvas/common/util/CrossAppSettings';
import Easing from 'canvas/common/gfx/Easing';
import RackObject from 'canvas/irv/view/RackObject';
import Rack from 'canvas/irv/view/Rack';
import Chassis from 'canvas/irv/view/Chassis';
import Machine from 'canvas/irv/view/Machine';
import Chart from 'canvas/irv/view/IRVChart';
import MessageHint from 'canvas/irv/view/MessageHint';
import RackHint from 'canvas/irv/view/RackHint';
import ContextMenu from 'canvas/irv/view/ContextMenu';
import ViewModel from 'canvas/irv/ViewModel';
import Link from 'canvas/irv/view/Link';
import ImageLink from 'canvas/irv/view/ImageLink';
import HoldingArea from 'canvas/irv/view/HoldingArea';
import DragPolicy from 'canvas/irv/util/DragPolicy';
import Profiler from 'Profiler';
import NameLabel from 'canvas/irv/view/NameLabel';

class RackSpace extends CanvasSpace {
  static initClass() {

    // statics overwritten by config

    this.DRAG_FADE_FILL   = '#0';
    this.DRAG_FADE_ALPHA  = .3;
    this.DRAG_SNAP_RANGE  = 10;
    this.DRAG_ITEM_ALPHA  = .5;

    this.METRIC_FADE_FILL   = '#000000';
    this.METRIC_FADE_ALPHA  = .7;

    this.SELECT_BOX_STROKE        = '#000000';
    this.SELECT_BOX_ALPHA         = 1;
    this.SELECT_BOX_STROKE_WIDTH  = 1;

    this.MOVING_DEVICE_STROKE_WIDTH  = 5;

    this.CHART_SELECTION_COUNT_FILL      = '#ffffff';
    this.CHART_SELECTION_COUNT_FONT      = '14px Karla';
    this.CHART_SELECTION_COUNT_BG_FILL   = '#000000';
    this.CHART_SELECTION_COUNT_BG_ALPHA  = 0.4;
    this.CHART_SELECTION_COUNT_CAPTION   = '[[selection_count]] metrics';
    this.CHART_SELECTION_COUNT_OFFSET_X  = 0;
    this.CHART_SELECTION_COUNT_OFFSET_Y  = -10;

    this.LAYOUT_UPDATE_DELAY       = 1500;
    this.ZOOM_DURATION             = 500;
    this.INFO_FADE_DURATION        = 200;
    this.FLIP_DURATION             = 500;
    this.FLIP_DELAY                = 200;
    this.CANVAS_MAX_DIMENSION      = 1000;

    // hardcoded and run-time assigned statics
    this.MIN_ZOOM  = null;
    this.MAX_ZOOM  = 1;
  }


  constructor(rackEl, chartEl, model, rackParent) {
    super(...arguments);
    let left;
    this.setLayout = this.setLayout.bind(this);
    this.highlightDevice = this.highlightDevice.bind(this);
    this.showSelection = this.showSelection.bind(this);
    this.draw = this.draw.bind(this);
    this.showHideHoldingArea = this.showHideHoldingArea.bind(this);
    this.switchFace = this.switchFace.bind(this);
    this.evFlipReady = this.evFlipReady.bind(this);
    this.evHalfFlipped = this.evHalfFlipped.bind(this);
    this.evFlipped = this.evFlipped.bind(this);
    this.evFlipComplete = this.evFlipComplete.bind(this);
    this.evZoomReady = this.evZoomReady.bind(this);
    this.evHoldingAreaZoomComplete = this.evHoldingAreaZoomComplete.bind(this);
    this.evRackZoomComplete = this.evRackZoomComplete.bind(this);
    this.evZoomComplete = this.evZoomComplete.bind(this);
    this.showHint = this.showHint.bind(this);
    this.evContextClick = this.evContextClick.bind(this);
    this.dragDeviceFromMenu = this.dragDeviceFromMenu.bind(this);
    this.stopDraggingDeviceFromMenu = this.stopDraggingDeviceFromMenu.bind(this);
    this.evRedrawComplete = this.evRedrawComplete.bind(this);
    this.switchView = this.switchView.bind(this);
    this.setMetricLevel = this.setMetricLevel.bind(this);
    this.rackEl = rackEl;
    this.chartEl = chartEl;
    this.model = model;
    this.rackParent = rackParent;
    Profiler.begin(Profiler.DEBUG);
    this.zooming     = false;
    this.flipping    = false;
    this.highlighted = [];
    this.dragging    = false;

    this.currentFace  = this.model.face();
    this.face = this.currentFace;

    this.scrollAdjust = Util.getScrollbarThickness();

    this.createGfx();

    RackObject.MODEL     = this.model;
    RackObject.RACK_GFX  = this.rackGfx;
    RackObject.INFO_GFX  = this.infoGfx;
    RackObject.RACK_INFO_GFX  = this.rackInfoGfx;
    RackObject.ALERT_GFX = this.alertGfx;

    RackObject.HOLDING_AREA_GFX = this.holdingAreaGfx;
    RackObject.HOLDING_AREA_INFO_GFX = this.holdingAreaInfoGfx;
    RackObject.HOLDING_AREA_ALERT_GFX = this.holdingAreaAlertGfx;
    RackObject.HOLDING_AREA_BACKGROUND_GFX = this.holdingAreaBackGroundGfx;

    if (this.model.showingRacks() && !this.model.showingFullIrv()) {
      RackSpace.PADDING = RackSpace.PADDING/2;
      RackSpace.RACK_V_SPACING = RackSpace.RACK_V_SPACING/2;
    }

    // makes position and size information accessible to the controller
    this.coordReferenceEl = this.alertGfx.cvs;

    this.zoomIdx = 0;
    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      this.holdingAreaConfig = this.holdingAreaConfig();
      this.holdingArea = new HoldingArea(this.holdingAreaConfig);
      this.setUpNonrackDevices();
    }

    if (this.model.showingRacks()) {
      this.setUpRacks();
    }
    
    // init scale
    this.setZoomPresets();
    this.scale   = this.zoomPresets[this.zoomIdx];
    this.model.scale(this.scale);
    this.rackGfx.setScale(this.scale);
    this.rackInfoGfx.setScale(this.scale);
    this.infoGfx.setScale(this.scale);
    this.alertGfx.setScale(this.scale);

    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      this.holdingAreaBackGroundGfx.setScale(this.scale);
      this.holdingAreaGfx.setScale(this.scale*this.holdingArea.factor);
      this.holdingAreaInfoGfx.setScale(this.scale*this.holdingArea.factor);
      this.holdingAreaAlertGfx.setScale(this.scale*this.holdingArea.factor);
    }

    this.draw();
    if (this.model.showingRacks()) { this.centreRacks(); }

    if (this.model.showChart()) { this.chart       = new Chart(this.chartEl, this.model); }
    this.hint        = new RackHint((left = $('tooltip').parentElement) != null ? left : $('tooltip').parentNode, this.model);
    this.contextMenu = new ContextMenu(this.rackEl, this.model, this.evContextClick);
    this.messageHint = new MessageHint();

    this.model.face.subscribe(this.switchFace);
    this.model.viewMode.subscribe(this.switchView);
    this.model.highlighted.subscribe(this.highlightDevice);
    this.model.filteredDevices.subscribe(this.showSelection);
    this.model.selectedDevices.subscribe(this.showSelection);
    this.model.showHoldingArea.subscribe(this.showHideHoldingArea);

    // While the early loading of the presets, a metric level could have been set but the previous
    // association was not yet created. So, lets check if there is a metric level, and run the function
    //if @model.showingFullIrv() and @model.metricLevel()? and @model.metricLevel() isnt "all"
    //  @setMetricLevel(@model.metricLevel())

    if (this.model.showingRacks() && !this.model.showingFullIrv()) {
      this.model.face(ViewModel.FACE_BOTH);
      this.centreRacks();
      this.model.activeSelection(true);
      for (var oneRack of Array.from(this.racks)) {
        for (var oneInstance of Array.from(this.model.deviceLookup().racks[oneRack.id].instances)) {
          oneInstance.included = true;
        }
      }
    }

    Profiler.end(Profiler.DEBUG);
  }

  // creates instances of SimpleRenderer, one for each layer required
  createGfx() {
    this.holdingAreaBackGroundGfx = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // Holding area background frame
    this.holdingAreaGfx = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // Holding area
    this.holdingAreaInfoGfx = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // Holding area
    this.holdingAreaAlertGfx = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // Holding area

    super.createGfx(...arguments);

    this.rackInfoGfx  = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // middle layer, draws the empty spaces for racks
    this.infoGfx  = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // middle layer, draws metric bars and textual labels
    this.alertGfx = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // top layer, draws highlights and breach boxes
    if (this.model.showingFullIrv()) {
      return this.countDownGfx = this.createGfxLayer(this.rackEl, 0, 0, 50, 50, 1);   // top layer, draws highlights and breach boxes
    }
  }

  holdingAreaConfig() {
    const rack_sizes = {topheight:50,topwidth:500,bottomheight:50,rackmaxu:42};
    return { 
      x:RackSpace.PADDING+RackSpace.RACK_H_SPACING,y:RackSpace.PADDING+rack_sizes.topheight,
      padding:RackSpace.PADDING,rackWidth:rack_sizes.topwidth,
      rackHorizontalPadding:RackSpace.RACK_H_SPACING,rackVerticalPadding:RackSpace.RACK_V_SPACING,
      height:rack_sizes.rackmaxu,uPxHeight:RackObject.U_PX_HEIGHT,
      internalTopPadding:rack_sizes.topheight,internalBottomPadding:rack_sizes.bottomheight,
      model:this.model,rackEl:this.rackEl,fadeDuration:RackSpace.INFO_FADE_DURATION,fps:RackSpace.FPS,zoomDuration:RackSpace.ZOOM_DURATION,
      zoomIdx: this.zoomIdx, coordReferenceEl: this.coordReferenceEl
    };
  }

  placeHoldingArea(scale) {
    let new_x = Util.getStyleNumeric(this.rackGfx.cvs, 'left');
    let new_y = Util.getStyleNumeric(this.rackGfx.cvs, 'top');
    new_x = new_x + this.rackGfx.cvs.width;
    new_y = new_y + (RackSpace.RACK_V_SPACING * scale);

    Util.setStyle(this.holdingAreaBackGroundGfx.cvs,  'left', new_x + 'px');
    Util.setStyle(this.holdingAreaBackGroundGfx.cvs,  'top',  new_y + 'px');

    new_x = new_x + (RackSpace.RACK_H_SPACING * scale);
    new_y = new_y + (RackSpace.RACK_H_SPACING * scale);

    Util.setStyle(this.holdingAreaGfx.cvs,            'left', new_x + 'px');
    Util.setStyle(this.holdingAreaGfx.cvs,            'top',  new_y + 'px');
    Util.setStyle(this.holdingAreaInfoGfx.cvs,        'left', new_x + 'px');
    Util.setStyle(this.holdingAreaInfoGfx.cvs,        'top',  new_y + 'px');
    Util.setStyle(this.holdingAreaAlertGfx.cvs,       'left', new_x + 'px');
    return Util.setStyle(this.holdingAreaAlertGfx.cvs,       'top',  new_y + 'px');
  }

  updateUrl(adding, extraPath){
    let document_url = document.URL;
    if (adding) {
      document_url = document_url + "/" + extraPath;
    } else {
      document_url = document_url.replace("/"+extraPath, "");
    }
    return window.history.pushState("","",document_url);
  }
    

  // instanciates racks using the list of rack definitions in the model, also calulates the px height of the tallest rack
  // and the row height (tallest rack + padding)
  setUpRacks() {
    if ((this.racks != null) && (this.racks.length > 0)) {
      for (var oneRack of Array.from(this.racks)) { oneRack.destroy(); }
    }
    this.racks = [];

    this.max_u  = 0;
    const racks  = this.model.racks();

    this.tallestRack = 0;
    for (var rack of Array.from(racks)) {
      if (rack.uHeight > this.max_u) { this.max_u = rack.uHeight; }
      var new_rack = new Rack(rack);

      this.racks.push(new_rack);
      if (new_rack.hasFocus()) {
        new_rack.refreshRackFocus(this.model);
      }
      var thisRackHeight = Rack.IMAGES_BY_TEMPLATE[rack.template.id].slices.front.top.height + Rack.IMAGES_BY_TEMPLATE[rack.template.id].slices.front.btm.height + (RackObject.U_PX_HEIGHT * rack.uHeight);
      if (thisRackHeight > this.tallestRack) { this.tallestRack = thisRackHeight; }
    }

    if (this.model.showingFullIrv()) {
      this.setUpDcrvShowableNonRackChassis();
    }

    if (this.tallestNonRackChassis > this.tallestRack) {
      this.tallestRack = this.tallestNonRackChassis;
    }

    if (this.model.showingFullIrv()) {
      this.tallestRack += NameLabel.SIZE + NameLabel.OFFSET_Y;
    }

    this.rowHeight   = (RackSpace.PADDING * 2) + this.tallestRack;

    this.arrangeRacks();
    return this.synchroniseZoomIdx();
  }


  parent() {
    return null;
  }

  //XXX This function should be refactored. There is no performance issue, just the logic to be improved.
  // If I import the HoldingArea class where this function is used, to check if parent is HoldingArea via intanceof,
  // require.js hangs (require.js load timeout) trying to load the classes. I guess is because it goes into a loop.
  isHoldingArea() {
    return false;
  }

  // instanciates non rack devices using the list of definitions in the model
  setUpNonrackDevices() {
    this.nonRackChassis = [];
    const nonrackDevices = this.model.nonrackDevices();
    if (!nonrackDevices) { return; }

    for (var oneNonRack of Array.from(nonrackDevices)) {
      var new_non_rack = new Chassis(oneNonRack,this.holdingArea);
      this.nonRackChassis.push(new_non_rack);
    }
    return this.holdingArea.setNonRackChassis(this.nonRackChassis);
  }

  setUpDcrvShowableNonRackChassis() {
    this.tallestNonRackChassis = 0;
    const setOfChassis = this.model.dcrvShowableNonRackChassis();
    return (() => {
      const result = [];
      for (var oneNonRack of Array.from(setOfChassis)) {
        var new_non_rack = new Chassis(oneNonRack,this);
        new_non_rack.visible = true;
        if (new_non_rack.height > this.tallestNonRackChassis) { this.tallestNonRackChassis = new_non_rack.height; }
        var index_new_item = this.racks.length;
        for (var i = 0; i < this.racks.length; i++) {
          var oneI = this.racks[i];
          if (new_non_rack.comparisonName < oneI.comparisonName) {
            index_new_item = i;
            break;
          }
        }
        result.push(this.racks.splice(index_new_item, 0, new_non_rack));
      }
      return result;
    })();
  }

  // public method, called whenver div dimensions change, actions update on a timeout to prevent overloading
  updateLayout() {
    // throttle the number of updates being executed using a timeout
    clearTimeout(this.layoutTmr);
    return this.layoutTmr = setTimeout(this.setLayout, RackSpace.LAYOUT_UPDATE_DELAY);
  }


  // called on a timeout, resizes visual assets to fit available space, recalculates any dependant values such as zoom presets
  setLayout() {
    const showing_all = this.scale === RackSpace.MIN_ZOOM;
  
    if (this.chart != null) { this.chart.updateLayout(); }
    if (this.model.showingRacks()) { this.arrangeRacks(); }
    this.setZoomPresets();
    this.synchroniseZoomIdx();
    if ((this.scale <= RackSpace.MIN_ZOOM) || showing_all) {
      this.zoomIdx = 0;
      this.scale   = this.zoomPresets[0];
      this.model.scale(this.scale);
      this.setScaleInLayers();
      this.draw();
    }
    if (this.model.showingRacks()) { return this.centreRacks(); }
  }

  setScaleInLayers() {
    this.rackGfx.setScale(this.scale);
    this.rackInfoGfx.setScale(this.scale);
    this.infoGfx.setScale(this.scale);
    this.alertGfx.setScale(this.scale);
    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      this.holdingAreaBackGroundGfx.setScale(this.scale);
      this.holdingAreaGfx.setScale(this.scale*this.holdingArea.factor);
      this.holdingAreaInfoGfx.setScale(this.scale*this.holdingArea.factor);
      this.holdingAreaAlertGfx.setScale(this.scale*this.holdingArea.factor);
      return this.placeHoldingArea(this.scale);
    }
  }

  // calculates preset zoom levels as an array of floats, these are: show all, fit to row and maximum. Show all and fit to row may be the
  // same value in which case only two presets will be present in the array
  setZoomPresets() {
    let scale_x, scale_y, show_all;
    this.zoomPresets = [];
    const dims         = this.rackEl.getCoordinates();

    // Zoom presets for DCRV
    if (this.model.showingFullIrv()) {
      scale_x = (dims.width - this.scrollAdjust) / this.racksWidth;
      scale_y = (dims.height - this.scrollAdjust) / this.racksHeight;

      show_all     = scale_x > scale_y ? scale_y : scale_x;
      const scale_to_row = dims.height / this.rowHeight;

      // show all and scale to row could be the same
      if ((show_all !== scale_to_row) && (this.num_rows > 1)) { this.zoomPresets.push(show_all); }
      // max zoom could be less than scale-to-row when restricting to max canvas size
      if (RackSpace.MAX_ZOOM > scale_to_row) { this.zoomPresets.push(scale_to_row); }
      this.zoomPresets.push(RackSpace.MAX_ZOOM);

    // Zoom presets for single rack view
    } else if (this.model.showingRacks()) {
      scale_x = dims.width / this.racksWidth;
      scale_y = dims.height / (this.tallestRack + (RackSpace.PADDING*2));
      show_all = scale_x > scale_y ? scale_y : scale_x;
      if (!(show_all > RackSpace.MAX_ZOOM)) { this.zoomPresets.push(show_all); }
      this.zoomPresets.push(RackSpace.MAX_ZOOM);
    }

    return RackSpace.MIN_ZOOM = this.zoomPresets[0];
  }


  // show a highlight over a device based on mouse position
  // @params x   the x coordinate of the mouse
  // @params y   the y coordinate of the mouse
  highlightAt(x, y) {
    if (this.contextMenu.visible) { return; }

    x /= this.scale;
    y /= this.scale;

    let device = this.getDeviceAt(x, y);

    if (device instanceof Rack) {
      device = null;
    } else if ((device != null) && device.pluggable && (this.metricLevel === 'chassis')) {
      device = device.parent();
    }

    const highlighted = this.model.highlighted();

    if (highlighted[0] !== device) {
      if (device != null) {
        return this.model.highlighted([device]);
      } else {
        return this.model.highlighted([]);
      }
    }
  }


  // highlighted model value subscriber, adds highlighting to devices
  // @param  highlighted   array, the list of devices to highlight
  highlightDevice(highlighted) {
    this.removeHighlights();

    for (var device of Array.from(highlighted)) {
      if (!device.isHighlighted()) { device.select(); }
    }

    return this.highlighted = highlighted;
  }


  // removes highlighting from currently highlighted devices
  removeHighlights() {
    for (var device of Array.from(this.highlighted)) { 
      device.deselect();
    }
    return this.highlighted = [];
  }

  // public method, clears all highlighted devices via the model
  clearHighlights() {
    if (!this.contextMenu.visible) { return this.model.highlighted([]); }
  }


  // filteredDevices and selectedDevices model values subscriber, updates what devices are included by a selection or filter and redraws
  // An object is included if it satisfies the filter and/or selection OR if any child object does, e.g. a complex chassis will be included
  // if any of it's blades are included even if the chassis itself does not satisfy the filter/selection
  showSelection() {
    for (var rack of Array.from(this.racks)) { rack.setIncluded(); }
    return this.draw();
  }


  // draw all racks
  draw() {
    Profiler.begin(Profiler.CRITICAL);

    if (this.racks == null || this.racks.length === 0) {
      $('zero-racks-message').removeClass('hidden');
    } else {
      $('zero-racks-message').addClass('hidden');
    }

    const show_u_labels = this.scale >= CanvasSpace.U_LBL_SCALE_CUTOFF;
    const show_name_label = this.scale >= CanvasSpace.NAME_LBL_SCALE_CUTOFF;
    const show_owner_label = show_name_label && this.model.RBAC.can_i("view", "all");
    if (this.model.showingRacks()) {
      for (var rack of Array.from(this.racks)) { rack.draw(show_u_labels, show_name_label, show_owner_label); }
      this.updateRackImage();
    }
    if (this.model.showHoldingArea()) {
      this.holdingArea.draw();
    }
    return Profiler.end(Profiler.CRITICAL);
  }

  // showHideHoldingArea 
  showHideHoldingArea() {
    this.setUpRacks();
    this.draw();
    this.centreRacks();
    this.placeHoldingArea(this.scale);
    this.setMetricLevel(this.model.metricLevel());
    if (!this.model.showHoldingArea()) {
      this.holdingArea.hide();
    }
    return Events.dispatchEvent(this.rackEl, 'reloadMetrics');
  }

  // 'face' model value subscriber, commences flip animation or switches in and out of both view mode
  // @param  face  the new value of face
  switchFace(face) {
    if (face === ViewModel.FACE_BOTH) {
      this.showSplitView();
    } else if (this.currentFace === ViewModel.FACE_BOTH) {
      this.revertFromSplitView();
    } else {
      this.flip();
    }

    if (this.chart != null) { this.chart.updateLayout(); }
    return this.currentFace = face;
  }

  synchroniseNonRackDevices(non_rack_defs, change_set) {
    let idx, one_chassis;
    if ((change_set == null) || (non_rack_defs == null)) { return; }
    this.model.activeSelection(false);
    const device_lookup = this.model.deviceLookup();
    const dcrvShowableNonRackChassis  = this.model.dcrvShowableNonRackChassis();
  
    for (var deleted_id of Array.from(change_set.deleted)) {
      var iterable = dcrvShowableNonRackChassis.slice(0).reverse();
      for (idx = 0; idx < iterable.length; idx++) {
        one_chassis = iterable[idx];
        if (one_chassis.id === deleted_id) {
          dcrvShowableNonRackChassis.splice(dcrvShowableNonRackChassis.indexOf(one_chassis), 1);
        }
      }
  
      delete device_lookup.chassis[deleted_id];
    }

    return (() => {
      const result = [];
      for (var one_chassis_def of Array.from(non_rack_defs)) {
      // See if the rack exists in our racks array, if so delete 
      // and insert new rack at its position
        if (device_lookup.chassis[one_chassis_def.id] != null) {
          for (idx = 0; idx < dcrvShowableNonRackChassis.length; idx++) {
            // to maintain the selected rack across the resynch set the 'selected'
            // parameter if present
            //
            one_chassis = dcrvShowableNonRackChassis[idx];
            var one_chassis_def_copy          = {};
            for (var i in one_chassis_def) { one_chassis_def_copy[i]       = one_chassis_def[i]; }
            one_chassis_def_copy.focused  = one_chassis.focused;
            one_chassis_def_copy.bothView = one_chassis.bothView;
  
            // We have found the existing rack we are modifiying, so delete it
            // as its name may have changed, thus meaning it has a new position
            // in the array
            if (one_chassis.id === one_chassis_def.id) {
              dcrvShowableNonRackChassis[idx] = one_chassis_def_copy;
            }
          }
        } else {
          // It must be a new rack as we didn't match it in our rack array
          //
          one_chassis_def.instances = [];
          dcrvShowableNonRackChassis.push(one_chassis_def);
        }
      
        result.push(device_lookup.chassis[one_chassis_def.id] = one_chassis_def);
      }
      return result;
    })();
  }


  // refreshes current view with any changes as notified by the server
  // @param  rack_defs   new rack definitions for any modified or added racks
  // @param  change_set  object with properties 'deleted', 'added' and 'modified'; each an array of rack ids
  synchroniseRacks(rack_defs, change_set) {
    let idx, rack;
    if ((change_set == null) || (rack_defs == null)) { return; }
    this.model.activeSelection(false);
    const device_lookup = this.model.deviceLookup();
    const racks         = this.model.racks();

    for (var deleted_id of Array.from(change_set.deleted)) {
      deleted_id = String(deleted_id);
      var iterable = racks.slice(0).reverse();
      for (idx = 0; idx < iterable.length; idx++) {
        rack = iterable[idx];
        if (rack.id === deleted_id) {
          racks.splice(racks.indexOf(rack), 1);
        }
      }

      delete device_lookup.racks[deleted_id];
    }

    return (() => {
      const result = [];
      for (var rack_def of Array.from(rack_defs)) {
      // See if the rack exists in our racks array, if so delete 
      // and insert new rack at its position
        if (device_lookup.racks[rack_def.id] != null) {
          for (idx = 0; idx < racks.length; idx++) {
            // to maintain the selected rack across the resynch set the 'selected'
            // parameter if present
            //
            rack = racks[idx];
            var rack_def_copy          = {};
            for (var i in rack_def) { rack_def_copy[i]       = rack_def[i]; }
            rack_def_copy.focused  = rack.focused;
            rack_def_copy.bothView = rack.bothView;

            // We have found the existing rack we are modifiying, so delete it
            // as its name may have changed, thus meaning it has a new position
            // in the array
            if (rack.id === rack_def.id) {
              racks[idx] = rack_def_copy;
            }
          }
        } else {
          // It must be a new rack as we didn't match it in our rack array
          //
          if (device_lookup.racks[rack_def.nextRackId] != null) {
            for (idx = 0; idx < racks.length; idx++) {
              rack = racks[idx];
              if (rack.id === rack_def.nextRackId) {
                racks.splice(idx, 0, rack_def);
                break;
              }
            }
          } else {
            racks.push(rack_def);
          }
        }
      
        result.push(device_lookup.racks[rack_def.id] = rack_def);
      }
      return result;
    })();
  }

  resetRackSpace() {
    if (this.racks != null) { for (var rack of Array.from(this.racks)) { rack.destroy(); } }
    this.racks = [];
    if (this.model.showingRacks() && !this.model.showingFullIrv()) {
      this.setUpRacks();
      this.centreRacks();
      this.model.activeSelection(true);
      for (var oneRack of Array.from(this.racks)) {
        for (var oneInstance of Array.from(this.model.deviceLookup().racks[oneRack.id].instances)) {
          oneInstance.included = true;
        }
      }
    } else if (this.model.showingFullIrv()) {
      this.setUpRacks();
      this.refreshRacks();
    }

    return this.draw();
  }


  // triggers re-instanciation of all racks based upon contents of device lookup
  refreshRacks() {
    let id;
    const device_lookup = this.model.deviceLookup();
    const current_racks = this.model.racks();

    // maintain server defined order
    const new_racks     = [];
    for (id in device_lookup.racks) {
      var rack = device_lookup.racks[id];
      var array_idx = Util.arrayIndexOf(current_racks, rack);
      new_racks[array_idx] = rack;
    }

    const new_non_racks = [];
    const selected_chassis_id = Object.keys(device_lookup.chassis).map(oneK => parseInt(oneK));
    for (var chassis of Array.from(this.model.dcrvShowableNonRackChassis())) {
      if (Array.from(selected_chassis_id).includes(chassis.id)) {
        var current_ids = new_non_racks.map(oneC => parseInt(oneC.id));
        if (!(Util.arrayIndexOf(current_ids, chassis.id) >= 0)) { new_non_racks.push(chassis); }
      }
    }

    this.model.dcrvShowableNonRackChassis(new_non_racks.clean());

    this.switchRackSet(new_racks.clean());
    if (this.model.face() === ViewModel.FACE_BOTH) { return this.showSplitView(); }
  }


  // destroys all rack instances of the supplied rack ids
  // @param  rack_ids  array, a list of rack ids to destroy
  destroyRacks(rack_ids) {
    return (() => {
      const result = [];
      for (var rack_id of Array.from(rack_ids)) {
        var rack = this.model.deviceLookup().racks[rack_id];
        for (var instance of Array.from(rack.instances)) {
          instance.destroy();
        }

        result.push(rack.instances = []);
      }
      return result;
    })();
  }


  // destroys existing racks in favour of a new set of racks but only if the new set differs from the current. Recalculates any dependant
  // values, zoom presets etc.
  // @param  new_racks   array, a list of rack definition objects
  switchRackSet(new_racks) {
    const equivalentRackSets = function(racks_a, racks_b) {
      let found, rack_a, rack_b;
      if (racks_a.length !== racks_b.length) {
        return false;
      }

      for (rack_a of Array.from(racks_a)) {
        for (rack_b of Array.from(racks_b)) {
          found = false;
          if (rack_a.id === rack_b.id) {
            found = true;
            break;
          }
        }

        if (!found) { return false; }
      }

      for (rack_b of Array.from(racks_b)) {
        for (rack_a of Array.from(racks_a)) {
          found = false;
          if (rack_a.id === rack_b.id) {
            found = true;
            break;
          }
        }

        if (!found) { return false; }
      }

      return true;
    };

    const old_racks = this.model.racks();
  
    // only redraw if we have to
    // Commenting this validation, so it now redraw everytime the user click on clear deselected.
    // The validation was failing, due to the fact that it was only checking if the selected rack set has changed, but not the selected nrad set.
    // Once in titania we have racks and nrads together (single API call, and single definition array), we could add this validation again.
    //return if equivalentRackSets(new_racks, old_racks)

    // kill off old rack set
    for (var rack of Array.from(this.racks)) { rack.destroy(); }

    const showing_all = this.scale === RackSpace.MIN_ZOOM;

    // update model and show new rack set
    this.model.racks(new_racks);
    if (this.model.showingRacks()) { this.setUpRacks(); }
    this.setZoomPresets();

    if (showing_all) {
      this.scale = this.zoomPresets[0];
      this.setScaleInLayers();
      this.model.scale(this.scale);
    } else if (this.scale > RackSpace.MAX_ZOOM) {
      this.scale = RackSpace.MAX_ZOOM;
      this.setScaleInLayers();
      this.model.scale(this.scale);
    } else if (this.scale < RackSpace.MIN_ZOOM) {
      this.scale = RackSpace.MIN_ZOOM;
      this.setScaleInLayers();
      this.model.scale(this.scale);
    }

    this.draw();

    this.synchroniseZoomIdx();
    if (this.model.showingRacks()) { return this.centreRacks(); }
  }
  

  // generates a new rack set duplicating each rack definition in order to produce two rack instances per rack id
  showSplitView() {
    // create rack defs with rear facing duplicates
    let i, rack, rear;
    let racks     = this.model.racks();
    const new_racks = [];
    for (rack of Array.from(racks)) {
      rear          = {};
      for (i in rack) { rear[i]       = rack[i]; }
      rack.bothView = ViewModel.FACE_FRONT;
      rear.bothView = ViewModel.FACE_REAR;
      new_racks.push(rack);
      new_racks.push(rear);
    }

    racks     = this.model.dcrvShowableNonRackChassis();
    const new_non_racks = [];
    for (rack of Array.from(racks)) {
      rear          = {};
      for (i in rack) { rear[i]       = rack[i]; }
      rack.bothView = ViewModel.FACE_FRONT;
      rear.bothView = ViewModel.FACE_REAR;
      new_non_racks.push(rack);
      new_non_racks.push(rear);
    }

    this.model.dcrvShowableNonRackChassis(new_non_racks);

    return this.switchRackSet(new_racks);
  }


  // deletes duplicated rack definitions and switches rack set 
  revertFromSplitView() {
    let racks     = this.model.racks();
    const new_racks = [];
    let count     = 0;
    let len       = racks.length;
    while (count < len) {
      new_racks.push(racks[count]);
      count += 2;
    }

    racks     = this.model.dcrvShowableNonRackChassis();
    const new_non_racks = [];
    count     = 0;
    len       = racks.length;
    while (count < len) {
      new_non_racks.push(racks[count]);
      count += 2;
    }

    this.model.dcrvShowableNonRackChassis(new_non_racks);
    return this.switchRackSet(new_racks);
  }


  // sets up and commences first stage of front/rear flip animation: fade out the info layer (metric bars and text)
  // rather than animating the existing canvas layers this clones them to two new 'fx' layers which are manipulated for the animation
  // the reason for this is if the user is zoomed in, only the visible slice of the data centre needs to be animated rather than redrawing
  // a much larger area
  flip() {
    this.flipping = true;
    this.flipCount = 0;

    this.rackGfx.pauseAnims();
    this.rackInfoGfx.pauseAnims();
    this.infoGfx.pauseAnims();
    this.alertGfx.pauseAnims();

    // store current scroll
    this.scrollOffset = {
      x: this.rackEl.scrollLeft,
      y: this.rackEl.scrollTop
    };

    // store canvas offset (for centring)
    this.cvsOffset = {
      x: Util.getStyleNumeric(this.rackGfx.cvs, 'left'),
      y: Util.getStyleNumeric(this.rackGfx.cvs, 'top')
    };

    // hide existing canvas layers
    this.rackEl.removeChild(this.rackGfx.cvs);
    this.rackEl.removeChild(this.rackInfoGfx.cvs);
    this.rackEl.removeChild(this.infoGfx.cvs);
    this.rackEl.removeChild(this.alertGfx.cvs);

    const dims         = this.rackEl.getCoordinates();//Util.getElementDimensions(@rackEl)
    dims.width  -= this.scrollAdjust;
    dims.height -= this.scrollAdjust;

    // create a copy of the rack canvas image
    this.fx = this.createGfxLayer(this.rackEl, 0, 0, dims.width, dims.height);
    this.fx.addImg({ img: this.rackGfx.cvs, x: this.cvsOffset.x - this.scrollOffset.x, y: this.cvsOffset.y - this.scrollOffset.y });

    // create a copy of the info canvas image
    this.fx2     = this.createGfxLayer(this.rackEl, 0, 0, dims.width, dims.height);
    const info_img = this.fx2.addImg({ img: this.infoGfx.cvs, x: this.cvsOffset.x - this.scrollOffset.x, y: this.cvsOffset.y - this.scrollOffset.y });
    // fade out info layer
    return this.fx2.animate(info_img, { alpha: 0 }, RackSpace.INFO_FADE_DURATION, Easing.Quad.easeOut, this.evFlipReady);
  }


  // invoked when the first stage of the flip sequence completes. Here each rack is sliced out of the composite image and animated
  // individually. The width of each rack is animated to zero, animations are staggered as when each animation completes the rack has to
  // redraw showing it's new face (i.e. front -> rear or rear -> front). This is a costly process so staggering these redraws spreads the
  // processing load helping to prevent any stuttering during animation
  evFlipReady() {
    this.fx.removeAll();

    this.rackLookup = {};
    const mid         = (this.racks.length / 2) - .5;
    for (let idx = 0; idx < this.racks.length; idx++) {
      // add a slice of each rack from the existing (hidden) rack canvas
      var rack = this.racks[idx];
      var img = this.fx.addImg({
        img         : this.rackGfx.cvs,
        x           : (this.cvsOffset.x + (rack.x * this.scale)) - this.scrollOffset.x,
        y           : (this.cvsOffset.y + (rack.y * this.scale)) - this.scrollOffset.y,
        sliceX      : rack.x * this.scale,
        sliceY      : rack.y * this.scale,
        sliceWidth  : rack.width * this.scale,
        sliceHeight : rack.height * this.scale});

      // rackLookup associates the rack instance with it's image, used when flipped half way
      this.rackLookup[img] = rack;

      // set up the animation adding a suitable delay to stagger rack face redraws. Flip animations are staggered so that they start from
      // the middle and spread outwards
      this.fx.animate(img, {
        delay : RackSpace.FLIP_DELAY * Math.abs(idx - mid),
        x     : (this.cvsOffset.x + ((rack.x + (rack.width / 2)) * this.scale)) - this.scrollOffset.x,
        width : 0
      }
      , RackSpace.FLIP_DURATION, Easing.Quad.easeIn, this.evHalfFlipped);
    }

    // force immediate draw or we'll have a blank image for one frame
    return this.fx.redraw();
  }


  // triggered when an individual rack has reached the half way point in the flip animation, it's current width is zero so we can now
  // redraw the rack with the new face (i.e. front -> rear or rear -> front)
  // @param  img_id   the SimpleRenderer asset id of the rack image being animated
  evHalfFlipped(img_id) {
    const show_u_labels   = this.scale >= RackSpace.U_LBL_SCALE_CUTOFF;
    const show_name_label = this.scale >= RackSpace.NAME_LBL_SCALE_CUTOFF;
    const show_owner_label = show_name_label && this.model.RBAC.can_i("view", "all");

    // redraw the rack in the (hidden) rack layer, since the rack image in the fx layer is a slice of the rack layer it will automatically
    // reflect the changes
    this.rackLookup[img_id].draw(show_u_labels, show_name_label, show_owner_label);

    const x     = this.fx.getAttribute(img_id, 'x');
    const width = this.fx.getAttribute(img_id, 'sliceWidth');

    // commence second half of flip animation
    return this.fx.animate(img_id, { x: x - (width / 2), width }, RackSpace.FLIP_DURATION, Easing.Quad.easeOut, this.evFlipped);
  }


  // called when an individual rack image has completed flipping. Since rack flip animations are staggered this tests wether all racks
  // have now completed and commences the final stage of the flip animation
  // @param  img_id   the SimpleRenderer asset id of the rack image being animated
  evFlipped(img_id) {
    ++this.flipCount;
    if (this.flipCount === this.racks.length) {
      this.fx2.removeAll();
      const info_img = this.fx2.addImg({ img: this.infoGfx.cvs, alpha: 0, x: this.cvsOffset.x - this.scrollOffset.x, y: this.cvsOffset.y - this.scrollOffset.y });
    
      // commence info (metric bars and text) layer fade in animation
      return this.fx2.animate(info_img, { alpha: 1 }, RackSpace.INFO_FADE_DURATION, Easing.Quad.easeOut, this.evFlipComplete);
    }
  }
    

  // triggered when all phases of the flip animation have completed. Destroys the fx layers, switching them for the real canvas layers
  // and resets scroll offsets
  evFlipComplete() {
    this.flipping = false;

    this.fx.destroy();
    this.fx2.destroy();

    this.rackEl.appendChild(this.rackGfx.cvs);
    this.rackEl.appendChild(this.rackInfoGfx.cvs);
    this.rackEl.appendChild(this.infoGfx.cvs);
    this.rackEl.appendChild(this.alertGfx.cvs);

    this.rackEl.scrollLeft = this.scrollOffset.x;
    this.rackEl.scrollTop = this.scrollOffset.y;

    this.rackGfx.resumeAnims();
    this.rackInfoGfx.resumeAnims();
    this.infoGfx.resumeAnims();
    this.alertGfx.resumeAnims();

    Events.dispatchEvent(this.rackEl, 'rackSpaceFlipComplete');
    return this.updateRackImage();
  }


  // public method, handles single clicks
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer
  click(x, y, multi_select) {
  
    if (this.contextMenu.visible) {
      this.contextMenu.hide();
      return this.highlightAt(x, y);
    } else {
      x /= this.scale;
      y /= this.scale;

      const clicked = this.getDeviceAt(x, y);

      // If opening a url of a rack (the manufacturer url) open in another tab.
      // We are ok about the user having to authorise the popups.
      if ((clicked instanceof Link) || (clicked instanceof ImageLink)) {
        if ((clicked instanceof ImageLink) && (clicked.parent() instanceof Rack)) {
          window.open(clicked.url, '_blank');
        } else {
          window.location = clicked.url;
        }
      }

      if (clicked != null) {
        return this.viewSelectItem(clicked, multi_select);
      }
    }
  }

  // public method, handles mouse middle/centre click
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer
  middleClick(x, y) {
    x /= this.scale;
    y /= this.scale;

    const clicked = this.getDeviceAt(x, y);

    if ((clicked instanceof Link) || (clicked instanceof ImageLink)) {
      return window.open(clicked.url, '_blank');
    }
  }

  viewSelectItem(item, multi_select) {
    let childKey, childValue, group, groups, id, key, value;
    const selected_devices = this.model.selectedDevices();

    if (multi_select) {
      let active_selection;
      const new_val = (selected_devices[item.group][item.id] = !selected_devices[item.group][item.id]);

      if (new_val) {
        active_selection = true;
      } else {
        active_selection = false;
        groups = this.model.groups();
        for (group of Array.from(groups)) {
          for (id in selected_devices[group]) {
            if (selected_devices[group][id]) {
              active_selection = true;
              break;
            }
          }

          if (active_selection) { break; }
        }
      }

      if (item instanceof Rack) {
        const object = item.selectChildren();
        for (key in object) {
          value = object[key];
          for (childKey in value) {
            childValue = value[childKey];
            selected_devices[key][childKey] = new_val;
          }
        }
      }

      this.model.selectedGroup(null);

      this.model.activeSelection(active_selection);
      return this.model.selectedDevices(selected_devices);

    } else {
      groups  = this.model.groups();
      const new_sel = {};
      for (group of Array.from(groups)) { new_sel[group] = {}; }
      new_sel[item.group][item.id] = true;

      if (item instanceof Rack) {
        const object1 = item.selectChildren();
        for (key in object1) {
          value = object1[key];
          for (childKey in value) {
            childValue = value[childKey];
            new_sel[key][childKey] = true;
          }
        }
      }


      this.model.selectedGroup(null);

      this.model.activeSelection(true);
      return this.model.selectedDevices(new_sel);
    }
  }

  // public method, commences drag operation on LBC
  // @param  x   mouse x coordinate relative to the LBC
  // @param  y   mouse y coordinate relative to the LBC
  startDragChart(x, y) {
    return this.chart.startDrag(x, y);
  }


  // public method, updates drag operation on LBC
  // @param  x   mouse x coordinate relative to the LBC
  // @param  y   mouse y coordinate relative to the LBC
  dragChart(x, y) {
    return this.chart.drag(x, y);
  }


  // public method, stops drag operation on LBC
  // @param  x   mouse x coordinate relative to the LBC
  // @param  y   mouse y coordinate relative to the LBC
  stopDragChart(x, y) {
    return this.chart.stopDrag(x, y);
  }


  // public method, commences the dragging of a selection box or device
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer
  startDrag(x, y) {
    x /= this.scale;
    y /= this.scale;
    this.selection = this.getDeviceAt(x, y);

    // if over a device commence dragging of device
    if ((this.selection != null) && this.canIMoveThisItem()) {
      let chassis_id, selection_height, the_image;
      Util.setStyle(this.rackEl, 'cursor', 'move');
      // drag a device/chassis
      const x_off_set = Util.getStyleNumeric(this.coordReferenceEl,'left') / this.scale;
      const y_off_set = Util.getStyleNumeric(this.coordReferenceEl,'top') / this.scale;
      let drag_layer_width = this.rackGfx.width;
      if (this.model.showHoldingArea()) { drag_layer_width += this.holdingAreaGfx.width; }
      this.fx = this.createGfxLayer(this.rackEl, 0, 0, x_off_set + drag_layer_width, this.rackGfx.height, this.scale);

      // the cassis is the one storing the image for the device
      if (this.selection instanceof Machine) {
        chassis_id = parseInt(this.selection.parent().id);
        if (this.selection.parent().complex === true) {
          this.moving_a_blade = true;
          the_image = this.selection.img;
          selection_height = 1;
        } else {
          the_image = this.selection.parent().img;
          selection_height = this.selection.parent().uHeight;
        }
      } else { //if @selection instanceof Chassis
        chassis_id = parseInt(this.selection.id);
        the_image = this.selection.img;
        selection_height = this.selection.uHeight;
      }

      this.dragImgOffset = { x: x_off_set, y: y_off_set };
      this.dragImg       = this.fx.addImg({ img: the_image, x: x + this.dragImgOffset.x, y: y + this.dragImgOffset.y, alpha: RackSpace.DRAG_ITEM_ALPHA });

      if (this.selection instanceof Chassis || this.selection instanceof Machine) {
        const targetRacks = DragPolicy.filter(this.selection, this.racks);
        targetRacks.forEach((rack) => {
          if (this.moving_a_blade) {
            rack.showFreeSpacesForBlade(this.selection.template.images.front,chassis_id);
          } else if (rack instanceof Rack) {
            rack.showFreeSpacesForChassis(selection_height,chassis_id,this.selection.depth());
          }
        });
      }

      return this.selection.showDrag();

    } else {
      this.selection = null;
      // drag a selection box
      this.fx        = this.createGfxLayer(this.rackEl, Util.getStyleNumeric(this.rackGfx.cvs, 'left'), Util.getStyleNumeric(this.rackGfx.cvs, 'top'), this.rackGfx.width, this.rackGfx.height, this.scale);
      this.boxAnchor = { x, y };
      return this.box       = this.fx.addRect({ x, y, stroke: RackSpace.SELECT_BOX_STROKE, strokeWidth: RackSpace.SELECT_BOX_STROKE_WIDTH / this.scale, alpha: RackSpace.SELECT_BOX_ALPHA, width: 1, height: 1 });
    }
  }

  canIMoveThisItem() {
    return this.draggableItem() && this.doIHavePermissionToMoveOrDrag() && (this.selection.face === 'front');
  }

  draggableItem() {
    if (this.selection instanceof Chassis || this.selection instanceof Machine) {
      if (this.selection instanceof Chassis && (this.selection.template.rackable === 1)) {
        return true;
      } else if (this.selection instanceof Machine && (this.selection.parent().template.rackable === 1)) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  doIHavePermissionToMoveOrDrag() {
    return ((this.selection instanceof Chassis || this.selection instanceof Machine) && this.model.RBAC.can_i_move_devices());
  }

  // public method, updates dragging of a selection box or device
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer
  drag(x, y) {
    x /= this.scale;
    y /= this.scale;

    if (this.selection != null) {
      const slots = [];
      for (var rack of Array.from(this.racks)) {
        slots.push(rack.getNearestSpace(x, y));
      }
      Util.sortByProperty(slots, 'dist', true);
      const nearest = slots[0];

      if (this.rectangleNearest != null) { this.fx.remove(this.rectangleNearest); }
      if ((nearest != null) && (((nearest.dist * this.scale) <= Math.pow(RackSpace.DRAG_SNAP_RANGE / this.scale, 2)) || ((x > nearest.left) && (x < nearest.right) && (y > nearest.top) && (y < nearest.bottom)))) {
        this.fx.setAttributes(this.dragImg, { alpha: 1 });
        this.fx.setAttributes(this.dragImg, { x: (this.dragImgOffset.x + nearest.left + ((nearest.right - nearest.left) / 2)) - (this.fx.getAttribute(this.dragImg, 'width') / 2), y: nearest.top });
        this.rectangleNearest = this.fx.addRect({ x: this.fx.getAttribute(this.dragImg, 'x'), y: this.fx.getAttribute(this.dragImg, 'y'), width: this.fx.getAttribute(this.dragImg, 'width'), height: this.fx.getAttribute(this.dragImg, 'height'), stroke: '#ff00ff', strokeWidth:RackSpace.MOVING_DEVICE_STROKE_WIDTH});
        return this.nearest = nearest;
      } else {
        this.fx.setAttributes(this.dragImg, { alpha: RackSpace.DRAG_ITEM_ALPHA });
        return this.fx.setAttributes(this.dragImg, { x: x + this.dragImgOffset.x, y: y + this.dragImgOffset.y });
      }
    } else if (this.box) {
      return this.dragBox(x, y);
    }
  }


  // draws a selection box defined by supplied x/y coordinates and @boxAnchor
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer and scale adjusted
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer and scale adjusted
  dragBox(x, y) {
    const attrs = {};

    if (x > this.boxAnchor.x) {
      attrs.x     = this.boxAnchor.x;
      attrs.width = x - this.boxAnchor.x;
    } else {
      attrs.x     = x;
      attrs.width = this.boxAnchor.x - x;
    }

    if (y > this.boxAnchor.y) {
      attrs.y      = this.boxAnchor.y;
      attrs.height = y - this.boxAnchor.y;
    } else {
      attrs.y      = y;
      attrs.height = this.boxAnchor.y - y;
    }

    return this.fx.setAttributes(this.box, attrs);
  }


  // removes selection box canvas layer and actions drag operation by either updating the model selected devices when dragging a box or
  // moving a device when dragging a device
  // @param  x   the x coordinate of the mouse relative to the rack canvas layer
  // @param  y   the y coordinate of the mouse relative to the rack canvas layer
  stopDrag(x, y) {
    // if dragging a device
    if (this.selection != null) {
      Util.setStyle(this.rackEl, 'cursor', 'auto');
      this.rackGfx.redraw();
      for (var rack of Array.from(this.racks)) {
        rack.hideSpaces();
      }
      this.fx.destroy();
      this.selection.hideDrag();
      this.deviceToConect = null;
      // TODO move the device to the target rack, update model, create worksheet job etc. etc.

      x /= this.scale;
      y /= this.scale;

      if ((this.model.showingFullIrv() || this.model.showingRacks()) && this.model.showHoldingArea() && this.holdingArea.overInternalArea(x,y)) {
        if (this.selection instanceof Chassis || (this.selection instanceof Machine && (this.selection.parent().complex === false))) {
          this.moveDeviceToHoldingArea();
        }
      } else if (this.nearest != null) {
        const x_coord = this.nearest.left+((this.nearest.right-this.nearest.left)/2);
        const y_coord = (this.nearest.bottom-(RackObject.U_PX_HEIGHT/2));
        if (this.moving_a_blade) {
          this.deviceToConect = this.getDeviceAt(x_coord,y_coord);
        } else {
          this.deviceToConect = this.getRackAt(x_coord,y_coord);
        }
      }

      if (this.deviceToConect != null) {
        if (this.nearest != null) {
          if (this.moving_a_blade && this.deviceToConect instanceof Chassis) {
            this.moveBladeBeingDragged();
          } else if (this.deviceToConect instanceof Rack) {
            if (this.selection.placedInHoldingArea()) {
              this.moveDeviceFromHoldingArea();
            } else {
              if (this.validLocationToMove(x,y)) {
                this.moveDeviceBeingDragged();
              } else {
                this.messageHint.show([["Cannot move device "+this.selection.name+" to position.", 0]]);
              }
            }
          }
        }
      }

      this.nearest = null;
      return this.moving_a_blade = null;

    // otherwise when dragging a selection box...
    } else if (this.box != null) {
      this.selectDevicesInsideDraggingBox(x,y);
      return this.box = null;
    }
  }

  validLocationToMove(x,y) {
    const device_at_dropping = this.getDeviceAt(x,y);
    if ((device_at_dropping != null) && (device_at_dropping instanceof Rack || this.movingMyself(this.selection,device_at_dropping) || (device_at_dropping.facing !== this.nearest.face))) {
      return true;
    } else {
      return false;
    }
  }

  // Function to validate if the device being dragged is dropped in an area that belongs to itself or in a blade that is inside itself.
  movingMyself(device_dragged, device_at_dropping) {
    return (device_dragged.id === device_at_dropping.id) || (device_dragged.id === __guard__(device_at_dropping.parent(), x => x.id));
  }

  selectDevicesInsideDraggingBox(x,y) {
    this.fx.destroy();

    x /= this.scale;
    y /= this.scale;

    const box = {};
    if (x > this.boxAnchor.x) {
      box.x     = this.boxAnchor.x;
      box.width = x - this.boxAnchor.x;
    } else {
      box.x     = x;
      box.width = this.boxAnchor.x - x;
    }

    if (y > this.boxAnchor.y) {
      box.y      = this.boxAnchor.y;
      box.height = y - this.boxAnchor.y;
    } else {
      box.y      = y;
      box.height = this.boxAnchor.y - y;
    }

    box.left   = box.x;
    box.right  = box.x + box.width;
    box.top    = box.y;
    box.bottom = box.y + box.height;

    this.model.selectedGroup(null);
    const selection = this.selectWithin(box, true);
    this.model.activeSelection(selection != null);
    this.model.selectedDevices(selection);
    return this.clearAllRacksAsFocused();
  }

  moveDeviceFromHoldingArea() {
    if (this.selection instanceof Machine || this.selection instanceof Chassis) {
      const chassisToBeUpdated = this.selection instanceof Chassis ? this.selection : this.selection.parent();
      chassisToBeUpdated.hide();
      const oneChassisObject = this.holdingArea.remove(chassisToBeUpdated.id);
      this.addChildToRack(parseInt(this.nearest.rack_id),chassisToBeUpdated);
      const next_rack = this.model.deviceLookup()['racks'][this.nearest.rack_id];
      chassisToBeUpdated.parent(next_rack.instances[0]);
      next_rack.chassis.push(oneChassisObject);
      this.model.deviceLookup()['racks'][parseInt(next_rack.id)] = next_rack;

      this.updateChassisPositionInARack(this.nearest.rack_id, chassisToBeUpdated.id, this.nearest.u, this.nearest.face, chassisToBeUpdated.face);
      return chassisToBeUpdated.moveToOrFromHoldingArea("RackChassis",this.nearest.rack_id,(this.nearest.u+1),this.nearest.face);
    }
  }

  moveDeviceToHoldingArea() {
    if (this.selection instanceof Machine || this.selection instanceof Chassis) {
      const chassisToBeUpdated = this.selection instanceof Chassis ? this.selection : this.selection.parent();
      if (!(chassisToBeUpdated.parent() instanceof HoldingArea)) {
        chassisToBeUpdated.hide();
        chassisToBeUpdated.parent(this.holdingArea);
        this.holdingArea.add(chassisToBeUpdated);
        return chassisToBeUpdated.moveToOrFromHoldingArea("NonRackChassis",null,0,'f');
      }
    }
  }

  moveDeviceBeingDragged() {
    if (this.selection instanceof Machine || this.selection instanceof Chassis) {
      const chassisToBeUpdated = this.selection instanceof Chassis ? this.selection : this.selection.parent();
      const previous_rack = null;
      const moving_to_different_rack = parseInt(chassisToBeUpdated.parent().id) !== this.nearest.rack_id;
      this.addChildToRack(parseInt(this.nearest.rack_id),chassisToBeUpdated);
      chassisToBeUpdated.parent(this.model.deviceLookup()['racks'][this.nearest.rack_id].instances[0]);
      this.updateChassisPositionInARack(this.nearest.rack_id, chassisToBeUpdated.id, this.nearest.u, this.nearest.face, chassisToBeUpdated.face);
      return chassisToBeUpdated.updatePosition();
    }
  }

  moveBladeBeingDragged() {
    if (this.selection instanceof Machine) {
      this.selection.hideMetric();
      const bladeToBeUpdated = this.selection;
      let previous_chassis = null;
      const moving_to_different_chassis = parseInt(bladeToBeUpdated.parent().id) !== this.nearest.chassis_id;
      if (moving_to_different_chassis) {
        previous_chassis = this.model.deviceLookup()['chassis'][bladeToBeUpdated.parent().id];
        const previous_chassis_rack_id = parseInt(previous_chassis.instances[0].parent().id);
        for (let index = 0; index < previous_chassis.Slots.length; index++) {
          var oneSlot = previous_chassis.Slots[index];
          if ((oneSlot.Machine != null) && (parseInt(oneSlot.Machine.id) === parseInt(bladeToBeUpdated.id))) {
            this.removeBladeFromChassisFromRack(previous_chassis_rack_id, parseInt(previous_chassis.id), parseInt(bladeToBeUpdated.id));
            this.addBladeToChassisInRack(this.nearest.rack_id, this.nearest.chassis_id, bladeToBeUpdated);
            var next_chassis = this.model.deviceLookup()['chassis'][this.nearest.chassis_id];
            bladeToBeUpdated.parent(next_chassis.instances[0]);
            previous_chassis.Slots[index].Machine = null;
            for (var slotIndex = 0; slotIndex < next_chassis.Slots.length; slotIndex++) {
              var oneNewSlot = next_chassis.Slots[slotIndex];
              if ((parseInt(oneNewSlot.row) === this.nearest.row) && (parseInt(oneNewSlot.col) === this.nearest.col)) {
                next_chassis.Slots[slotIndex].Machine = oneSlot.Machine;
              }
            }
            this.model.deviceLookup()['chassis'][parseInt(previous_chassis.id)] = previous_chassis;
            this.model.deviceLookup()['chassis'][parseInt(next_chassis.id)] = next_chassis;
            break;
          }
        }
      }

      bladeToBeUpdated.slot_id = this.nearest.slot_id;
      return bladeToBeUpdated.updateSlot();
    }
  }

  updateChassisPositionInARack(rack_id, chassis_id, new_u, new_face, dragged_image_face) {
    return (() => {
      const result = [];
      for (var oneRack of Array.from(this.racks)) {
        if (parseInt(oneRack.id) === rack_id) {
          result.push(oneRack.updateChassisPosition(parseInt(chassis_id), new_u, new_face));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  // public method, zooms the view to 'view all'
  resetZoom() {
    if (this.scale === this.zoomPresets[0]) {
      Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
      return;
    }

    this.zoomIdx = 0;
    const centre_x = this.coordReferenceEl.width / 2;
    const centre_y = this.coordReferenceEl.height / 2;
    return this.quickZoom(centre_x, centre_y, this.zoomPresets[this.zoomIdx]);
  }

  addChildToRack(rack_id, child) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.racks.length; index++) {
        var oneRack = this.racks[index];
        if (parseInt(oneRack.id) === rack_id) {
          result.push(this.racks[index].children.push(child));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  removeBladeFromChassisFromRack(rack_id, chassis_id, blade_id) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.racks.length; index++) {
        var oneRack = this.racks[index];
        if (parseInt(oneRack.id) === rack_id) {
          this.racks[index].removeBladeFromChassis(chassis_id, blade_id);
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  addBladeToChassisInRack(rack_id, chassis_id, blade) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.racks.length; index++) {
        var oneRack = this.racks[index];
        if (parseInt(oneRack.id) === rack_id) {
          this.racks[index].addBladeToChassis(chassis_id, blade);
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  // zoom to next zoom preset value; travelling either forward or backwards through the array of zoom presets
  // @param  direction   int, optional defaulting to 1, indicates wether to zoom in or out, should be 1 or -1
  // @param  centre_x    float, optional defaulting to rack view centre, the target x coordinate about which to centre the view when zooming
  // @param  centre_y    float, optional defaulting to rack view centre, the target y coordinate about which to centre the view when zooming
  // @param  cyclical    boolean, optional defaulting to true, indicates wether to cycle through the zoom preset array
  zoomToPreset(direction, centre_x, centre_y, cyclical) {
    if (direction == null) { direction = 1; }
    if (cyclical == null) { cyclical = true; }
    if (this.zooming) { return; }

    // don't action zoom if we've hit one end of the presets array and not cyclical
    if (!cyclical && (((this.zoomIdx + direction) < 0) || ((this.zoomIdx + direction) >= this.zoomPresets.length))) {
      Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
      return;
    }

    if (centre_x == null) { centre_x  = this.coordReferenceEl.width / 2; }
    if (centre_y == null) { centre_y  = this.coordReferenceEl.height / 2; }
    this.zoomIdx += direction;
    // cycle through presets
    if (this.zoomIdx >= this.zoomPresets.length) { this.zoomIdx = 0; }
    if (this.zoomIdx < 0) { this.zoomIdx = this.zoomPresets.length - 1; }
    return this.quickZoom(centre_x, centre_y, this.zoomPresets[this.zoomIdx]);
  }


  // zoom idx denotes where in the list of zoom presets the current view is. Certain operations such as step-zooming or resizing the
  // browser can cause this to fall out of sync. This routine forces it back in sync.
  synchroniseZoomIdx() {
    if (this.zoomPresets == null) { return; }

    let idx = 1;
    const len = this.zoomPresets.length;
    while ((idx < len) && (this.scale >= this.zoomPresets[idx])) { ++idx; }
    return this.zoomIdx = idx - 1;
  }


  // down render everything to a single image and scale that rather than each individual asset
  // Calculates target view (post zoom) properties and commenes first phase of zoom animation: fade out info layer (metric bars and text)
  // Rather than animating the existing canvas layers this clones them to two new 'fx' layers which are manipulated for the animation
  // the reason for this is its much more performant to work with one flattened image rather than potentially thousands of individual
  // assets also, if the user is zoomed in only the visible slice of the data centre needs to be animated rather than redrawing a much
  // larger area
  quickZoom(centre_x, centre_y, new_scale) {
    if (this.zooming) { return; }

    const dims         = this.rackEl.getCoordinates();
    dims.width  -= this.scrollAdjust;
    dims.height -= this.scrollAdjust;

    // restrict requested scale to max and min values
    if (new_scale > RackSpace.MAX_ZOOM) {
      this.zoomIdx  = 0;
      new_scale = RackSpace.MAX_ZOOM;
    }
    if (new_scale < RackSpace.MIN_ZOOM) {
      this.zoomIdx  = this.zoomPresets.length - 1;
      new_scale = RackSpace.MIN_ZOOM;
    }

    // calculate centre coords according to target scale
    centre_x = centre_x / (this.scale / new_scale);
    centre_y = centre_y / (this.scale / new_scale);

    // store current scroll
    this.scrollOffset = {
      x: this.rackParent.scrollLeft,
      y: this.rackParent.scrollTop
    };

    // calculate target coords according to top-left
    let target_x = centre_x - (dims.width / 2);
    let target_y = centre_y - (dims.height / 2);

    const target_width  = this.rackGfx.width * new_scale;
    const target_height = this.rackGfx.height * new_scale;

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

    let current_offset_x = Util.getStyleNumeric(this.rackGfx.cvs, 'left');
    let current_offset_y = Util.getStyleNumeric(this.rackGfx.cvs, 'top');
    const lazy_factor      = 2;
  
    // only zoom if new scale is different to current and target scroll
    // is a significant change (greater than lazy factor)
    if ((new_scale === this.scale) && ((Math.abs(this.targetOffset.x - this.scrollOffset.x - current_offset_x) < lazy_factor) && (Math.abs(this.targetOffset.y - this.scrollOffset.y - current_offset_y) < lazy_factor))) {
      Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
      return;
    }

    // commence zoom
    this.hint.hide();
    this.contextMenu.hide();
    this.removeHighlights();
    this.zooming     = true;
    this.targetScale = new_scale;
    this.model.targetScale(this.targetScale);

    current_offset_x = Util.getStyleNumeric(this.rackGfx.cvs, 'left');
    current_offset_y = Util.getStyleNumeric(this.rackGfx.cvs, 'top');

    // clone rack canvas
    if (this.model.showingRacks()) {
      this.fx      = this.createGfxLayer(this.rackEl, 0, 0, dims.width, dims.height);
      this.rackImg = this.fx.addImg({ img: this.rackGfx.cvs, x: current_offset_x - this.scrollOffset.x, y: current_offset_y - this.scrollOffset.y });
    }

    //# clone holding area canvas
    //if @model.showHoldingArea()
    //  @fxHoldingArea = @createGfxLayer(@rackEl, 0, 0, @holdingArea.x + @holdingArea.width, @holdingArea.y + @holdingArea.height)
    //  @holdingAreaImg = @fxHoldingArea.addImg({ img: @holdingAreaGfx.cvs, x: current_offset_x - @scrollOffset.x + (@holdingArea.x*@scale), y: current_offset_y - @scrollOffset.y + (@holdingArea.y*@scale) })
    //# clone holding area canvas
    //  @fxHoldingAreaBackGround = @createGfxLayer(@rackEl, 0, 0, dims.width, dims.height)
    //  @holdingAreaImgBackGround = @fxHoldingAreaBackGround.addImg({ img: @holdingAreaBackGroundGfx.cvs, x: current_offset_x - @scrollOffset.x, y: current_offset_y - @scrollOffset.y })

    // clone info canvas
    this.fx2     = this.createGfxLayer(this.rackEl, 0, 0, dims.width, dims.height);
    const info_img = this.fx2.addImg({ img: this.infoGfx.cvs, x: current_offset_x - this.scrollOffset.x, y: current_offset_y - this.scrollOffset.y });

    // commence info fade animation
    this.fx2.animate(info_img, { alpha: 0 }, RackSpace.INFO_FADE_DURATION, Easing.Quad.easeOut, this.evZoomReady);

    if (this.model.showingRacks()) { this.rackGfx.pauseAnims(); }
    if (this.model.showHoldingArea()) { this.holdingAreaGfx.pauseAnims(); }
    if (this.model.showHoldingArea()) { this.holdingAreaBackGroundGfx.pauseAnims(); }
    this.rackInfoGfx.pauseAnims();
    this.infoGfx.pauseAnims();
    this.alertGfx.pauseAnims();

    // hide existing canvas layers
    this.rackEl.removeChild(this.rackGfx.cvs);
    this.rackEl.removeChild(this.holdingAreaGfx.cvs);
    this.rackEl.removeChild(this.holdingAreaInfoGfx.cvs);
    this.rackEl.removeChild(this.holdingAreaAlertGfx.cvs);
    this.rackEl.removeChild(this.holdingAreaBackGroundGfx.cvs);
    this.rackEl.removeChild(this.rackInfoGfx.cvs);
    this.rackEl.removeChild(this.infoGfx.cvs);
    this.rackEl.removeChild(this.alertGfx.cvs);

    // force immediate draw or we'll have a blank image for one frame
    if (this.model.showingRacks()) { this.fx.redraw(); }
    //@fxHoldingArea.redraw() if @model.showHoldingArea()
    return this.fx2.redraw();
  }


  // called when info fade animation completes, sets the scale of hidden canvas layeres to the target zoom level and  commences
  // actual zoom animation
  evZoomReady() {
    this.fx2.removeAll();

    const relative_scale = this.targetScale / this.rackGfx.scale;

    this.rackInfoGfx.setScale(this.targetScale);
    this.infoGfx.setScale(this.targetScale);
    this.alertGfx.setScale(this.targetScale);

    // decide wether to show rack labels
    const show_name_label = this.targetScale >= RackSpace.NAME_LBL_SCALE_CUTOFF;
    const show_u_labels   = this.targetScale >= RackSpace.U_LBL_SCALE_CUTOFF;
    const show_owner_label = show_name_label && this.model.RBAC.can_i("view", "all");

    if (this.model.showingRacks()) {
      for (var rack of Array.from(this.racks)) {
        if (rack instanceof Rack) { rack.showOwnerLabel(show_owner_label); }
        rack.showNameLabel(show_name_label);
        if (rack instanceof Rack) { rack.showULabels(show_u_labels, this.targetScale); }

        for (var child of rack.children) {
          if (child instanceof Chassis) {
            child.nameLabel.redraw();
          }
        }
      }
    }

    if (this.model.showingRacks()) { this.fx.animate(this.rackImg, {
      x      : -this.targetOffset.x,
      y      : -this.targetOffset.y,
      width  : this.rackGfx.cvs.width * relative_scale,
      height : this.rackGfx.cvs.height * relative_scale
    }
    , RackSpace.ZOOM_DURATION, Easing.Quad.easeInOut, this.evRackZoomComplete); }

    //@fxHoldingArea.animate(@holdingAreaImg,
    //  x      : -@targetOffset.x + (@holdingArea.x*@targetScale)
    //  y      : -@targetOffset.y + (@holdingArea.y*@targetScale)
    //  width  : @holdingAreaGfx.cvs.width * relative_scale
    //  height : @holdingAreaGfx.cvs.height * relative_scale
    //, RackSpace.ZOOM_DURATION, Easing.Quad.easeInOut, @evHoldingAreaZoomComplete) if @model.showHoldingArea()

    //@fxHoldingAreaBackGround.animate(@holdingAreaImgBackGround,
    //  x      : -@targetOffset.x
    //  y      : -@targetOffset.y
    //  width  : @holdingAreaBackGroundGfx.cvs.width * relative_scale
    //  height : @holdingAreaBackGroundGfx.cvs.height * relative_scale
    //, RackSpace.ZOOM_DURATION, Easing.Quad.easeInOut, @evHoldingAreaZoomComplete) if @model.showHoldingArea()
  }

  evHoldingAreaZoomComplete() {
    return console.log("Holding Area Zoom Completes");
  }

  // called when zoom animation completes, commences fading in of info layer animation
  evRackZoomComplete() {
    // fade in info layer
    const info_img = this.fx2.addImg({ img: this.infoGfx.cvs, x: -this.targetOffset.x, y: -this.targetOffset.y, alpha: 0 });
    return this.fx2.animate(info_img, { alpha: 1 }, RackSpace.INFO_FADE_DURATION, Easing.Quad.easeOut, this.evZoomComplete);
  }


  // called when all phases of zoom animation are complete, destroys fx layers, reveals hidden canvas layers and dispatches zoom complete
  // event
  evZoomComplete() {
    if (this.model.showingRacks()) { this.fx.destroy(); }
    //@fxHoldingArea.destroy() if @model.showHoldingArea()
    //@fxHoldingAreaBackGround.destroy() if @model.showHoldingArea()
    this.fx2.destroy();

    this.rackGfx.setScale(this.targetScale);
    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      this.holdingAreaGfx.setScale(this.targetScale*this.holdingArea.factor);
      this.holdingAreaInfoGfx.setScale(this.targetScale*this.holdingArea.factor);
      this.holdingAreaAlertGfx.setScale(this.targetScale*this.holdingArea.factor);
      this.holdingAreaBackGroundGfx.setScale(this.targetScale);
    }

    this.rackEl.appendChild(this.holdingAreaBackGroundGfx.cvs);
    this.rackEl.appendChild(this.holdingAreaGfx.cvs);
    this.rackEl.appendChild(this.holdingAreaInfoGfx.cvs);
    this.rackEl.appendChild(this.holdingAreaAlertGfx.cvs);
    this.rackEl.appendChild(this.rackGfx.cvs);
    this.rackEl.appendChild(this.rackInfoGfx.cvs);
    this.rackEl.appendChild(this.infoGfx.cvs);
    this.rackEl.appendChild(this.alertGfx.cvs);

    // If target scale is min zoom, then set the rackParent div scroll to 0,0
    if (this.targetScale === this.zoomPresets[0]) {
      this.rackParent.scrollLeft = 0;
      this.rackParent.scrollTop  = 0;
    } else {
      this.rackParent.scrollLeft = this.targetOffset.x;
      this.rackParent.scrollTop  = this.targetOffset.y;
    }

    this.rackGfx.resumeAnims();
    this.holdingAreaBackGroundGfx.resumeAnims();
    this.holdingAreaGfx.resumeAnims();
    this.rackInfoGfx.resumeAnims();
    this.infoGfx.resumeAnims();
    this.alertGfx.resumeAnims();

    this.scale = this.targetScale;
    this.model.scale(this.scale);
    this.zooming = false;
    this.synchroniseZoomIdx();
    if (this.model.showingRacks()) { this.centreRacks(); }
    this.placeHoldingArea(this.targetScale);

    return Events.dispatchEvent(this.rackEl, 'rackSpaceZoomComplete');
  }


  // this visually centres all racks according to the available space in the containing div
  centreRacks() {
    const rack_dims = this.rackEl.getCoordinates();
    const cvs_dims  = this.rackGfx.cvs.getCoordinates();
    const offset    = { x: rack_dims.width - this.scrollAdjust - cvs_dims.width, y: rack_dims.height - this.scrollAdjust - cvs_dims.height };
  
    if (offset.x < 0) { offset.x = 0; }
    if (offset.y < 0) { offset.y = 0; }

    let centre_x = offset.x / 2;
    let centre_y = offset.y / 2;

    centre_x = centre_x + 'px';
    centre_y = centre_y + 'px';

    Util.setStyle(this.rackGfx.cvs, 'left', centre_x);
    Util.setStyle(this.rackInfoGfx.cvs, 'left', centre_x);
    Util.setStyle(this.infoGfx.cvs, 'left', centre_x);
    Util.setStyle(this.alertGfx.cvs, 'left', centre_x);

    Util.setStyle(this.rackGfx.cvs, 'top', centre_y);
    Util.setStyle(this.rackInfoGfx.cvs, 'top', centre_y);
    Util.setStyle(this.infoGfx.cvs, 'top', centre_y);
    Util.setStyle(this.alertGfx.cvs, 'top', centre_y);
  }

  getRackAt(x, y) {

    if (this.model.showingRacks()) {
      for (var rack of Array.from(this.racks)) {
        // only query the rack if the coordinates lie within it's boundaries
        if ((x > rack.x) && (x < (rack.x + rack.width)) && (y > rack.y) && (y < (rack.y + rack.height))) {
          return rack;
        }
      }
    }
  }

  // public method, finds a devices at the given coordinates, this facilitates highlighting on mouse hover
  // @param  x   the x coordinate relative to the rack canvas layer and scale adjusted
  // @param  y   the y coordinate relative to the rack canvas layer and scale adjusted
  // @return     a reference to the device instance at the specified coordinates or null if none is found
  getDeviceAt(x, y) {
    let device;
    if (this.model.showingRacks()) {
      for (var rack of Array.from(this.racks)) {
        // only query the rack if the coordinates lie within it's boundaries
        if ((x > rack.x) && (x < (rack.x + rack.width)) && (y > rack.y) && (y < (rack.y + rack.height))) {
          device = rack.getDeviceAt(x, y);
          if (device != null) { return device; } else { return rack; }
        }
      }
    }

    if (this.model.showHoldingArea()) {
      if (this.holdingArea.overTheHoldingArea()) {
        device = this.holdingArea.getDeviceAt(null,null);
        if (device != null) { return device; }
      }
    }

    return null;
  }


  // public method, displays a hover hint for a device
  // @param  abs_coords  an object with x/y properties of the absolute coordinates. This is necessary to position the hint
  // @param  rel_coords  an object with x/y properties of the relative coordinates. This is necessary to find the device
  showHint(abs_coords, rel_coords) {
    if (this.contextMenu.visible) { return; }

    rel_coords.x /= this.scale;
    rel_coords.y /= this.scale;

    let device = this.getDeviceAt(rel_coords.x, rel_coords.y);
  
    // no device? Nothing to do
    if (device == null) { return; }

    // ignore blades if viewing chassis level metrics
    if (device.pluggable && (this.metricLevel === 'chassis')) { device = device.parent(); }
    if (device instanceof ImageLink || device instanceof Link) { device = device.parent(); }
    return this.hint.show(device, abs_coords.x, abs_coords.y);
  }


  // hides the hover hint
  hideHint() {
    return this.hint.hide();
  }


  // public method, reveals the context menu at a given location
  showContextMenu(abs_coords, rel_coords) {
    let available_slot;
    this.contextMenu.hide();
    this.highlightAt(rel_coords.x, rel_coords.y);
    const original_coord = {x:rel_coords.x,y:rel_coords.y};
    rel_coords.x /= this.scale;
    rel_coords.y /= this.scale;

    let selection = this.getDeviceAt(rel_coords.x, rel_coords.y);
    if (selection != null) {
      if (selection.pluggable && (this.metricLevel === 'chassis')) { selection = selection.parent(); }
      if (selection instanceof ImageLink || selection instanceof Link) { selection = selection.parent(); }
    }

    this.hint.hide();

    // chassis only functionality, to include a context menu option 'Add blade' for an empty slot
    if (selection != null) {
      if (selection instanceof Chassis || selection instanceof Rack) {
        available_slot = selection.getSlot(rel_coords.x, rel_coords.y);
        if ((available_slot != null) && (available_slot.device != null) && (available_slot.device.template.depth === 2)) {
          available_slot = null;
        } else if (available_slot != null) {
          available_slot.type = selection instanceof Chassis ? 'chassis' : 'rack';
        }
        if (selection instanceof Chassis) {
          this.device_to_drag_coords = original_coord;
        }
      } else if (selection instanceof Machine) {
        if (!selection.placedInCurrentView()) {
          selection = selection.parent().parent();
          available_slot = selection.getSlot(rel_coords.x, rel_coords.y);
          available_slot.type = 'rack';
        }
        this.device_to_drag_coords = original_coord;
      }
    }

    if (!!this.model.showingFullIrv() || !(selection == null)) { return this.contextMenu.show(selection, abs_coords.x, abs_coords.y, available_slot); }
  }


  // context menu click event handler, actions internal operations originating from the context menu
  // @param  param_str   a string detailing the operation to action and any required parameters
  evContextClick(param_str) {
    if (param_str == null) { return; }

    const params = param_str.split(',');

    switch (params[0]) {
      case 'focusOn':
        return this.focusOn(params[1], params[2]);
      case 'statusChangeRequest':
        if (params[1] !== 'destroy' || confirm(`Are you sure you want to destroy ${params[4]}? This cannot be undone.`)) {
          return this.requestStatusChange(params[1], params[2], params[3], params[4]);
        }
      case 'reset':
        return Events.dispatchEvent(this.rackEl, 'rackSpaceReset');
      case 'clearDeselected':
        return Events.dispatchEvent(this.rackEl, 'rackSpaceClearDeselected');
      case 'reSelectAll':
        CrossAppSettings.clear('irv');
        return window.location = "/irv";
      case 'startDraggingDevice':
        return this.startDraggingDevice();
    }
  }

  startDraggingDevice() {
    this.dragDeviceFromMenu();
    Events.addEventListener(this.rackEl, 'mousemove', this.dragDeviceFromMenu);
    return Events.addEventListener(this.rackEl, 'mouseup', this.stopDraggingDeviceFromMenu);
  }

  dragDeviceFromMenu(ev) {
    if (!this.dragging) {
      this.dragging = true;
      if (this.dragging) {
        this.clickAssigned = true;
        this.startDrag(this.device_to_drag_coords.x, this.device_to_drag_coords.y);
        return this.fx.setAttributes(this.dragImg, { x: this.device_to_drag_coords.x + this.contextMenu.coords.x + this.dragImgOffset.x, y: this.device_to_drag_coords.y + this.contextMenu.coords.y + this.dragImgOffset.y });
      }
    } else {
      const coords = Util.resolveMouseCoords(this.coordReferenceEl, ev);
      return this.drag(coords.x, coords.y);
    }
  }

  stopDraggingDeviceFromMenu(ev) {
    this.upCoords = Util.resolveMouseCoords(this.coordReferenceEl, ev);
    //clearTimeout(@clickTmr)
    Events.removeEventListener(this.rackEl, 'mousemove', this.dragDeviceFromMenu);
  
    // decide if this is a single or double-click
    if (this.dragging) {
      const coords = Util.resolveMouseCoords(this.coordReferenceEl, ev);
      this.stopDrag(coords.x, coords.y);
      this.clickAssigned = true;
      this.dragging      = false;
    }
  }


  setRackAsFocused(rack_id) {
    const rack = this.racks.filter(r => r.id === rack_id);
    if (rack[0] != null) {
      return this.model.deviceLookup().racks[rack_id].focused = rack[0].setFocus();
    }
  }


  clearAllRacksAsFocused() {
    return (() => {
      const result = [];
      for (var rack of Array.from(this.racks)) {
        if (rack.hasFocus()) {
          result.push(this.model.deviceLookup().racks[rack.id].focused = rack.clearFocus());
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  requestStatusChange(action, type, id, name) {
    const typeName = type.slice(0, -1);
    let target = Util.substitutePhrase(ContextMenu.ACTION_PATHS[type], `${typeName}_id`, id);
    target = Util.substitutePhrase(target, 'action', action);
    fetch(target, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')
      }
    })
      .then(response => response.json())
      .then(data => {
        this.updateRequestFlash(data, action, type, name);
      })
      .catch(error => {
        this.updateRequestFlash({success: false, errors: [`Unknown server error`]}, action, type, name);
      }
    );
  }

  updateRequestFlash(result, action, recordType, name) {
    const template = document.getElementById('flash-template');
    let newFlash = template.clone();
    let type = result.success ? "info" : "alert";
    newFlash.id = `${type}Container`;
    if (!result.success) {
      newFlash.removeClass('info');
      newFlash.addClass('alert');
    }
    const capitalizedAction = action.charAt(0).toUpperCase() + action.slice(1);
    let content = "";
    if (result.success) {
      content = `${capitalizedAction} request submitted for ${recordType.slice(0, -1)} ${name}`;
    } else {
      content = `${capitalizedAction} request failed for ${recordType.slice(0, -1)} ${name}: ${result.errors.join('; ')}`;
    }
    newFlash.getElementsByClassName('flash-content')[0].innerHTML = content;
    document.getElementById('flash-messages').append(newFlash);
  }

  // creates a selection containing a specific device and (recursively) all of its children and zooms the view on to that device
  // @param  group   the category/id pool to which the device belongs (rack, chassis etc.)
  // @param  id      the specific id of the device
  focusOn(group, id) {
    const target = this.model.deviceLookup()[group][id];
    if (group === "racks") {
      this.clearAllRacksAsFocused();
      this.setRackAsFocused(id); // Here we set a flag against only racks to say they have been focused on specifically, 
    }
                            // there is no need at the moment to set such a flag on any other objects...
    if (target == null) { return; }

    let left_bound  = Number.MAX_VALUE;
    let right_bound = -Number.MAX_VALUE;
    let upper_bound = Number.MAX_VALUE;
    let lower_bound = -Number.MAX_VALUE;

    // lists the physical locations of each instance of the target device
    const regions = [];

    for (var instance of Array.from(target.instances)) {
      if (!instance.visible) { continue; }

      var instance_right  = instance.x + instance.width;
      var instance_bottom = instance.y + instance.height;

      // find the smallest possible box which will fit around our selection
      if (instance.x < left_bound) { left_bound  = instance.x; }
      if (instance_right > right_bound) { right_bound = instance_right; }
      if (instance.y < upper_bound) { upper_bound = instance.y; }
      if (instance_bottom > lower_bound) { lower_bound = instance_bottom; }

      regions.push({ left: instance.x, right: instance_right, top: instance.y, bottom: instance_bottom });
    }

    const bound_width  = right_bound - left_bound;
    const bound_height = lower_bound - upper_bound; 

    const centre_x = (left_bound + (bound_width / 2)) * this.scale;
    const centre_y = (upper_bound + (bound_height / 2)) * this.scale;

    const dims    = Util.getElementDimensions(this.rackEl);
    const scale_x = (dims.width - this.scrollAdjust) / bound_width;
    const scale_y = (dims.height - this.scrollAdjust) / bound_height;
    const scale   = scale_x > scale_y ? scale_y : scale_x;

    // commence zoom animation sequence
    this.quickZoom(centre_x, centre_y, scale);

    let active_selection = false;
    const selection        = {};
    const groups           = this.model.groups();
    for (group of Array.from(groups)) { selection[group] = {}; }

    // compile a selection of all target device instances and all of their children recursively
    for (var region of Array.from(regions)) {
      var sub_sel = this.selectWithin(region, false);
      if (sub_sel != null) {
        active_selection = true;
        for (group in sub_sel) {
          var set = sub_sel[group];
          for (id in set) { selection[group][id] = true; }
        }
      }
    }

    // update model
    this.model.activeSelection(active_selection);
    return this.model.selectedDevices(selection);
  }


  // gets a list of device instances which are physically contained by any specified box.
  // @param  box         object defining the box containing properties 'left', 'right', 'top' and 'bottom'
  // @param  inclusive   boolean, indicates wether to performa an inclusive selection (all devices contained or touching the box) or
  //                     exclusive selection (only devices entirely encapsulated by the box)
  // @return array of device instances which satisfy the selection or null if nothing
  selectWithin(box, inclusive) {
    let group;
    let active_selection = false;
    const groups           = this.model.groups();
    const selected         = {};
    for (group of Array.from(groups)) { selected[group]  = {}; }

    for (var rack of Array.from(this.racks)) {
      var subselection = rack.selectWithin(box, inclusive);
      for (group of Array.from(groups)) {
        for (var i in subselection[group]) {
          // we only want to display a subset of metrics when at least one device or chassis is selected i.e. ignore rack only selections
          // additionally ignore native object properties, hence isNaN/parseInt stuff
          if (!isNaN(Number(subselection[group][i]))) {
            active_selection   = true;
            selected[group][i] = true;
          }
        }
      }
    }
            
    if (active_selection) {
      return selected;
    } else {
      return;
    }
  }


  // determine how the racks are layed out. This is a two phase operation: (1) find the number of rows/cols with a width/heigth ratio
  // which most closely matches the width/height ratio of the containing div (this should geometrically be the arrangement which results in
  // minimum whitespace) (2) systematically adjust the row width in an attempt to reduce the number of empty spaces on the last row. This
  // is to avoid the situation where the row width is say 20 racks but the last row has only three racks (and a lot of white space after
  // it). The second phase can lead to a significant digression from the first phase.
  arrangeRacks() {
    super.arrangeRacks(...arguments);
    this.rackInfoGfx.setDims(this.racksWidth, this.racksHeight);
    this.infoGfx.setDims(this.racksWidth, this.racksHeight);
    return this.alertGfx.setDims(this.racksWidth, this.racksHeight);
  }

  // sets a call back on rackGfx draw frame completion
  updateRackImage() {
    // delay setting the image for one frame to give the renderer time to redraw
    return this.rackGfx.drawComplete = this.evRedrawComplete;
  }


  // called by rackGfx draw frame complete, updates the images of the racks in the model, this allows the thumb nav to maintain an
  // up-to-date image
  evRedrawComplete() {
    this.rackGfx.drawComplete = null;
    return this.model.rackImage(this.rackGfx.cvs);
  }

  // viewMode model value subscriber, redraws rack view to reflect new view mode
  switchView() {
    this.draw();
  }

  redraw() {
    this.removeHighlights();
    return this.draw();
  }

  // metricLevel model subscriber, creates a selection of relevant devices when changing metric level.
  // @param  metric_level  the new value of metric level
  setMetricLevel(metric_level) {
    let device, group, id;
    this.metricLevel = metric_level;
    const groups       = this.model.groups();
    const selection    = {};
    for (group of Array.from(groups)) { selection[group] = {}; }

    const device_lookup = this.model.deviceLookup();
  
    //
    // "selection" is built up based on the layer selected (here the layer is called "metric level").
    //

    //CHASSIS (or 'ALL')
    if ((metric_level === ViewModel.METRIC_LEVEL_CHASSIS) || (metric_level === ViewModel.METRIC_LEVEL_ALL)) {
      for (id in device_lookup.chassis) {
        device = device_lookup.chassis[id];
        if (this.selectionAndNotSelected(device) || this.noHoldingAndInHolding(device)) { continue; }
        if (device.instances[0].complex) {
          selection[device.instances[0].group][device.instances[0].id] = true;
          for (var child of Array.from(device.instances[0].children)) { selection[child.group][child.id] = true; }
        }
      }
    }

    //DEVICES (or 'ALL')
    if ((metric_level === ViewModel.METRIC_LEVEL_DEVICES) || (metric_level === ViewModel.METRIC_LEVEL_ALL)) {
      for (id in device_lookup.devices) {
        device = device_lookup.devices[id];
        if (this.selectionAndNotSelected(device) || this.noHoldingAndInHolding(device)) { continue; }
        selection[device.instances[0].group][device.instances[0].id] = true;
      }
    }

    this.model.activeSelection(true);
    return this.model.selectedDevices(selection);
  }

  // Validates if not showing holding area, and device is in the holding area
  noHoldingAndInHolding(device) {
    return (this.model.showHoldingArea() === false) && (device.instances[0].placedInHoldingArea() === true);
  }

  // Validates if there is an active selection, and device is not selected
  selectionAndNotSelected(device) {
    return this.model.activeSelection() && !__guard__(this.model.selectedDevices()[device.instances[0].group], x => x[device.instances[0].id]);
  }
};
RackSpace.initClass();
export default RackSpace;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
