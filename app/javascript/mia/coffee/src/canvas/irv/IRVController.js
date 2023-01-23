/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// ╔═════╦════════════════════════════════════╗
// ║ IRV ║ ~ ©Concurrent Thinking Ltd. 2012 ~ ║
// ╚═════╩════════════════════════════════════╝

import CanvasController from '../../canvas/common/CanvasController';
import CrossAppSettings from '../../canvas/common/util/CrossAppSettings';
import UpdateMsg from '../../canvas/irv/view/UpdateMsg';
import Configurator from '../../canvas/irv/util/Configurator';
import Events from '../../canvas/common/util/Events';
import Util from '../../canvas/common/util/Util';
import AssetManager from '../../canvas/irv/util/AssetManager';
import Hint from '../../canvas/irv/view/Hint';
import ThumbHint from '../../canvas/irv/view/ThumbHint';
import RackSpace from '../../canvas/irv/view/RackSpace';
import Rack from '../../canvas/irv/view/Rack';
import PowerStrip from '../../canvas/irv/view/PowerStrip';
import Socket from '../../canvas/irv/view/Socket';
import ThumbNav from '../../canvas/common/widgets/ThumbNav';
import FilterBar from '../../canvas/common/widgets/FilterBar';
import ViewModel from '../../canvas/irv/ViewModel';
import Parser from '../../canvas/irv/util/Parser';
import PresetManager from '../../canvas/common/util/PresetManager';
import StaticGroupManager from '../../canvas/common/util/StaticGroupManager'
import Profiler from 'Profiler';
// import  'util/ComboBox'
import Tooltip from '../../canvas/irv/view/Tooltip';
import PieCountdown from '../../canvas/common/widgets/PieCountdown';
import RBAC from '../../canvas/common/util/RBAC';

// These are all expected to provide global objects.
// import 'AjaxPopup'; //legacy
// import 'MessageSlider'; //legacy
// import 'canvg'; //inc


class IRVController extends CanvasController {
  static initClass() {
    // statics overwritten by config
    this.DOUBLE_CLICK_TIMEOUT          = 250;
    this.DRAG_ACTIVATION_DIST          = 8;
    this.RACK_HINT_HOVER_DELAY         = 2000;
    this.RACK_PAGE_HEIGHT_PROPORTION   = .7;
    this.ZOOM_KEY                      = 32;
    this.STEP_ZOOM_AMOUNT              = .01;
    this.THUMB_WIDTH                   = 200;
    this.MULTI_SELECT_KEY              = 17;
    this.THUMB_HEIGHT                  = 130;
    this.PRIMARTY_IMAGE_PATH           = '../';
    this.SECONDARY_IMAGE_PATH          = '../';
    this.THUMB_HINT_HOVER_DELAY        = 500;
    this.API_RETRY_DELAY               = 5000;
    this.SCREENSHOT_FILENAME           = 'rarararar.jpg';
    this.EXPORT_FILENAME               = 'haaai.txt';
    this.EXPORT_HEADER                 = '';
    this.EXPORT_RECORD                 = '';
    this.EXPORT_MESSAGE                = 'Saving IRV image, please wait...';
    this.NAV_HIDE_LAYOUT_UPDATE_DELAY  = 1000;
    this.EXPORT_IMAGE_URL              = '/-/api/v1/irv/racks/export_image';
    this.BREACH_POLL_RATE              = 60000;
    this.METRIC_POLL_EDIT_DELAY        = 2000;
    this.METRIC_TEMPLATES_POLL_RATE     = 113000;
    this.MIN_METRIC_POLL_RATE          = 600;
    this.INVALID_POLL_COLOUR           = '#f99';
    this.DEFAULT_METRIC_STAT           = 'max';
    this.MODIFIED_RACK_POLL_RATE       = 60000;
    this.MODIFIED_POWER_STRIPS_POLL_RATE       = 60000;
    this.RANGE_EXPANSION_FACTOR        = 0.05;

    this.MAIN_PAGE_CONTENT_ID          = 'pageContent';
    this.CANVAS_CONTENT_ID             = 'interactive_canvas_view';
    this.BOTTOM_PADDING                = 20;
  }

  constructor(options) {
    super(...arguments);

    this.getUserRoles = this.getUserRoles.bind(this);
    this.configReceived = this.configReceived.bind(this);
    this.evShowHideScrollBars = this.evShowHideScrollBars.bind(this);
    this.getPowerStripDefs = this.getPowerStripDefs.bind(this);
    this.getNonrackDeviceDefs = this.getNonrackDeviceDefs.bind(this);
    this.visibleRackIds = this.visibleRackIds.bind(this);
    this.visibleNonRackIds = this.visibleNonRackIds.bind(this);
    this.visiblePowerStripIds = this.visiblePowerStripIds.bind(this);
    this.idsAsParams = this.idsAsParams.bind(this);
    this.enableShowHoldingAreaCheckBox = this.enableShowHoldingAreaCheckBox.bind(this);
    this.getModifiedRacksTimestamp = this.getModifiedRacksTimestamp.bind(this);
    this.getModifiedPowerStripsTimestamp = this.getModifiedPowerStripsTimestamp.bind(this);
    this.setModifiedRacksTimestamp = this.setModifiedRacksTimestamp.bind(this);
    this.setModifiedPowerStripsTimestamp = this.setModifiedPowerStripsTimestamp.bind(this);
    this.getSystemDateTime = this.getSystemDateTime.bind(this);
    this.getSystemDateTimeForPowerStrip = this.getSystemDateTimeForPowerStrip.bind(this);
    this.getModifiedRackIds = this.getModifiedRackIds.bind(this);
    this.getModifiedPowerStripIds = this.getModifiedPowerStripIds.bind(this);
    this.getMetricTemplates = this.getMetricTemplates.bind(this);
    this.getThresholds = this.getThresholds.bind(this);
    this.receivedThresholds = this.receivedThresholds.bind(this);
    this.metricTemplatesPoller = this.metricTemplatesPoller.bind(this);
    this.refreshMetricTemplates = this.refreshMetricTemplates.bind(this);
    this.retryMetricTemplates = this.retryMetricTemplates.bind(this);
    this.retryRackDefs = this.retryRackDefs.bind(this);
    this.retryPowerStripDefs = this.retryPowerStripDefs.bind(this);
    this.retryNonrackDeviceDefs = this.retryNonrackDeviceDefs.bind(this);
    this.retrySystemDateTime = this.retrySystemDateTime.bind(this);
    this.loadBreaches = this.loadBreaches.bind(this);
    this.scrollPanelUp = this.scrollPanelUp.bind(this);
    this.evReceivedBreaches = this.evReceivedBreaches.bind(this);
    this.evClearDeselected = this.evClearDeselected.bind(this);
    this.evReset = this.evReset.bind(this);
    this.evResetZoom = this.evResetZoom.bind(this);
    this.evResetFilters = this.evResetFilters.bind(this);
    this.evZoomIn = this.evZoomIn.bind(this);
    this.evZoomOut = this.evZoomOut.bind(this);
    this.saveScreen = this.saveScreen.bind(this);
    this.exitToDCPV = this.exitToDCPV.bind(this);
    this.printScreen = this.printScreen.bind(this);
    this.exportData = this.exportData.bind(this);
    this.evMouseUpMetricSelect = this.evMouseUpMetricSelect.bind(this);
    this.evBlurSelect = this.evBlurSelect.bind(this);
    this.evHideNav = this.evHideNav.bind(this);
    this.evResize = this.evResize.bind(this);
    this.updateLayout = this.updateLayout.bind(this);
    this.resetMetricPoller = this.resetMetricPoller.bind(this);
    this.showHideExportDataOption = this.showHideExportDataOption.bind(this);
    this.switchMetric = this.switchMetric.bind(this);
    this.switchMetricLevel = this.switchMetricLevel.bind(this);
    this.receivedMetricTemplates = this.receivedMetricTemplates.bind(this);
    this.refreshedMetricTemplates = this.refreshedMetricTemplates.bind(this);
    this.receivedModifiedRackIds = this.receivedModifiedRackIds.bind(this);
    this.receivedModifiedNonRackIds = this.receivedModifiedNonRackIds.bind(this);
    this.receivedModifiedPowerStripIds = this.receivedModifiedPowerStripIds.bind(this);
    this.receivedRackDefs = this.receivedRackDefs.bind(this);
    this.recievedPowerStripDefs = this.recievedPowerStripDefs.bind(this);
    this.recievedNonrackDeviceDefs = this.recievedNonrackDeviceDefs.bind(this);
    this.loadMetrics = this.loadMetrics.bind(this);
    this.receivedMetrics = this.receivedMetrics.bind(this);
    this.displayMetrics = this.displayMetrics.bind(this);
    this.displayVHMetrics = this.displayVHMetrics.bind(this);
    this.evMouseWheelRack = this.evMouseWheelRack.bind(this);
    this.evMouseWheelThumb = this.evMouseWheelThumb.bind(this);
    this.evKeyDown = this.evKeyDown.bind(this);
    this.evKeyUp = this.evKeyUp.bind(this);
    this.evRightClickRack = this.evRightClickRack.bind(this);
    this.evMouseDownRack = this.evMouseDownRack.bind(this);
    this.evMouseUpRack = this.evMouseUpRack.bind(this);
    this.evClick = this.evClick.bind(this);
    this.evDoubleClick = this.evDoubleClick.bind(this);
    this.evDrag = this.evDrag.bind(this);
    this.evMouseMoveRack = this.evMouseMoveRack.bind(this);
    this.evMouseMoveThumb = this.evMouseMoveThumb.bind(this);
    this.evMouseOutRacks = this.evMouseOutRacks.bind(this);
    this.evMouseOutThumb = this.evMouseOutThumb.bind(this);
    this.evZoomComplete = this.evZoomComplete.bind(this);
    this.evFlipComplete = this.evFlipComplete.bind(this);
    this.evMouseDownChart = this.evMouseDownChart.bind(this);
    this.evMouseUpChart = this.evMouseUpChart.bind(this);
    this.evDragChart = this.evDragChart.bind(this);
    this.showRackHint = this.showRackHint.bind(this);
    this.showThumbHint = this.showThumbHint.bind(this);
    this.applyFilter = this.applyFilter.bind(this);
    this.evScrollRacks = this.evScrollRacks.bind(this);
    this.evRedrawRackSpace = this.evRedrawRackSpace.bind(this);
    this.evLoadRackAssets = this.evLoadRackAssets.bind(this);
    this.evMouseDownThumb = this.evMouseDownThumb.bind(this);
    this.evMouseUpThumb = this.evMouseUpThumb.bind(this);
    this.evDoubleClickThumb = this.evDoubleClickThumb.bind(this);
    this.thumbScroll = this.thumbScroll.bind(this);
    this.switchFace = this.switchFace.bind(this);
    this.showOrHidePowerStripLayer = this.showOrHidePowerStripLayer.bind(this);
    this.updateShowOrHidePowerStripsLink = this.updateShowOrHidePowerStripsLink.bind(this);
    this.evMouseDownFilter = this.evMouseDownFilter.bind(this);
    this.evMouseOutFilter = this.evMouseOutFilter.bind(this);
    this.evMouseUpFilter = this.evMouseUpFilter.bind(this);
    this.evMouseMoveFilter = this.evMouseMoveFilter.bind(this);
    this.evFilterStopDrag = this.evFilterStopDrag.bind(this);
    this.switchPreset = this.switchPreset.bind(this);
    this.evGetHintInfo = this.evGetHintInfo.bind(this);
    this.evEditMetricPoll = this.evEditMetricPoll.bind(this);
    this.evSetMetricPoll = this.evSetMetricPoll.bind(this);
    this.evResetMetricPoller = this.evResetMetricPoller.bind(this);
    this.setMetricPoll = this.setMetricPoll.bind(this);
    this.setMetricPollInput = this.setMetricPollInput.bind(this);
    this.evDropFilterBar = this.evDropFilterBar.bind(this);
    this.hintInfoReceived = this.hintInfoReceived.bind(this);
    this.evSwitchStat = this.evSwitchStat.bind(this);
    this.evSwitchGroup = this.evSwitchGroup.bind(this);
    this.evSwitchGraphOrder = this.evSwitchGraphOrder.bind(this);
    this.evShowVMs = this.evShowVMs.bind(this);
    this.evHideVMs = this.evHideVMs.bind(this);
    this.loadVMMetrics = this.loadVMMetrics.bind(this);
    this.receivedVMMetrics = this.receivedVMMetrics.bind(this);
    if (options == null) { options = {}; }
    this.options = options;
    this.config_file = '/-/irv/configuration';
    console.log("Constructing IRV :::: with the options :::: ",this.options);
    $(document).ready(this.getConfig);

    // Store global reference to controller
    document.IRV = this;
  }

  getUserRoles() {
    return this.model.RBAC = new RBAC();
  }

  // called on successful load of confuration file. Applies application configuration, overwrites view model startup state with
  // any parameters passed in querystring, initialises model and parser and commences load sequence
  // @param  config  configuration object
  configReceived(config) {
    Configurator.setup(CanvasController, IRVController, config);
    AssetManager.setup(); 

    // grab url params if any and set model values
    let params = String(window.location);
    params = params.substr(params.indexOf('?') + 1);
    if (params.length > 0) {
      params = params.split('&');
      for (var param of Array.from(params)) {
        var parts = param.split('=');
        // parse strings to booleans
        if (parts[1] === 'true') { parts[1] = true; }
        if (parts[1] === 'false') { parts[1] = false; }
        ViewModel[parts[0]] = parts[1];
      }
    }

    this.model = new ViewModel();

    this.crossAppSettings = CrossAppSettings.get('irv');

    this.filterCrossAppSettings();

    this.getUserRoles();
    ko.applyBindings(this.model);

    if (((this.options != null ? this.options.show : undefined) != null) && Array.from(this.options_show).includes("full_irv")) {
      this.model.showingFullIrv(true);
      this.model.showingRacks(true);
    }

    if (!this.model.showingFullIrv()) {
      this.model.showChart(false);
      FilterBar.THICKNESS = 0;
    }

    if (this.model.showingFullIrv()) { this.groups = new StaticGroupManager(this.model, this.crossAppSettings.selectedGroup); }

    this.parser   = new Parser(this.model);
    this.setResources();

    if (((this.options != null ? this.options.show : undefined) != null) && Array.from(this.options_show).includes("racks")) {
      this.model.showingRacks(true);
    }
  
    if (((this.options != null ? this.options.show : undefined) != null) && Array.from(this.options_show).includes("rack_thumbnail")) {
      this.model.showingRacks(true);
      this.model.showingRackThumbnail(true);
    }

    if (((this.options != null ? this.options.show : undefined) != null) && Array.from(this.options_show).includes("power_strips") && (this.options.powerStripIds != null)) {
      this.model.showingPowerStrips(true);
    }

    this.evLoadRackAssets();

    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      CanvasController.NUM_RESOURCES += 1;
      this.getNonrackDeviceData();
    }

    if (this.model.showingRacks()) {
      CanvasController.NUM_RESOURCES += 1;
      if (this.model.showingFullIrv()) {
        CanvasController.NUM_RESOURCES += 2; // metricstemplates and thresholds
      }
      this.getRackData();
    }

    if (this.model.showingPowerStrips() || (this.model.showingRacks() && !this.model.showingFullIrv() && (this.options.powerStripIds != null))) {
      CanvasController.NUM_RESOURCES += 1;
      this.getPowerStripData();
    }

    //if @model.showingFullIrv()
    this.stylesChanges();
    return this.showHideScrollBars(0);
  }

  stylesChanges() {
    const pageBox = $('pageBox');
    Util.setStyle(pageBox, 'overflow-x', 'hidden');
    return Util.setStyle(pageBox, 'overflow-y', 'hidden');
  }

  filterCrossAppSettings() {
    // the focus property is a value written to the page indicating if to focus in on a specific device (having clicked through from
    // the device show page). If defined this over writes any selection carried over from the DCPV
    let focus_filter;
    const focus = $(this.options.parent_div_id).get('data-focus');
    const filter = $(this.options.parent_div_id).get('data-filter');
    if (focus != null) {
      focus_filter = {};
      focus_filter[focus.split(',')[2]] = true;
    }
    if (filter != null) {
      this.model.displayingAllRacks(false);
      focus_filter = {};
      focus_filter[filter.split(',')[1]] = true;
    }
    if ((focus != null) || (filter != null)) {
      this.crossAppSettings.selectedRacks = focus_filter;
      return this.crossAppSettings.selectedNonRackChassis = {};
    }
  }

  evShowHideScrollBars() {
    return this.showHideScrollBars(this.rackSpace.zoomIdx);
  }

  showHideScrollBars(zoomIndex) {
    const rv = $(this.options.parent_div_id);
    if (this.model.showingPowerStrips() && !this.model.showingRacks()) {
      Util.setStyle(rv, 'overflow-x', 'hidden');
      Util.setStyle(rv, 'overflow-y', 'hidden');
      Util.setStyle($('device_overview_div'), 'overflow-x', 'auto');
      return Util.setStyle($('device_overview_div'), 'overflow-y', 'auto');
    } else {
      if ((zoomIndex === 0) && (this.model.showHoldingArea() === false)) {
        Util.setStyle(rv, 'overflow-x', 'hidden');
        return Util.setStyle(rv, 'overflow-y', 'hidden');
      } else {
        Util.setStyle(rv, 'overflow-x', 'auto');
        return Util.setStyle(rv, 'overflow-y', 'auto');
      }
    }
  }

  // creates metric combo box select event handler
  connectMetricCombos() {
    ComboBox.connect_all('cbox');
    if (ComboBox.boxes.metrics != null) {
      this.model.metricIds.subscribe(new_metric_ids => {
        return ComboBox.boxes.metrics.updateDataIds(new_metric_ids);
      });
      ComboBox.boxes.metrics.add_change_callback(() => {
        return this.model.selectedMetric(ComboBox.boxes.metrics.value);
      });
    }
    if (ComboBox.boxes.groups != null) {
      return ComboBox.boxes.groups.add_change_callback(() => {
        return this.model.selectedGroup(ComboBox.boxes.groups.value);
      });
    }
  }

  // makes server requests required for initialisation
  getRackData() {
    super.getRackData(...arguments);
    if (this.model.showingFullIrv()) { this.getMetricTemplates(); }
    if (this.model.showingFullIrv()) { this.getThresholds(); }
    this.testLoadProgress();
    return this.getSystemDateTime();
  }

  getPowerStripData() {
    let ps_ids = this.options.powerStripIds.split(",");
    this.model.powerStripsVisible = this.model.powerStripsVisible.concat(ps_ids.map(oneId => parseInt(oneId,10)));
    if (this.options.otherPowerStripIds != null) { ps_ids = ps_ids.concat(this.options.otherPowerStripIds.split(",")); }
    this.getPowerStripDefs(ps_ids);
    return this.getSystemDateTimeForPowerStrip();
  }

  getNonrackDeviceData() {
    return this.getNonrackDeviceDefs();
  }

  // load PowerStrip defenitions
  // @param  power_strips_ids  option array of PowerStrip ids to fetch
  getPowerStripDefs(power_strip_ids) {
    const query_str = (power_strip_ids != null) ? this.idsAsParams(power_strip_ids,'power_strip_ids') : '';

    return new Request.JSON({url: this.resources.path + this.resources.powerStripDefinitions + '?' + (new Date()).getTime() + query_str, onComplete: this.recievedPowerStripDefs, onTimeout: this.retryPowerStripDefs}).get();
  }

  getNonrackDeviceDefs(holding_area_ids, non_rack_ids) {
    let query_holding = '';
    if (holding_area_ids != null) { 
      if (holding_area_ids.length > 0) {
        query_holding = this.idsAsParams(holding_area_ids,'rackable_non_rack_ids');
      } else {
        query_holding = '&rackable_non_rack_ids[]=';
      }
    }
    let query_str = '';
    if (non_rack_ids != null) {
      if (non_rack_ids.length > 0) {
        query_str = this.idsAsParams(non_rack_ids,'non_rack_ids');
      } else {
        query_str = '&non_rack_ids[]=';
      }
    }

    return new Request.JSON({url: this.resources.path + this.resources.nonrackDeviceDefinitions + '?' + (new Date()).getTime() + query_holding + query_str, onComplete: this.recievedNonrackDeviceDefs, onTimeout: this.retryNonrackDeviceDefs}).get();
  }

  // collates an array of rack ids based on what is currently on display
  visibleRackIds() {
    const arr = [];
    for (var rack of Array.from(this.model.racks())) {
      arr.push(rack.id);
    }

    return arr;
  }

  visibleNonRackIds() {
    const arr = [];
    for (var non_rack of Array.from(this.model.dcrvShowableNonRackChassis())) {
      arr.push(non_rack.id);
    }

    return arr;
  }

  visiblePowerStripIds() {
    const arr = [];
    for (var powerStrip of Array.from(this.model.powerStrips())) {
      arr.push(powerStrip.id);
    }

    return arr;
  }

  idsAsParams(non_rack_ids, array_name) {
    let params = "";
    for (var non_rack_id of Array.from(non_rack_ids)) {
      params += "&"+array_name+"[]=" + non_rack_id;
    }

    return params;
  }

  enableShowHoldingAreaCheckBox() {
    if (this.model.racks().length > 5) {
      return this.holdingAreaCheckBox.disabled = true;
    } else {
      return this.holdingAreaCheckBox.disabled = false;
    }
  }

  // returns the value stored in @modifiedRacksTimestamp, initialising it with the current timestamp if null 
  getModifiedRacksTimestamp() {
    return this.modifiedRacksTimestamp || (this.modifiedRacksTimestamp = Math.round(+new Date()/1000));
  }

  // returns the value stored in @modifiedPowerStripsTimestamp, initialising it with the current timestamp if null 
  getModifiedPowerStripsTimestamp() {
    return this.modifiedPowerStripsTimestamp || (this.modifiedPowerStripsTimestamp = Math.round(+new Date()/1000));
  }


  // called when receiving time from server, extracts time in milliseconds and stores it
  // @param  timestamp string representation of current time from server
  setModifiedRacksTimestamp(timestamp) {
    //XXX Split method is used for when we load the servers time, as it comes back in the following format: '1380642828661 3600 BST 2013-10-01 16:53:48'
    timestamp = String(timestamp);
    if (timestamp.length >= 13) { // we have a timestamp in milliseconds
      return this.modifiedRacksTimestamp = Math.round(timestamp.match(/.{1,13}/g)[0] / 1000);
    } else {
      return this.modifiedRacksTimestamp = timestamp;
    }
  }

  // called when receiving time from server, extracts time in milliseconds and stores it
  // @param  timestamp string representation of current time from server
  setModifiedPowerStripsTimestamp(timestamp) {
    //XXX Split method is used for when we load the servers time, as it comes back in the following format: '1380642828661 3600 BST 2013-10-01 16:53:48'
    timestamp = String(timestamp);
    if (timestamp.length >= 13) { // we have a timestamp in milliseconds
      return this.modifiedPowerStripsTimestamp = Math.round(timestamp.match(/.{1,13}/g)[0] / 1000);
    } else {
      return this.modifiedPowerStripsTimestamp = timestamp;
    }
  }


  // sends a request to the server for the current time
  getSystemDateTime() {
    return new Request({url: this.resources.systemDateTime + '?' + (new Date()).getTime(), onComplete: this.setModifiedRacksTimestamp, onTimeout: this.retrySystemDateTime}).get();
  }

  // sends a request to the server for the current time
  getSystemDateTimeForPowerStrip() {
    return new Request({url: this.resources.systemDateTime + '?' + (new Date()).getTime(), onComplete: this.setModifiedPowerStripsTimestamp, onTimeout: this.retrySystemDateTime}).get();
  }


  // requests a change set from the server, passing with the list of racks to report changes for and wether or not to 
  // suppress notifications of added racks
  getModifiedRackIds() {
    new Request.JSON({url: this.resources.path + this.resources.modifiedRackIds + '?' + (new Date()).getTime() + '&modified_timestamp=' + this.getModifiedRacksTimestamp() + this.rackIdsAsParams(this.visibleRackIds()) + '&suppress_additions=' + !this.model.displayingAllRacks(), onComplete: this.receivedModifiedRackIds, onTimeout: this.retryModifiedRackIds}).get();
    if (this.model.showingFullIrv()) {
      return new Request.JSON({url: this.resources.path + this.resources.modifiedNonRackIds + '?' + (new Date()).getTime() + '&modified_timestamp=' + this.getModifiedRacksTimestamp() + this.idsAsParams(this.visibleNonRackIds(),'non_rack_ids') + '&suppress_additions=' + !this.model.displayingAllRacks(), onComplete: this.receivedModifiedNonRackIds, onTimeout: this.retryModifiedNonRackIds}).get();
    }
  }

  // requests a change set from the server, passing with the list of PowerStrips to report changes for and wether or not to 
  // suppress notifications of added PowerStrips
  getModifiedPowerStripIds() {
    let extra_param;
    if (this.model.showingRacks()) {
      extra_param = 'rack_id=' + this.model.racks()[0].id;
    }
    return new Request.JSON({url: this.resources.path + this.resources.modifiedPowerStripIds + '?' + (new Date()).getTime() + '&modified_timestamp=' + this.getModifiedPowerStripsTimestamp() + this.idsAsParams(this.visiblePowerStripIds(),'power_strip_ids') + '&suppress_additions=' + !this.model.showingRacks() + '&'+extra_param, onComplete: this.receivedModifiedPowerStripIds, onTimeout: this.retryModifiedPowerStripIds}).get();
  }

  // requests metric definitions from the server
  getMetricTemplates() {
    return new Request.JSON({url: this.resources.path + this.resources.metricTemplates + '?' + (new Date()).getTime(), onComplete: this.receivedMetricTemplates, onTimeout: this.retryMetricTemplates}).get();
  }


  // requests thresholds definitions from the server
  getThresholds() {
    if ($('threshold_select') != null) {
      return new Request.JSON({url: this.resources.path + this.resources.thresholds + '?' + (new Date()).getTime(), onComplete: this.receivedThresholds, onTimeout: this.retryMetricTemplates}).get();
    } else {
      return ++this.resourceCount; // Otherwise the page will not proceed to load :/
    }
  }

  // called when threshold definitions are returned from the server, parses them and stores in the model. Load progress is also tested
  // here as this forms part of the initialisation data
  // @param  thresholds  object representing the threshold definitions
  receivedThresholds(thresholds) {
    const parsed = this.parser.parseThresholds(thresholds);
    this.model.thresholdsByMetric(parsed.byMetric);
    this.model.thresholdsById(parsed.byId);
    ++this.resourceCount;
    return this.testLoadProgress();
  }

  // Function to call the metric templates API.
  // The resourceCount needs to be decreased, since once the api call response is received,
  // then the resourceCount will be increased by 1, and only when the resources loaded are equal to the 
  // amount of total resources, is when rack space will be synchronised.
  metricTemplatesPoller() {
    --this.resourceCount;
    return this.getMetricTemplates();
  }


  // requests metric definitions from the server, this is triggered when interacting with the metric combo box to always provide
  // an up-to-date list of metrics
  refreshMetricTemplates() {
    return new Request.JSON({url: this.resources.path + this.resources.metricTemplates + '?' + (new Date()).getTime(), onComplete: this.refreshedMetricTemplates, onTimeout: this.retryMetricTemplates}).get();
  }


  // called should the metric definition response fail, re-submits the request. !! possibly untested, possibly redundant
  retryMetricTemplates() {
    Profiler.trace(Profiler.CRITICAL, 'Failed to load metric templates, retrying in ' + IRVController.API_RETRY_DELAY + 'ms');
    return setTimeout(this.getMetricTemplates, IRVController.API_RETRY_DELAY);
  }


  // called should the rack definition response fail, re-submits the request. !! possibly untested, possibly redundant
  retryRackDefs() {
    Profiler.trace(Profiler.CRITICAL, 'Failed to load rack definitions, retrying in ' + IRVController.API_RETRY_DELAY + 'ms');
    return setTimeout(this.getRackDefs, IRVController.API_RETRY_DELAY);
  }

  // called should the PowerStrip definition response fail, re-submits the request. !! possibly untested, possibly redundant
  retryPowerStripDefs() {
    Profiler.trace(Profiler.CRITICAL, 'Failed to load PowerStrip definitions, retrying in ' + IRVController.API_RETRY_DELAY + 'ms');
    return setTimeout(this.getPowerStripDefs, IRVController.API_RETRY_DELAY);
  }

  retryNonrackDeviceDefs() {
    Profiler.trace(Profiler.CRITICAL, 'Failed to load nonrack device definitions, retrying in ' + IRVController.API_RETRY_DELAY + 'ms');
    return setTimeout(this.getNonrackDeviceDefs, IRVController.API_RETRY_DELAY);
  }

  // called should the system time response fail, re-submits the request. !! possibly untested, possibly redundant
  retrySystemDateTime() {
    Profiler.trace(Profiler.CRITICAL, 'Failed to load system date time, retrying in ' + IRVController.API_RETRY_DELAY + 'ms');
    return setTimeout(this.getSystemDateTime, IRVController.API_RETRY_DELAY);
  }

  // triggered when all initialisation data and rack images have loaded. Sets up everything, instanciates class instances, starts
  // pollers and adds event listeners
  init() {
    // Hide loader
    Util.setStyle($('loader'), 'visibility', 'hidden');
    this.clickAssigned      = true;
    this.dragging           = false;
    this.hintTmr            = 0;
    this.clickTmr           = 0;
    this.ev                 = {};
    this.scrollAdjust       = Util.getScrollbarThickness();
    this.keysPressed        = {};
    this.autoSelectMetric   = true;
    this.currentFace        = this.model.face();
    this.currentMetricLevel = this.model.metricLevel();

    this.chartEl         = $('graph_container');
    this.rackEl          = $('rack_container');
    this.thumbEl         = $('thumb_nav');
    this.filterBarEl     = $('colour_map');
    this.metricPollInput = $('metric_poll_input');
    this.holdingAreaCheckBox = $('show_holding_area');

    if (this.metricPollInput != null) { this.metricPollInput.value = this.model.metricPollRate() / 1000; }

    this.topHint = new Hint(this.rackEl, this.model);

    // nav links
    if ($('reset_filters') != null) { Events.addEventListener($('reset_filters'), 'click', this.evResetFilters); }
    if ($('zoom_in_btn') != null) { Events.addEventListener($('zoom_in_btn'), 'click', this.evZoomIn); }
    if ($('zoom_out_btn') != null) { Events.addEventListener($('zoom_out_btn'), 'click', this.evZoomOut); }
    if ($('reset_zoom_btn') != null) { Events.addEventListener($('reset_zoom_btn'), 'click', this.evResetZoom); }
    if ($('hideSideContent') != null) { Events.addEventListener($('hideSideContent'), 'click', this.evHideNav); }
    if ($('metrics') != null) { Events.addEventListener($('metrics'), 'mouseup', this.evMouseUpMetricSelect); }
    if ($('metrics') != null) { Events.addEventListener($('metrics'), 'blur', this.evBlurSelect); }

    // title buttons
    if ($('dcpv_link') != null) { Events.addEventListener($('dcpv_link'), 'mousedown', this.exitToDCPV); }
    if ($('print_link') != null) { Events.addEventListener($('print_link'), 'click', this.printScreen); }
    if ($('save_link') != null) { Events.addEventListener($('save_link'), 'click', this.saveScreen); }
    if ($('export_link') != null) { Events.addEventListener($('export_link'), 'click', this.exportData); }

    if (this.filterBarEl != null) { Events.addEventListener(this.filterBarEl, 'filterBarSetAnchor', this.evDropFilterBar); }
    Events.addEventListener(this.rackEl, 'rackSpaceZoomComplete', this.evZoomComplete);
    Events.addEventListener(this.rackEl, 'rackSpaceFlipComplete', this.evFlipComplete);
    Events.addEventListener(this.rackEl, 'rackSpaceReset', this.evReset);
    Events.addEventListener(this.rackEl, 'rackSpaceClearDeselected', this.evClearDeselected);
    Events.addEventListener(this.rackEl, 'rackSpaceShowVMs', this.evShowVMs);
    Events.addEventListener(this.rackEl, 'rackSpaceCloseVMs', this.evHideVMs);
    Events.addEventListener(this.rackParent, 'scroll', this.evScrollRacks);
    Events.addEventListener(this.rackEl, 'redrawRackSpace', this.evRedrawRackSpace);
    Events.addEventListener(this.rackEl, 'getModifiedRackIds', this.getModifiedRackIds);
    Events.addEventListener(this.rackEl, 'reloadMetrics', this.evResetMetricPoller);
    Events.addEventListener(window, 'keydown', this.evKeyDown);
    Events.addEventListener(window, 'keyup', this.evKeyUp);
    Events.addEventListener(this.rackEl, 'mouseout', this.evMouseOutRacks);
    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'mouseout', this.evMouseOutThumb); }
    Events.addEventListener(document.window, 'resize', this.evResize);
    if (this.filterBarEl != null) { Events.addEventListener(this.filterBarEl, 'mousedown', this.evMouseDownFilter); }
    if (this.filterBarEl != null) { Events.addEventListener(this.filterBarEl, 'mouseup', this.evMouseUpFilter); }
    if (this.filterBarEl != null) { Events.addEventListener(this.filterBarEl, 'mouseout', this.evMouseOutFilter); }
    Events.addEventListener(window, 'getHintInfo', this.evGetHintInfo);
    if (this.metricPollInput != null) { Events.addEventListener(this.metricPollInput, 'keyup', this.evEditMetricPoll); }
    if (this.metricPollInput != null) { Events.addEventListener(this.metricPollInput, 'blur', this.evSetMetricPoll); }

    this.updateLayout();

    if (this.holdingAreaCheckBox != null) {
      if (this.model.showingRacks() || this.model.showingFullIrv()) {
        this.enableShowHoldingAreaCheckBox();
        this.model.racks.subscribe(this.enableShowHoldingAreaCheckBox);
      }
    }

    // set up subscriptions
    this.model.showChart.subscribe(this.updateLayout);
    this.model.showFilterBar.subscribe(this.updateLayout);
    this.model.selectedMetric.subscribe(this.updateLayout);
    this.model.face.subscribe(this.switchFace);
    this.model.showHoldingArea.subscribe(this.evShowHideScrollBars);

    if (this.model.showingRacks() && !this.model.showingFullIrv()) {
      this.showPowerStripsLink = $('power_strips_show');
      if (this.showPowerStripsLink != null) { Events.addEventListener(this.showPowerStripsLink, 'click', this.showOrHidePowerStripLayer); }
    }

    this.model.filters.subscribe(this.applyFilter);
    this.model.metricLevel.subscribe(this.switchMetricLevel);
    this.model.selectedMetricStat.subscribe(this.evSwitchStat);
    this.model.graphOrder.subscribe(this.evSwitchGraphOrder);
    this.model.selectedGroup.subscribe(this.evSwitchGroup);
    this.pollSub = this.model.metricPollRate.subscribe(this.setMetricPollInput);

    this.model.showingPowerStrips.subscribe(this.updateShowOrHidePowerStripsLink);

    // Rack Space
    this.rackSpace = new RackSpace(this.rackEl, this.chartEl, this.model, this.rackParent);
    if (this.model.showingFullIrv()) {
      this.pieCountdown = new PieCountdown(this.rackSpace.countDownGfx, this.model.metricPollRate()/1000);
    }

    // focus in on a specific device if data attribute has been defined. This attribute is embedded in the page if the user has navigated
    // here from the device show page
    let focus = (this.rackEl.parentNode != null ? this.rackEl.parentNode : this.rackEl.parentElement).get('data-focus');
    if (focus != null) {
      focus = focus.split(',');
      this.rackSpace.focusOn(focus[0], focus[1]);
      this.showHideScrollBars(1);
    }

    this.enableMouse();

    // thumb navigation
    if (this.thumbEl != null) { this.thumb = new ThumbNav(this.thumbEl, IRVController.THUMB_WIDTH, IRVController.THUMB_HEIGHT, this.model); }

    // colour map
    if (this.filterBarEl != null) { this.filterBar = new FilterBar(this.filterBarEl, this.rackParent, this.model); }
  

    const device_lookup = this.model.deviceLookup();

    this.setAPIFilter();

    // request initial metric data
    if (this.model.showingFullIrv()) {
      this.modifiedMetricTemplates = setInterval(this.metricTemplatesPoller, IRVController.METRIC_TEMPLATES_POLL_RATE);
      if (this.model.metricPollRate() !== 0) {
        this.loadMetrics;
      }

      this.connectMetricCombos();
    }

    this.tooltip = new Tooltip();

    // since the metrics and breaches poll at the same rate (default), put
    // the requests out of phase with each other
    if (this.model.showingFullIrv()) {
      this.loadBreaches();

      setTimeout(() => {
        return this.breachTmr = setInterval(this.loadBreaches, IRVController.BREACH_POLL_RATE);
      }
      , IRVController.BREACH_POLL_RATE / 2);
    }

    if ((this.options != null) && (this.options.applyfilter === "true")) { this.applyCrossAppSettings(); }

    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      this.modifiedRackDefinitionTmr = setInterval(this.getModifiedRackIds, IRVController.MODIFIED_RACK_POLL_RATE);
    }

    if (this.model.showingPowerStrips() || (this.model.showingRacks() && !this.model.showingFullIrv())) {
      this.modifiedPowerStripDefinitionTmr = setInterval(this.getModifiedPowerStripIds, IRVController.MODIFIED_POWER_STRIPS_POLL_RATE);
    }

    if (this.model.showingPowerStrips() && !this.model.showingRacks()) {
      Util.setStyle(this.rackParent, 'height', this.rackSpace.rackGfx.cvs.height  + 'px');
      Util.setStyle(this.rackParent, 'width', this.rackSpace.rackGfx.cvs.width  + 'px');
    }
  
    this._callback_store = {};
  
    this.initialised = true;
    //console.log "DCRV INITIALISED!!!"
    if (this.waitingForInitialisation === true) {
      this.displayTheMetrics(this.metricValues);
      this.waitingForInitialisation = false;
    }
    setTimeout(this.scrollPanelUp, 1000);
    return this.showFinishedTime();
  }


  // requests a list of breaching device ids from the server
  loadBreaches() {
    return new Request.JSON({url: this.resources.path + this.resources.breaches + '?' + (new Date()).getTime(), onSuccess: this.evReceivedBreaches}).get();
  }

  scrollPanelUp() {
    const container = $("sidemenu");
    const scrollTo = $("rack_actions");
    if (!scrollTo || !container) { return; }
    return container.scrollTop = scrollTo.offsetTop + container.scrollTop;
  }

  // called when the server returns the list of breaching device ids. Stores breaches in the model
  // @param  breaches  breaching device ids returned from server
  evReceivedBreaches(breaches) {
    let group;
    const device_lookup    = this.model.deviceLookup();
    const groups           = this.model.groups();
    const breaching        = {};
    for (group of Array.from(groups)) { breaching[group] = {}; }

    for (group in breaches) {
      if (breaching[group] == null) { continue; }
      for (var id of Array.from(breaches[group])) { breaching[group][id] = true; }
    }

    return this.model.breaches(breaching);
  }

  // actions settings carried over from other apps, e.g. DCPV
  applyCrossAppSettings() {
    const selected_metric = this.crossAppSettings.selectedMetric;

    // assume if selected metric is set that we have a valid set of settings
    if (selected_metric != null) {
      this.model.selectedMetric(selected_metric);
      this.model.filters()[selected_metric] = this.crossAppSettings.filters[selected_metric];
      this.model.colourMaps()[selected_metric] = this.crossAppSettings.colourMaps[selected_metric];
      this.model.filters(this.model.filters());
      return this.model.colourMaps(this.model.colourMaps());
    }
  }

    // settings are one time use only, clear settings data
    //CrossAppSettings.clear('irv')


  // resolve a list of included chassis and devices. This will be
  // used to filter metrics when sending the request
  setAPIFilter() {
    let id;
    const device_lookup = this.model.deviceLookup();
    this.apiFilter = { device_ids: [], tagged_devices_ids: []};
    const groups = ['chassis', 'devices'];

    for (id in device_lookup.chassis) {
      var oneChassis = device_lookup.chassis[id];
      if (!this.model.showHoldingArea() && (oneChassis.instances[0] != null ? oneChassis.instances[0].placedInHoldingArea() : undefined)) { continue; }
      if (oneChassis.template.simple === false) {
        this.apiFilter.tagged_devices_ids.push(oneChassis.tagged_device_id);
      }
    }

    for (id in device_lookup.devices) {
      var oneDevice = device_lookup.devices[id];
      if (!this.model.showHoldingArea() && (oneDevice.instances[0] != null ? oneDevice.instances[0].placedInHoldingArea() : undefined)) { continue; }
      this.apiFilter.device_ids.push(id);
    }

    for (var oneC of Array.from(this.model.dcrvShowableNonRackChassis())) {
      if (oneC.simple !== true) {
        this.apiFilter.tagged_devices_ids.push(oneC.tagged_device_id);
      }
      for (var oneS of Array.from(oneC.Slots)) {
        if (oneS.Machine != null) { this.apiFilter.device_ids.push(oneS.Machine.id); }
      }
    }

    this.apiFilter.tagged_devices_ids = JSON.stringify(this.apiFilter.tagged_devices_ids);
    return this.apiFilter.device_ids  = JSON.stringify(this.apiFilter.device_ids);
  }


  // event handler triggered by context menu click
  // @param  ev  the click event object
  evClearDeselected(ev) {
    return this.discardExcludedRacks();
  }


  // removes and destroys any deselected racks, these are the racks excluded by any currently active filter and/or selection
  discardExcludedRacks() {
    let instance;
    const active_selection = this.model.activeSelection();
    const active_filter    = this.model.activeFilter();

    // cancel action if no selection or filter currently applied
    if (!active_selection && !active_filter) { return; }

    const device_lookup    = this.model.deviceLookup();
    const filtered_devices = this.model.filteredDevices();
    const selected_devices = this.model.selectedDevices();

    var trash_lookup = rack_object => {
      for (var child of Array.from(rack_object.children)) { trash_lookup(child); }
      return delete device_lookup[rack_object.group][rack_object.id];
    };

    let modified = false;

    for (var id in device_lookup.racks) {
      var rack_def = device_lookup.racks[id];
      if (!rack_def.instances[0].included) {
        modified = true;
        for (instance of Array.from(rack_def.instances)) { trash_lookup(instance); }
      }
    }

    for (var chassis_def of Array.from(this.model.dcrvShowableNonRackChassis())) {
      if (!(chassis_def.instances[0] != null ? chassis_def.instances[0].included : undefined)) {
        modified = true;
        for (instance of Array.from(chassis_def.instances)) { trash_lookup(instance); }
      }
    }

    if (modified) {
      this.model.displayingAllRacks(false);
      this.model.deviceLookup(device_lookup);
      this.setAPIFilter();
      this.resetMetricPoller();
      return this.rackSpace.refreshRacks();
    }
  }


  // shows updating message and prevents user interation, this is used during zoom and flip animations as well as any processes
  // which could cause the UI to freeze for a noticable period of time
  showUpdateMsg() {
    return this.updateMsg.show();
  }


  // hides the updating message and re-enables user interaction
  hideUpdateMsg() {
    return this.updateMsg.hide();
  }


  // zoom in or out a small amount
  // @param  direction should be 1 or -1, indicating wether to zoom in or out
  // @param  x         optional, the x coordiate about which to centre the zoom operation. Defaults to rack view centre
  // @param  y         optional, the y coordiate about which to centre the zoom operation. Defaults to rack view centre
  stepZoom(direction, x, y) {
    if (this.model.showingFullIrv()) { this.showUpdateMsg(); }

    if (x == null) { x = this.rackEl.scrollLeft + (this.rackElDims.width / 2); }
    if (y == null) { y = this.rackEl.scrollTop + (this.rackElDims.height / 2); }

    this.zooming = true;
    clearTimeout(this.hintTmr);
    this.disableMouse();
    return this.rackSpace.quickZoom(x, y, this.rackSpace.scale + (this.rackSpace.scale * IRVController.STEP_ZOOM_AMOUNT * direction));
  }


  // zooms the rack view to a preset zoom level. At the time of writing the preset zoom values are defined as 'fit all',
  // 'fit to row height' and 'maximum'
  // @param  direction should be either 1 or -1 to indicating traversal forward or backwards through zoom preset array
  // @param  x         optional, the x coordiate about which to centre the zoom operation. Defaults to rack view centre
  // @param  y         optional, the y coordiate about which to centre the zoom operation. Defaults to rack view centre
  // @param  cyclical  optional defaults to true, indicates wether to cycle through zoom preset array traversal
  zoomToPreset(direction, x, y, cyclical) {
    if (cyclical == null) { cyclical = true; }
    if (this.model.showingFullIrv()) { this.showUpdateMsg(); }

    if (x == null) { x = this.rackEl.scrollLeft + (this.rackElDims.width / 2); }
    if (y == null) { y = this.rackEl.scrollTop + (this.rackElDims.height / 2); }

    this.zooming = true;
    clearTimeout(this.hintTmr);
    this.disableMouse();
    this.rackSpace.zoomToPreset(direction, x, y, cyclical);
    return this.showHideScrollBars(this.rackSpace.zoomIdx);
  }

  zoomHoldingArea(direction, x, y) {
    if (this.model.showingFullIrv()) { this.showUpdateMsg(); }

    this.zooming = true;
    clearTimeout(this.hintTmr);
    this.disableMouse();
    return this.rackSpace.holdingArea.zoomToPreset(direction, x, y);
  }

  // reset context menu click event handler. Resets the zoom level to 'fit all' and removes any active filter and selection
  // @param  ev  the click event object
  evReset(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    this.resetFilters();
    return this.resetZoom();
  }


  // reset zoom click event handler. Resets teh current zoom level to 'fit all'
  // @param  ev  the click event object
  evResetZoom(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.resetZoom();
  }


  // displays updating message and triggers zoom reset animation
  resetZoom() {
    this.updateMsg.show();
    return this.rackSpace.resetZoom();
  }


  // reset filters click handler, removes any active selection and filter
  // @param  ev  click event object
  evResetFilters(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.resetFilters();
  }

  // removes any active filter and/or selection
  resetFilters() {
    this.model.resetFiltersAndSelectedGroup();

    this.model.activeSelection(false);
    this.model.selectedDevices(this.model.getBlankGroupObject());
    this.rackSpace.clearAllRacksAsFocused();
    this.rackSpace.setMetricLevel(this.currentMetricLevel);
    return this.filterBar.resetFilters();
  }

  // zoom in button click event handler, zooms to next zoom preset
  // @param  ev  event objet which invoked execution
  evZoomIn(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.zoomToPreset(1, null, null, false);
  }


  // zoom out button click event handler, zooms to previous zoom preset
  // @param  ev  event objet which invoked execution
  evZoomOut(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.zoomToPreset(-1, null, null, false);
  }


  // grabs image data from both the rack view and LBC and posts it out to the server using a hidden form
  saveScreen() {
    let chart_b64, chart_cvs;
    alert_dialog(IRVController.EXPORT_MESSAGE);
    const ts       = new Date();
    let filename = IRVController.SCREENSHOT_FILENAME;
    filename = Util.substitutePhrase(filename, 'day', Util.addLeadingZeros(ts.getUTCDate()));
    filename = Util.substitutePhrase(filename, 'month', Util.addLeadingZeros(ts.getUTCMonth() + 1));
    filename = Util.substitutePhrase(filename, 'year', Util.addLeadingZeros(ts.getUTCFullYear()));
    filename = Util.substitutePhrase(filename, 'hours', Util.addLeadingZeros(ts.getUTCHours()));
    filename = Util.substitutePhrase(filename, 'minutes', Util.addLeadingZeros(ts.getUTCMinutes()));
    filename = Util.substitutePhrase(filename, 'seconds', Util.addLeadingZeros(ts.getUTCSeconds()));
    filename = Util.cleanUpSubstitutions(filename);
    //console.log filename
    const rack_b64    = this.grabScreen();

    const addFrmVal = function(name, value) {
      const val       = document.createElement('input');
      val.name  = name;
      val.type  = 'hidden';
      val.value = value;
      return frm.appendChild(val);
    };

    if (this.model.showChart()) {
      chart_cvs  = this.rackSpace.chart.cvs;
      chart_b64  = chart_cvs.toDataURL();
    }

    var frm         = document.createElement('form');
    frm.name    = 'imagePost-a-tron';
    frm.method  = 'post';
    frm.enctype = 'multipart/form-data';

    addFrmVal('filename', filename);
    addFrmVal('type[]', 'text');
    addFrmVal('data[]', rack_b64.split(',')[1]);
    addFrmVal('size[]', String(this.rackSpace.coordReferenceEl.width) + 'x' + String(this.rackSpace.coordReferenceEl.height));

    if (this.model.showChart()) {
      addFrmVal('type[]', 'text'); 
      addFrmVal('data[]', chart_b64.split(',')[1]);
      addFrmVal('size[]', String(Math.ceil(chart_cvs.width)) + 'x' + String(Math.ceil(chart_cvs.height)));
    }

    addFrmVal('authenticity_token', $$('meta[name="csrf-token"]')[0].getAttribute('content'));

    document.body.appendChild(frm);
    frm.action = IRVController.EXPORT_IMAGE_URL;
    return frm.submit();
  }


  // exit to plan view event handler. Stores relevant display settings if any so they may be picked up by the plan view
  // @param  ev  the event object which invoked execution
  exitToDCPV(ev) {
    return this.saveSettings('dcpv');
  }

  saveSettings(going_to) {
    const settings = {};

    // carry over either the current static group or the selected devices (if any)
    if (this.model.selectedGroup() != null) {
      settings.selectedGroup = this.model.selectedGroup();
    } else if (this.model.activeSelection() || this.crossAppSettings.selectedRacks) {
      const device_lookup    = this.model.deviceLookup();
      const selected_devices = { racks: {} };
      let valid            = false;

      for (var id in device_lookup.racks) {
        if (device_lookup.racks[id].instances[0].included) {
          valid = true;
          selected_devices.racks[id] = true;
        }
      }

      if (valid) { settings.selectedDevices = selected_devices; }
      settings.selectedRacks = selected_devices.racks;
    }

    const selected_metric = this.model.selectedMetric();

    if (selected_metric != null) {
      settings.selectedMetric              = this.model.selectedMetric();
      settings.colourMaps                  = {};
      settings.colourMaps[selected_metric] = this.model.colourMaps()[selected_metric];
      settings.filters                     = {};
      settings.filters[selected_metric]    = this.model.filters()[selected_metric];
    }

    if ((going_to === 'dcpv') && this.model.showingRacks() && !this.model.showingFullIrv()) {
      settings.focusOn = "racks,"+this.options.rackIds;
    }

    return CrossAppSettings.set(going_to, settings);
  }
    

  // generates simplified page in HTML suitable for printing and triggers print action
  printScreen() {
    let layer_chart, old_width;
    const layer_racks = this.rackSpace.rackGfx.cvs;
    const layer_power = this.rackSpace.powerStripsGfx.cvs;
    const layer_alert = this.rackSpace.alertGfx.cvs;
    const layer_info  = this.rackSpace.infoGfx.cvs;
  
    // storing the original values
    const left_values = [layer_racks.style.left,layer_power.style.left,layer_alert.style.left,layer_info.style.left];
    const width_values = [layer_racks.style.width,layer_power.style.width,layer_alert.style.width,layer_info.style.width];

    // setting left to 0 to avoid white space in the print
    layer_racks.style.left = '0px';
    layer_power.style.left = '0px';
    layer_alert.style.left = '0px';
    layer_info.style.left = '0px';

    const print_width = this.model.showingFullIrv() ? '800px' : '700px';

    layer_racks.style.width = print_width;
    layer_power.style.width = print_width;
    layer_alert.style.width = print_width;
    layer_info.style.width  = print_width;

    let html = '<div style="height: 650px;">' + layer_racks.outerHTML;
  
    if (this.model.showingPowerStrips()) { html += layer_power.outerHTML; }
  
    html += layer_alert.outerHTML + layer_info.outerHTML + '</div>';
    if (this.model.showChart()) {
      layer_chart = this.rackSpace.chart.cvs;
      old_width = layer_chart.width;
      layer_chart.style.width = print_width;
      html += '<div></div><div>' + layer_chart.outerHTML + '</div>';
    }
    Util.printHtmlInNewPage( html );

    // returning the original values
    layer_racks.style.left = left_values[0];
    layer_power.style.left = left_values[1];
    layer_alert.style.left = left_values[2];
    layer_info.style.left = left_values[3];

    layer_racks.style.width = width_values[0];
    layer_power.style.width = width_values[1];
    layer_alert.style.width = width_values[2];
    layer_info.style.width = width_values[3];

    if (this.model.showChart()) {
      return layer_chart.style.width = old_width+'px';
    }
  }

  // export data event handler, generates a csv of the current metric data and generates a file which is downloaded
  // @param  ev  event object which invoked execution
  exportData(ev) {
    ev.stopPropagation();
    ev.preventDefault();

    const selected_metric = this.model.selectedMetric();
    if (selected_metric == null) { return; }

    const data          = this.model.metricData();
    const metric        = this.model.metricTemplates()[selected_metric];
    const groups        = this.model.groups();
    const device_lookup = this.model.deviceLookup();

    let output = IRVController.EXPORT_HEADER;
    output = Util.substitutePhrase(output, 'metric_name', metric.name);
    output = Util.substitutePhrase(output, 'metric_units', metric.units);
    output = Util.substitutePhrase(output, 'metric_name', metric.units);

    for (var group of Array.from(groups)) {
      var group_lookup = device_lookup[group];
      var values       = data.values[group];

      for (var id in values) {
        var device = group_lookup[id];

        if (device != null) {
          var record = IRVController.EXPORT_RECORD;
          record = Util.substitutePhrase(record, 'device_name', device.name);
          record = Util.substitutePhrase(record, 'device_id', device.id);
          record = Util.substitutePhrase(record, 'value', values[id]);

          output += record + String.fromCharCode(10);
        }
      }
    }

    const ts       = new Date();
    let filename = IRVController.EXPORT_FILENAME;
    filename = Util.substitutePhrase(filename, 'metric_name', metric.name);
    filename = Util.substitutePhrase(filename, 'day', Util.addLeadingZeros(ts.getUTCDate()));
    filename = Util.substitutePhrase(filename, 'month', Util.addLeadingZeros(ts.getUTCMonth() + 1));
    filename = Util.substitutePhrase(filename, 'year', Util.addLeadingZeros(ts.getUTCFullYear()));
    filename = Util.substitutePhrase(filename, 'hours', Util.addLeadingZeros(ts.getUTCHours()));
    filename = Util.substitutePhrase(filename, 'minutes', Util.addLeadingZeros(ts.getUTCMinutes()));
    filename = Util.substitutePhrase(filename, 'seconds', Util.addLeadingZeros(ts.getUTCSeconds()));
    filename = Util.cleanUpSubstitutions(filename);

    return this.saveFile(filename, output);
  }


  // creates a file using the given data and has the browser download the file with the given filename. Cross browser support of the
  // filename is limit
  // @param  filename  string, the filename to assign to the file
  // @param  data      object, the data to be written to the file
  saveFile(filename, data) {
    if (Browser.ie) {
      const win = window.open();
      win.document.write(data);
      win.document.close();
      return win.document.execCommand('SaveAs', null, filename);
    } else {
      const data_url    = window.URL.createObjectURL(new Blob([data], { type: 'text/octet-stream'}));
      const dl          = document.createElement('a');
      dl.href     = data_url;
      dl.download = filename;

      document.body.appendChild(dl);
      dl.click();
      return document.body.removeChild(dl);
    }
  }


  // flattens all canvas layers which make up the rack view into a single canvas image and exports the image as base 64 encoded data
  grabScreen() {
    const {
      width
    } = this.rackSpace.rackGfx.cvs;
    const {
      height
    } = this.rackSpace.rackGfx.cvs;

    const cvs           = document.createElement('canvas');
    cvs.width     = width;
    cvs.height    = height;
    const ctx           = cvs.getContext('2d');
    ctx.fillStyle = '#ffffff';

    ctx.fillRect(0, 0, width, height);
  
    ctx.drawImage(this.rackSpace.rackGfx.cvs, 0, 0);
    ctx.drawImage(this.rackSpace.infoGfx.cvs, 0, 0);
    ctx.drawImage(this.rackSpace.alertGfx.cvs, 0, 0);
    if (this.model.showingPowerStrips()) {
      ctx.drawImage(this.rackSpace.powerStripsGfx.cvs, 0, 0);
    }

    return cvs.toDataURL();
  }


  // metric selection combo box focus event handler. Requests an up to date list of metric definitions from the server
  // @param  ev  the event object which invoked execution
  evFocusMetricSelect(ev) {
    if (this.refreshingMetrics) { return; }
    return this.refreshMetricTemplates();
  }


  // metric selection combo box mouse up event handler. This selects all the text in the combo box input field, but only when the
  // field has just received focus. This means the user can still highlight text with the mouse after focus has been acquired and
  // this routine will not override their selection.
  // @param  ev  the event object which invoked execution
  evMouseUpMetricSelect(ev) {
    if (!this.autoSelectMetric) { return; }
    this.autoSelectMetric = false;
    return ev.target.select();
  }

  // metric selection combo box blur event handler. Resets auto select flag
  // @param  ev  the event object which invoked execution
  evBlurSelect(ev) {
    return this.autoSelectMetric = true;
  }


  // hide LH menu bar event handler, triggers the page layout to be updated on a timer, this allows the LH menu hide animation to complete
  // before updating the layout
  // @param  ev  the event object which invoked execution
  evHideNav(ev) {
    return setTimeout(this.updateLayout, IRVController.NAV_HIDE_LAYOUT_UPDATE_DELAY);
  }


  // browser resize event handler, updates the page layout
  // @param  ev  event object which invoked execution
  evResize(ev) {
    return this.updateLayout();
  }


  // updates page layout 
  updateLayout() {
    let rack_height_proportion;
    let filter_height_proportion = 0;
    let graph_height_proportion = 0;
    if ((this.noMetricSelected(this.model.selectedMetric()) === false) && ( this.model.showChart() || this.model.showFilterBar() )) {
      rack_height_proportion   = IRVController.RACK_PAGE_HEIGHT_PROPORTION;
      if (this.model.showFilterBar()) {
        filter_height_proportion = 0.05;
      } else {
        rack_height_proportion += 0.05;
      }
      if (this.model.showChart()) {
        graph_height_proportion  = 1 - rack_height_proportion - filter_height_proportion;
      } else {
        rack_height_proportion = 1 - filter_height_proportion;
      }
    } else {
      rack_height_proportion = 0.96;
    }

    //Setting the height of the canvas area, based on the actual height of the window.
    const dims_page_content = $(IRVController.MAIN_PAGE_CONTENT_ID).getCoordinates();
    const interactive_canvas_view = $(IRVController.CANVAS_CONTENT_ID);
    const interactive_coords = interactive_canvas_view.getCoordinates();
    Util.setStyle(interactive_canvas_view, 'height', ((dims_page_content.height + dims_page_content.top) - interactive_coords.top - IRVController.BOTTOM_PADDING) + 'px');

    Util.setStyle(this.rackParent, 'height', (rack_height_proportion * 99) + '%');
    if (this.model.showChart()) {
      Util.setStyle(this.chartEl, 'top', ((rack_height_proportion + filter_height_proportion) * 100) + '%');
      Util.setStyle(this.chartEl, 'height', (graph_height_proportion * 100) + '%');
    }

    const dims     = this.rackParent.getCoordinates();
    if (this.filterBarEl != null) { const fb_dims  = this.filterBarEl.getCoordinates(); }
    const fb_align = (this.filterBar != null) ? this.filterBar.alignment : FilterBar.DEFAULT_ALIGN;

    Util.setStyle(this.rackEl, 'position', 'absolute');

    switch (fb_align) {
      case FilterBar.ALIGN_TOP:
        Util.setStyle(this.rackEl, 'top', FilterBar.THICKNESS);
        Util.setStyle(this.rackEl, 'left', 0);
        Util.setStyle(this.rackEl, 'width', '100%');
        Util.setStyle(this.rackEl, 'height', (dims.height) + 'px');
        break;
      case FilterBar.ALIGN_BOTTOM:
        Util.setStyle(this.rackEl, 'top', 0);
        Util.setStyle(this.rackEl, 'left', 0);
        Util.setStyle(this.rackEl, 'width', '100%');
        Util.setStyle(this.rackEl, 'height', (dims.height) + 'px');
        break;
      case FilterBar.ALIGN_LEFT:
        Util.setStyle(this.rackEl, 'top', 0);
        Util.setStyle(this.rackEl, 'left', FilterBar.THICKNESS);
        Util.setStyle(this.rackEl, 'width', (dims.width - FilterBar.THICKNESS) + 'px');
        Util.setStyle(this.rackEl, 'height', '100%');
        break;
      case FilterBar.ALIGN_RIGHT:
        Util.setStyle(this.rackEl, 'top', 0);
        Util.setStyle(this.rackEl, 'left', 0);
        Util.setStyle(this.rackEl, 'width', (dims.width - FilterBar.THICKNESS) + 'px');
        Util.setStyle(this.rackEl, 'height', '100%');
        break;
    }

    this.rackElDims  = this.rackEl.getCoordinates();
    this.chartElDims = this.chartEl != null ? this.chartEl.getCoordinates() : undefined;

    if (this.rackSpace != null) {
      if (this.filterBar) { this.filterBar.updateLayout(); }
      return this.rackSpace.updateLayout();
    }
  }


  // clears any runnnig pollers and restarts them
  resetMetricPoller() {
    // During the loading of a preset in the DCRV, there are more than 1 observable that could trigger this function.
    // So, if a preset is being set/loaded at the moment, exit this function, because when the preset finish loading,
    // the observable loadingAPreset will call this function again.
    if (this.model.loadingAPreset() === true) { return; }
    clearInterval(this.metricTmr);
    clearInterval(this.vmMetricTmr);
    if ((this.model.metricPollRate() !== 0) && !this.noMetricSelected(this.model.selectedMetric())) {
      this.loadMetrics();
      this.metricTmr   = setInterval(this.loadMetrics, this.model.metricPollRate());
      if (this.showingVMs) {
        this.loadVMMetrics();
        return this.vmMetricTmr = setInterval(this.loadVMMetrics, this.model.metricPollRate(), this.vHostId);
      }
    }
  }

  noMetricSelected(one_metric){
    return (one_metric === null) || (one_metric === '') || (one_metric === ViewModel.METRIC_NO_VALUE) || (one_metric === PresetManager.METRIC_NOT_VALID);
  }

  showHideExportDataOption(metric) {
    return $('export_link').className = this.noMetricSelected(metric) ? "hide" : "";
  }

  // selectedMetric model property subscriber. Resets selected preset drop-down, clears existing metric data, resets filter and restarts
  // metric poller(s)
  // @param  metric  string, new metric id
  switchMetric(metric) {
    let group;
    if (!this.model.validMetric(metric)) { return; }

    // clear the preset selection if the metric we're switching to is not
    // the one stored against the current preset
    const selected_preset = this.model.selectedPreset();
    if (selected_preset != null) {
      const presets = this.model.presetsById();
      for (var id in presets) {
        if (presets[id].name === selected_preset) {
          var associated_metric = presets[id].values.selectedMetric;
          associated_metric = associated_metric.substr(1, associated_metric.length - 2);
          break;
        }
      }
    }

    this.resetMetricPoller();
  
    // clear metric data
    const groups = this.model.groups();
    let blank  = { values: {} };
    for (group of Array.from(groups)) { blank.values[group] = {}; }
    this.model.metricData(blank);

    if (this.noMetricSelected(metric)) {
      this.resetFilters();
      this.pieCountdown.hide();
    }

    // reset filter
    if (this.model.activeFilter() && ((typeof filter === 'undefined' || filter === null) || ((filter.max === colour_map.high) && (filter.min === colour_map.low)))) {
      blank        = {};
      for (group of Array.from(groups)) { blank[group] = {}; }
      this.model.activeFilter(false);
      return this.model.filteredDevices(blank);
    }
  }


  // metricLevel model property subscriber. Resets poller; switching between polling the metrics and the vm group metrics or fetching all
  // as necessary
  switchMetricLevel(metric_level) {
    const switch_to_vms   = (this.currentMetricLevel !== ViewModel.METRIC_LEVEL_VHOSTS) && (metric_level === ViewModel.METRIC_LEVEL_VHOSTS);
    const switch_from_vms = (this.currentMetricLevel === ViewModel.METRIC_LEVEL_VHOSTS) && (metric_level !== ViewModel.METRIC_LEVEL_VHOSTS);
    const switch_to_all   = (this.currentMetricLevel !== ViewModel.METRIC_LEVEL_ALL) && (metric_level === ViewModel.METRIC_LEVEL_ALL);
    const switch_from_all = (this.currentMetricLevel === ViewModel.METRIC_LEVEL_ALL) && (metric_level !== ViewModel.METRIC_LEVEL_ALL);

    // when switching to or from VMs clear metric data, change sort order options and reset metric poller
    if (switch_to_vms || switch_from_vms || switch_to_all || switch_from_all) {
      const groups      = this.model.groups();
      const vals        = {};
      for (var group of Array.from(groups)) { vals[group] = {}; }
      this.model.metricData({ values: vals });
      this.model.graphOrders(switch_to_vms ? ViewModel.VHOST_CHART_ORDERS : ViewModel.NORMAL_CHART_ORDERS);
      this.resetMetricPoller();
    }

    this.currentMetricLevel = metric_level;
    this.model.activeSelection(false);
    this.model.selectedDevices(this.model.getBlankGroupObject());
    return this.rackSpace.setMetricLevel(this.model.metricLevel());
  }


  // invoked when the server returns the metric definitions, parses and stores them in the model
  // @param  metric_templates  the metric definitions as returned by the server
  receivedMetricTemplates(metric_templates) {
    this.metrics = $('metrics');
    const templates = this.parser.parseMetricTemplates(metric_templates);
    this.model.metricTemplates(templates);

    let metrics_available = false;
    for (var i in templates) {
      metrics_available = true;
      break;
    }

    //@metrics.value = 'Select a metric' if metrics_available and @metrics? and @noMetricSelected(@metrics.value)
    ++this.resourceCount;
    return this.testLoadProgress();
  }

  // invoked when the server returns the metric definition after initialisation. Parses them and updates the model but only if changes
  // have occurred
  // @param  metric_templates  the metric definitions as returned by the server
  refreshedMetricTemplates(metric_templates) {
    let id;
    const templates = this.parser.parseMetricTemplates(metric_templates);

    // look for changes
    const old     = this.model.metricTemplates();
    let changed = false;
    // check for additions
    for (id in templates) {
      if (old[id] == null) {
        changed = true;
        break;
      }
    }

    // check for deletions (only if we haven't already found changes)
    if (!changed) {
      for (id in old) {
        if (templates[id] == null) {
          changed = true;
          break;
        }
      }
    }

    // update model only if there are changes
    if (changed) { return this.model.metricTemplates(templates); }
  }


  // called on receiving change set from the server. Triggers request for updated rack definitions necessary to synchronise the changes
  // @param  rack_data array of rack definition objects
  receivedModifiedRackIds(rack_data) {
    if (!this.dragging) {
      this.setModifiedRacksTimestamp(String(rack_data.timestamp));
      const rack_ids = rack_data.added.concat(rack_data.modified);
      this.changeSetRacks = rack_data;
      if (rack_ids.length > 0) {
        --this.resourceCount;
        return this.getRackDefs(this.rackIdsAsParams(rack_ids)); // we have new and modified racks present, and possibly deleted, the else handles
                               // the situation where we only have deleted racks
      } else if (rack_data.deleted.length > 0) {
        this.model.modifiedRackDefs([]); // we have only deleted racks in this request so empy the rack defs array
        return this.synchroniseChanges();
      }
    }
  }

  receivedModifiedNonRackIds(non_rack_data) {
    if (!this.dragging) {
      this.setModifiedRacksTimestamp(String(non_rack_data.timestamp));
      const non_rack_ids = non_rack_data.added.concat(non_rack_data.modified);
      this.changeSetNonRacks = non_rack_data;
      if (non_rack_ids.length > 0) {
        --this.resourceCount;
        return this.getNonrackDeviceDefs([], non_rack_ids);
      } else if (non_rack_data.deleted.length > 0) {
        this.model.modifiedDcrvShowableNonRackChassis([]); // we have only deleted racks in this request so empy the rack defs array
        return this.synchroniseChanges();
      }
    }
  }

  // called on receiving change set from the server. Triggers request for updated PowerStrip definitions necessary to synchronise the changes
  // @param  power_strip_data array of PowerStrip definition objects
  receivedModifiedPowerStripIds(power_strip_data) {
    if (!this.dragging) {
      this.setModifiedPowerStripsTimestamp(String(power_strip_data.timestamp));
      const power_strip_ids = power_strip_data.added.concat(power_strip_data.modified);

      this.model.powerStripsVisible = this.model.powerStripsVisible.concat(power_strip_ids.map(oneId => parseInt(oneId,10)));
      this.changeSetPowerStrip = power_strip_data;
      if (power_strip_ids.length > 0) {
        return this.getPowerStripDefs(power_strip_ids); // we have new and modified PowerStrip present, and possibly deleted, the else handles
                                            // the situation where we only have deleted PowerStrips
      } else if (power_strip_data.deleted.length > 0) {
        this.model.modifiedPowerStripDefs([]); // we have only deleted power stirps in this request so empy the PowerStrip defs array
        return this.synchroniseChanges();
      }
    }
  }



  // triggered when the server responds with rack definitions. This can be during the initialise process or as a result of changes to
  // the data centre. Actions the data accordingly
  // @param  rack_defs the rack definitions as returned by the server
  receivedRackDefs(rack_defs) {
    console.log("receivedRackDefs:");

    const defs = this.parser.parseRackDefs(rack_defs);

    if ((this.model.showingRacks() || this.model.showingFullIrv()) && (defs.racks != null) && (defs.racks.length > 0) && (this.model.racks() != null) && (this.model.racks().length > 0) && (this.model.racks()[this.model.racks().length-1].id === defs.racks[defs.racks.length-1].id)) {
      defs.racks[defs.racks.length-1].nextRackId = null;
    }

    if (this.initialised) {
      ++this.resourceCount;
      //XXX We only want to load in the new assets, the whole loading assets/redrawing is rather inefficient
      // so just replicate it here until someone has the time and energy to rewrite it
      //
      //XXX is this need any more as its now in the synchroniseChanges function
      //
      // for asset in defs.assetList # deal with loading the images
      // AssetManager.get(IRVController.PRIMARY_IMAGE_PATH + asset, @evAssetLoaded, @evAssetFailed)
      this.model.assetList(defs.assetList);
      this.model.modifiedRackDefs(defs.racks);
      if (this.model.assetList().length === 0) {
        // No assets to load, we must have deleted all devices from the rack, thus we need a redraw, but
        // there is no need to go through the asset loading routine
        return this.testLoadProgress();
      } else {
        return this.synchroniseChanges();
      }
    } else {
      return this.initialiseRackDefs(defs);
    }
  }

  recievedPowerStripDefs(power_strip_defs) {

    console.log("recievedPowerStripDefs:");
    const defs = this.parser.parsePowerStripDefs(power_strip_defs);

    if (this.initialised) {
      this.model.assetList(defs.assetList);
      this.model.modifiedPowerStripDefs(defs.powerStrips);
      if (this.model.assetList().length === 0) {
        return this.testLoadProgress();
      } else {
        return this.synchroniseChanges();
      }
    } else {
      return this.initialisePowerStripDefs(defs);
    }
  }

  recievedNonrackDeviceDefs(nonrack_device_defs) {
    console.log("recievedNonrackDeviceDefs:");
    if (this.initialised) {
      ++this.resourceCount;
      this.model.assetList(nonrack_device_defs.assetList);
      this.model.modifiedDcrvShowableNonRackChassis(nonrack_device_defs.dcrvShowableNonRackChassis);
      if (this.model.assetList().length === 0) {
        return this.testLoadProgress();
      } else {
        return this.synchroniseChanges();
      }
    } else {
      return this.initialiseNonRackDeviceDefs(nonrack_device_defs);
    }
  }

  createPresetManager() {
    this.updateMsg = new UpdateMsg(this.rackParent, [$('side_bar')]);
    this.model.selectedMetric.subscribe(this.switchMetric);
    this.model.selectedMetric.subscribe(this.showHideExportDataOption);
    this.showHideExportDataOption(this.model.selectedMetric());
    // preset manager
    //console.log "@@@ DCRV @@@ Contructing presset mananger"
    this.model.loadingAPreset.subscribe(this.resetMetricPoller);
    return this.presets = new PresetManager(this.model, (this.crossAppSettings.selectedMetric != null) && ((this.options != null) && (this.options.applyfilter === "true")));
  }

  // called during the initialisation process this stores relevent values in the model
  initialiseRackDefs(defs) {
    super.initialiseRackDefs(...arguments);

    if ((this.options != null ? this.options.rackIds : undefined) != null) { 
      this.model.displayingAllRacks(false);
    }
  
    return this.recievedRacksAndChassis('racks');
  }

  recievedRacksAndChassis(got_what){
    if (got_what === 'racks') {
      this.got_racks = true;
    }
    if (got_what === 'chassis') {
      this.got_chassis = true;
    }

    if ((this.got_racks === true) && (this.got_chassis === true)) {
      this.setAPIFilter();
      if (this.model.showingFullIrv()) { return this.createPresetManager(); }
    }
  }


  initialisePowerStripDefs(defs) {
    ++this.resourceCount;

    const allAssets = [];
    for (var powerStripAsset of Array.from(defs.assetList)) { allAssets.push(powerStripAsset); }
    if (this.model.assetList() != null) {
      for (var rackAsset of Array.from(this.model.assetList())) { allAssets.push(rackAsset); }
    }
    this.model.assetList(allAssets);
    this.synchroniseChanges(defs.assetList);

    this.model.powerStrips(defs.powerStrips);
    this.model.deviceLookup().powerStrips = defs.deviceLookup.powerStrips;
    return this.testLoadProgress();
  }

  initialiseNonRackDeviceDefs(defs) {
    ++this.resourceCount;

    const allAssets = [];
    for (var oneNonrackAsset of Array.from(defs.assetList)) { allAssets.push(oneNonrackAsset); }
    if (this.model.assetList() != null) {
      for (var previousAsset of Array.from(this.model.assetList())) { allAssets.push(previousAsset); }
    }
    this.model.assetList(allAssets);
    this.synchroniseChanges(defs.assetList);

    this.model.nonrackDevices(defs.rackableNonRackChassis);

    let nonRackChassisToShow = defs.dcrvShowableNonRackChassis;
    if (this.crossAppSettings.selectedNonRackChassis != null) {
      nonRackChassisToShow = [];
      for (var oneN in this.crossAppSettings.selectedNonRackChassis) {
        for (var oneD of Array.from(defs.dcrvShowableNonRackChassis)) {
          if (oneD.id === parseInt(oneN)) {
            nonRackChassisToShow.push(oneD);
          }
        }
      }
    }

    this.model.dcrvShowableNonRackChassis(nonRackChassisToShow);
    return this.recievedRacksAndChassis('chassis');
  }

  // called whenever a resource finishes loading during initialisation process or when new racks definitions are received following
  // modifications to the data centre. Updates loading dialogue and triggers synchronisation or next step of initialisation as necessary
  testLoadProgress() {
    let progress;
    const assets = this.model.assetList();

    if ((assets != null) && (assets.length >= 0)) {
      const num_assets = assets.length;
      progress   = this.calculateProgress(num_assets);
      //XXX We have loaded everything now, this is where we action any rebuilding and redrawing
      //
      //console.log "testLoadProgress::::",@resourceCount,CanvasController.NUM_RESOURCES,"---",@assetCount,num_assets,"=========",progress
      if ((this.resourceCount === CanvasController.NUM_RESOURCES) && (this.assetCount === num_assets)) {
        this.assetCount = 0;
        if (this.initialised) {
          this.rackSpace.synchroniseNonRackDevices(this.model.modifiedDcrvShowableNonRackChassis(), this.changeSetNonRacks);
          this.rackSpace.synchroniseRacks(this.model.modifiedRackDefs(), this.changeSetRacks);
          this.rackSpace.synchronisePowerStrips(this.model.modifiedPowerStripDefs(), this.changeSetPowerStrip);
          this.rackSpace.resetRackSpace();
          this.setAPIFilter();
          if (this.rackSpace.chart != null) { this.rackSpace.chart.update(); }
          this.model.modifiedDcrvShowableNonRackChassis([]); // Clear memory
          this.model.modifiedRackDefs([]); // Clear memory
          this.model.modifiedPowerStripDefs([]); // Clear memory for PowerStrips
        } else {
          this.init() && !this.initialised;
        }
      }
    } else {
      progress = 0;
    }

    return $('dialogue').innerHTML = CanvasController.RESOURCE_LOAD_CAPTION.replace(/\[\[progress\]\]/g, progress + '%');
  }

  // generic request error handler
  loadError(err_str, err) {
    return Profiler.trace(Profiler.CRITICAL, `loadError ${err_str}`);
  }


  // generic request failure handler
  loadFail(failee) {
    return Profiler.trace(Profiler.CRITICAL, `loadFail ${failee}`);
  }


  // sends a request for metric data to the server, called on an interval
  loadMetrics() {
    //console.log "@@@ DCRV @@@ LOADING METRICS"
    const selected_metric = this.model.selectedMetric();
    if (this.noMetricSelected(selected_metric)) { return; }

    const metric_api = this.model.metricLevel() === ViewModel.METRIC_LEVEL_VHOSTS ? this.resources.vhMetricData : this.resources.metricData;

    new Request.JSON({
      url        : this.resources.path + metric_api.replace(/\[\[metric_id\]\]/g, selected_metric) + '?' + (new Date()).getTime(),
      onComplete : this.receivedMetrics,
      headers    : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      data       : this.apiFilter
    }).send();

    // also grab vms if viewing all
    if (this.model.metricLevel() === ViewModel.METRIC_LEVEL_ALL) {
      this.vHostId = null;
      return this.loadVMMetrics();
    }
  }


  // called when the server responds with metric data
  // @param  metrics the metric data as returned by the server
  receivedMetrics(metrics) {
    //console.log "@@@ DCRV @@@ RECEIVED METRICS",metrics
    // display update message and display metrics a short while after
    // this allows the screen to redraw once the update message has been
    // added, otherwise the process will be tied up in the processing of
    // the metrics and the update message will not be displayed. There
    // us a Util function forceImmediateRedraw which might negate the need
    // for a timeout here but I can't test if this actually works with
    // my small datacentre
    if (this.model.showingFullIrv()) { this.showUpdateMsg(); }
    clearTimeout(this.dispTmr);
    // If the DCRV is initialised (All the images loaded and rendered), then display metrics, otherwise save the metrics in a variable, and wait for the initialization.
    if (this.initialised) {
      return this.displayTheMetrics(metrics);
    } else {
      this.metricValues = metrics;
      return this.waitingForInitialisation = true;
    }
  }

  // Called when the metrics data has arrived, and the DCRV is initialised
  // Avoids the issue when metrics arrives before full irv is rendered, and fails to draw some elements.
  displayTheMetrics(metrics) {
    this.pieCountdown.reStart(this.model.metricPollRate()/1000);
    return this.dispTmr = setTimeout((this.model.metricLevel() === ViewModel.METRIC_LEVEL_VHOSTS ? this.displayVHMetrics : this.displayMetrics), 50, metrics);
  }

  // parses metric data, dertermines max/min if no colour map exists for the selected metric and updates filtered devices where necessary
  // @param  metrics metric data as received from the server
  displayMetrics(metrics) {
    // VM metrics arrive in a separate request so maintain any existing VM metric data
    const old_metrics = this.model.metricData();
    const {
      vms
    } = old_metrics.values;

    metrics = this.parser.parseMetrics(metrics);
    metrics.values.vms = vms;

    const filters  = this.model.filters();
    const filter   = filters[metrics.metricId];
    const col_maps = this.model.colourMaps();
    const col_map  = col_maps[metrics.metricId];

    // We check to see if this run of code is simply a timed poll for the same metric,
    // if it is then use the existing min/max filters and colour maps, other wise we
    // must have selected a new metric, and we should rebuild its colour maps
    //
    // See ticket #11051 - above logic has been removed as it caused other problems
    //
  
    //@toggleViewIfNecessary(metrics)
  
    if (col_map) {
      if ((col_map.original_low == null) || (col_map.original_high == null)) {
        col_map.original_low = col_map.low;
        col_map.original_high = col_map.high;
        col_maps[metrics.metricId] = col_map;
        this.model.colourMaps(col_maps);
      }
      this.model.metricData(metrics);
      if ((filter != null) && ( ((filter.max != null) && (filter.max !== col_map.high)) || ((filter.min != null) && (filter.min !== col_map.low)) )) { this.applyFilter(); }
    } else {
      // no default colour map or filter defined, calculate now
      let range;
      if (filters[metrics.metricId] == null) {
        filters[metrics.metricId] = {};
        this.model.filters(filters);
      }

      // determine min max
      const group_vals = metrics.values[this.model.metricLevel()];
      let min        = Number.MAX_VALUE;
      let max        = -Number.MAX_VALUE;
      for (var id in group_vals) {
        var val = Number(group_vals[id]);
        if (val < min) { min = val; }
        if (val > max) { max = val; }
      }

      // If the min and max are equal (in the not very probable scenario where every device has the same value for the selectedMetric), 
      // then separate them by the IRVController.RANGE_EXPANSION_FACTOR
      if (min === max) {
        min -= min*IRVController.RANGE_EXPANSION_FACTOR;
        max += max*IRVController.RANGE_EXPANSION_FACTOR;
      }

      if (min === Number.MAX_VALUE) {
        // no metrics to determine min/max so set to zero. The small range value prevents
        // division by zero errors elsewhere
        range = 1e-100;
        min   = 0;
        max   = 0;
      } else {
        range = max - min;
      }

      col_maps[metrics.metricId] = { low: min, high: max, range, inverted: false, original_low: min, original_high: max };

      this.model.colourMaps(col_maps);
      this.model.metricData(metrics);
    }

    this.rackSpace.setMetricLevel(this.model.metricLevel());
    if (this.model.showingFullIrv()) { return this.hideUpdateMsg(); }
  }


  // parses metric data, dertermines max/min if no colour map exists for the selected metric and updates filtered devices where necessary
  // @param  metrics metric data as received from the server
  displayVHMetrics(metrics) {
    // VM metrics arrive in a separate request so maintain any existing VM metric data
    const old_metrics = this.model.metricData();
    const {
      vms
    } = old_metrics.values;

    metrics = this.parser.parseVHMetrics(metrics);
    metrics.values.vms = vms;

    const filters  = this.model.filters();
    const filter   = filters[metrics.metricId];
    const col_maps = this.model.colourMaps();
    const col_map  = col_maps[metrics.metricId];

    if (col_map != null) {
      if ((col_map.original_low == null) || (col_map.original_high == null)) {
        col_map.original_low = col_map.low;
        col_map.original_high = col_map.high;
        col_maps[metrics.metricId] = col_map;
        this.model.colourMaps(col_maps);
      }
      this.model.metricData(metrics);
      if ((filter.max !== col_map.high) || (filter.min !== col_map.low)) { this.applyFilter(); }
    } else {
      // no default colour map or filter defined, calculate now
      let range;
      if (filters[metrics.metricId] == null) {
        filters[metrics.metricId] = {};
        this.model.filters(filters);
      }

      // determin min max
      const group_vals = metrics.values[this.model.metricLevel()];
      let min        = Number.MAX_VALUE;
      let max        = -Number.MAX_VALUE;
      for (var id in group_vals) {
        var val = Number(group_vals[id]);
        if (val.min < min) { ({
          min
        } = val); }
        if (val.max > max) { ({
          max
        } = val); }
      }

      // If the min and max are equal (in the not very probable scenario where every device has the same value for the selectedMetric), 
      // then separate them by the IRVController.RANGE_EXPANSION_FACTOR
      if (min === max) {
        min -= min*IRVController.RANGE_EXPANSION_FACTOR;
        max += max*IRVController.RANGE_EXPANSION_FACTOR;
      }

      if (min === Number.MAX_VALUE) {
        // no metrics to determin min/max so set to zero. The small range value prevents
        // division by zero errors elsewhere
        range = 1e-100;
        min   = 0;
        max   = 0;
      } else {
        range = max - min;
      }

      col_maps[metrics.metricId] = { low: min, high: max, range, inverted: false, original_low: min, original_high: max };

      this.model.colourMaps(col_maps);
      this.model.metricData(metrics);
    }

    if (this.model.showingFullIrv()) { return this.hideUpdateMsg(); }
  }

  toggleViewIfNecessary(metrics) {
    const devicesMetrics = Object.keys(metrics.selection.devices).length;
    const chassisMetrics = Object.keys(metrics.selection.chassis).length;
    let new_level = null;
    if ((devicesMetrics === 0) && (chassisMetrics > 0)) {
      new_level = "chassis";
    }
    if ((devicesMetrics > 0) && (chassisMetrics === 0)) {
      new_level = "devices";
    }
    if ((devicesMetrics > 0) && (chassisMetrics > 0)) {
      new_level = "all";
    }

    if (new_level !== null) {
      return this.model.metricLevel(new_level);
    }
  }


  // rack view mouse wheel event handler
  // @param  ev  the event object which invoked execution
  evMouseWheelRack(ev) {

    // get device at the present coordinates to determine if it is a PowerStrip
    const coords      = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
    coords.x /= this.rackSpace.scale;
    coords.y /= this.rackSpace.scale;
    let device_bellow = this.rackSpace.getDeviceAt(coords.x, coords.y);
    if (device_bellow instanceof Socket) {
      device_bellow = device_bellow.parent;
    }

    if (device_bellow instanceof PowerStrip && (this.rackSpace.scale === RackSpace.MAX_ZOOM)) { 
      ev.preventDefault();
      ev.stopPropagation();

      const mouseDeltaY = this.getDeltaMouseY(ev);
      // power strip scrolled down
      if (mouseDeltaY > 0) {
        if (device_bellow.y < this.rackSpace.rackParent.scrollTop) {
          device_bellow.setCoords(device_bellow.x,(device_bellow.y + mouseDeltaY));
        }
      }

      // power strip scrolled up
      if (mouseDeltaY < 0) {
        if ((device_bellow.y + device_bellow.height) >  (this.rackSpace.rackParent.scrollTop + this.rackSpace.rackParent.clientHeight)) {
          device_bellow.setCoords(device_bellow.x,(device_bellow.y + mouseDeltaY));
        }
      }

    } else {
      this.rackSpace.arrangePowerStrips();
      this.evStepZoom(ev);
    }

    return this.highlightRackSpace(ev);
  }

  // Function to get the mouse wheel Y delta, normalized between browsers.
  getDeltaMouseY(event) {
    let rolled = 0;
    if (event.wheelDeltaY != null) {
      rolled = event.wheelDeltaY;
    } else if (event.wheelDelta != null) {
      rolled = event.wheelDelta;
    } else {
      rolled = -40 * event.detail;
    }
    return rolled;
  }

  // thumb navigation mouse wheel event handler
  // @param  ev  the event object which invoked execution
  evMouseWheelThumb(ev) {
    return this.evStepZoom(ev);
  }


  // generic mouse wheel event handler. Activates step-zooming if zoom key is depressed
  // @param  ev  the event object which invoked execution
  evStepZoom(ev) {
    if (this.keysPressed[IRVController.ZOOM_KEY]) {
      ev.preventDefault();
      ev.stopPropagation();
      const coords = Util.resolveMouseCoords(this.thumbEl, ev);
      return this.stepZoom(ev.wheelDelta / Math.abs(ev.wheelDelta), (coords.x / this.thumb.width) * this.rackSpace.coordReferenceEl.width, (coords.y / this.thumb.height) * this.rackSpace.coordReferenceEl.height);
    }
  }


  // key down event handler, maintains a lookup object of which keys are currently pressed
  // @param  ev  the event object which invoked execution
  evKeyDown(ev) {
    return this.keysPressed[ev.keyCode] = true;
  }


  // key down event handler, maintains a lookup object of which keys are currently pressed
  // @param  ev  the event object which invoked execution
  evKeyUp(ev) {
    return this.keysPressed[ev.keyCode] = false;
  }


  // rack view right click event handler, displays context menu
  // @param  ev  the event object which invoked execution
  evRightClickRack(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    this.clickAssigned = true;
    const coords         = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
    const pos            = this.rackParent.getPosition();
    // if the view decides to display a custom context menu then prevent the default menu from showing
    return this.rackSpace.showContextMenu({ x: ev.clientX - pos.x, y: ev.clientY - pos.y}, coords);
  }


  // rack view left click event handler, initialises drag handling
  // @param  ev  the event object which invoked execution
  evMouseDownRack(ev) {
    // ignore anything other than left-clicks
    if (((ev.which != null) && ((ev.which !== 1) && (ev.which !== 2))) || ((ev.button != null) && ((ev.button !== 0) && (ev.button !== 1)))) { return; }
    let coords      = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
    const rack_coords = Util.resolveMouseCoords(this.rackEl, ev);

    // ensure mouse down hasn't originated from the scrollbar region
    if (true) { // rack_coords.x - @rackEl.scrollLeft < @rackElDims.width - @scrollAdjust and rack_coords.y - @rackEl.scrollTop < @rackElDims.height - @scrollAdjust
      if (ev.which === 1) {
        this.downCoords = {x:coords.x,y:coords.y};

        // get device at the present coordinates 
        coords.x /= this.rackSpace.scale;
        coords.y /= this.rackSpace.scale;
        const device = this.rackSpace.getDeviceAt(coords.x, coords.y);

        return Events.addEventListener(this.rackEl, 'mousemove', this.evDrag);
      } else if (ev.which === 2) {
        coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
        return this.rackSpace.middleClick(coords.x, coords.y);
      }
    } else {
      return this.downCoords = null;
    }
  }


  // rack view mouse up event handler, cancels drag handling and handles click action interpretation. Javascript doesn't handle double
  // click's very well, it fires a dblclick event as well as two click events making actioning the events difficult. Rather than listen
  // for a dblclick event we create a timeout, if another click is received before the timeout executes we interpret as a double click;
  // if the timeout executes it is interpreted as a single click. The downside of this is a slight delay perceived by the user before any
  // single click is actioned
  // @param  ev  the event object which invoked execution
  evMouseUpRack(ev) {
    // Only considering left-clicks
    if (((ev.which != null) && (ev.which === 1)) || ((ev.button != null) && (ev.button === 0))) {

      // Ensure the mouse down hasn't originated from the scrollbar region
      if (this.downCoords == null) { return; }

      if (ev.which === 1) {
        this.upCoords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
        clearTimeout(this.clickTmr);
        Events.removeEventListener(this.rackEl, 'mousemove', this.evDrag);

        // decide if this is a single or double-click
        if (this.dragging) {
          const coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
          this.rackSpace.stopDrag(coords.x, coords.y);
          this.clickAssigned = true;
          this.dragging      = false;
          return this.model.dragging(this.dragging);
        } else if (this.clickAssigned) {
          this.clickAssigned = false;
          return this.clickTmr      = setTimeout(this.evClick, IRVController.DOUBLE_CLICK_TIMEOUT, ev);
        } else {
          this.clickAssigned = true;
          if (this.model.showingFullIrv() || this.model.showingRacks()) { return this.evDoubleClick(ev); }
        }
      }
    }
  }


  // rack view single click event handler, invoked when the possibility of a double click has been eliminated
  // @param  ev  the event object which invoked execution
  evClick(ev) {
    if (!this.clickAssigned) {
      this.clickAssigned = true;
      const coords         = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
      this.dragging      = false;

      this.rackSpace.click(coords.x, coords.y, this.keysPressed[IRVController.MULTI_SELECT_KEY]);
      return Events.removeEventListener(this.rackEl, 'mousemove', this.evDrag);
    }
  }


  // rack view double click event handler, start zoom animation
  // @param  ev  the event object which invoked execution
  evDoubleClick(ev) {

    if (this.model.showHoldingArea() && this.rackSpace.holdingArea.overInternalArea(this.downCoords.x/this.rackSpace.scale, this.downCoords.y/this.rackSpace.scale)) {
      this.zoomHoldingArea(1, this.downCoords.x/this.rackSpace.scale, this.downCoords.y/this.rackSpace.scale);
      return;
    }

    // clear selection
    if (document.selection && document.selection.empty) {
        document.selection.empty();
    } else if (window.getSelection) {
        const sel = window.getSelection();
        sel.removeAllRanges();
      }

    ev.preventDefault();
    ev.stopPropagation();
    return this.zoomToPreset(1, this.downCoords.x, this.downCoords.y);
  }


  // rack view drag event handler, invoked on mouse move with left mouse button depressed. Activates dragging only if mouse has moved
  // beyond a threshold distance from the original click coordinates.
  // @param  ev  the event object which invoked execution
  evDrag(ev) {
    const coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
    if (!this.dragging) {
      this.dragging = Math.sqrt(Math.pow(coords.x - this.downCoords.x, 2) + Math.pow(coords.y - this.downCoords.y, 2)) > IRVController.DRAG_ACTIVATION_DIST;
      this.model.dragging(this.dragging);
      if (this.dragging) {
        this.clickAssigned = true;
        return this.rackSpace.startDrag(this.downCoords.x, this.downCoords.y);
      }
    } else {
      return this.rackSpace.drag(coords.x, coords.y);
    }
  }


  // rack view mouse move event handler, initialises hover hint timer and actions device hover highlighting
  // @param  ev  the event object which invoked execution
  evMouseMoveRack(ev) {
    // side step annoying false move events
    if ((ev.clientX === this.ev.clientX) && (ev.clientY === this.ev.clientY)) { return; }

    let coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, ev);
    coords = {x: coords.x/this.rackSpace.scale, y: coords.y/this.rackSpace.scale};
    if (this.model.showHoldingArea()) {
      if (this.rackSpace.holdingArea.overTheHoldingArea(coords.x,coords.y)) {
        this.moveHoldingArea(coords.x,coords.y);
      } else if (this.rackSpace.holdingArea.moving === true) {
        this.rackSpace.holdingArea.moving = false;
      }
    }

    return this.highlightRackSpace(ev);
  }

  moveHoldingArea(x,y) {
    if (this.rackSpace.holdingArea.overTheEdges() > 0) {
      if (this.rackSpace.holdingArea.moving !== true) {
        return this.rackSpace.holdingArea.move();
      }
    } else if (this.rackSpace.holdingArea.overTheEdges() === 0) {
      return this.rackSpace.holdingArea.moving = false;
    }
  }

  highlightRackSpace(event) {
    clearTimeout(this.hintTmr);
    const div_coords    = Util.resolveMouseCoords(this.rackEl, event);
    div_coords.x -= this.rackEl.scrollLeft;
    div_coords.y -= this.rackEl.scrollTop;
    let coords        = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, event);

    if (this.pieCountdown != null) {
      this.pieCountdown.showHint(Util.resolveMouseCoords(this.pieCountdown.gfx.cvs, event),this.topHint);
    }

    // exit if moving over scrollbar area
    //return if div_coords.x > @rackElDims.width - @scrollAdjust or div_coords.y > @rackElDims.height - @scrollAdjust

    this.hintTmr = setTimeout(this.showRackHint, IRVController.RACK_HINT_HOVER_DELAY);
    this.ev      = event;

    this.rackSpace.hideHint();
    //unless @dragging
    coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, event, true);
    const deltaVertical = (event.deltaY != null) ? event.deltaY : 0;
    if (this.rackSpace.holdingArea != null) { this.rackSpace.holdingArea.ev = event; }
    return this.rackSpace.highlightAt(coords.x, (coords.y + deltaVertical));
  }


  // thumb navigation mouse move event handler, initialises thumb hover hint timer
  // @param  ev  the event object which invoked execution
  evMouseMoveThumb(ev) {
    // side step annoying false move events
    if ((ev.clientX === this.ev.clientX) && (ev.clientY === this.ev.clientY)) { return; }

    clearTimeout(this.hintTmr);
    this.hintTmr = setTimeout(this.showThumbHint, IRVController.THUMB_HINT_HOVER_DELAY);
    this.ev = ev;
    return this.thumb.hideHint();
  }


  // rack view mouse out event handler
  // @param  ev  the event object which invoked execution
  evMouseOutRacks(ev) {
    clearTimeout(this.hintTmr);
    return this.rackSpace.clearHighlights();
  }


  // thumb navigation event handler
  // @param  ev  the event object which invoked execution
  evMouseOutThumb(ev) {
    return clearTimeout(this.hintTmr);
  }


  // rack view zoom complete event handler, resets update message, updates thumb navigation
  // @param  ev  the event object which invoked execution
  evZoomComplete(ev) {
    if (this.model.showingFullIrv()) { this.hideUpdateMsg(); }
    this.zooming = false;
    if (this.thumbEl != null) { this.updateThumb(); }
    return this.enableMouse();
  }


  // rack view flip (front/rear) animation complete event handler
  // @param  ev  the event object which invoked execution
  evFlipComplete(ev) {
    if (this.model.showingFullIrv()) { this.hideUpdateMsg(); }
    this.flipping = false;
    return this.enableMouse();
  }


  // LBC mouse down event handler, initialises drag event handling
  // @param  ev  the event object which invoked execution
  evMouseDownChart(ev) {
    const coords      = Util.resolveMouseCoords(this.chartEl, ev);
    this.downCoords = coords;
    return Events.addEventListener(this.chartEl, 'mousemove', this.evDragChart);
  }


  // LBC mouse up event handler, clears drag event handling and actions any selection box which has been created
  // @param  ev  the event object which invoked execution
  evMouseUpChart(ev) {
    this.upCoords = Util.resolveMouseCoords(this.chartEl, ev);
    Events.removeEventListener(this.chartEl, 'mousemove', this.evDragChart);

    if (this.dragging) {
      const coords = Util.resolveMouseCoords(this.chartEl, ev);
      this.rackSpace.stopDragChart(coords.x, coords.y);
      return this.dragging = false;
    }
  }


  // LBC drag event handler, invoked on mouse move with the left button depressed. Actions dragging only if mouse has moved beyond a
  // threshold distance from the originating click coordinates
  // @param  ev  the event object which invoked execution
  evDragChart(ev) {
    const coords = Util.resolveMouseCoords(this.chartEl, ev);
    if (!this.dragging) {
      this.dragging = Math.sqrt(Math.pow(coords.x - this.downCoords.x, 2) + Math.pow(coords.y - this.downCoords.y, 2)) > IRVController.DRAG_ACTIVATION_DIST;
      if (this.dragging) {
        return this.rackSpace.startDragChart(this.downCoords.x, this.downCoords.y);
      }
    } else {
      return this.rackSpace.dragChart(coords.x, coords.y);
    }
  }


  // called from a timeout, displays rack view hover hint
  showRackHint() {
    let left;
    if (this.dragging) { return; }
    const coords = Util.resolveMouseCoords(this.rackSpace.coordReferenceEl, this.ev);
    const pos    = ((left = $('tooltip').parentElement) != null ? left : $('tooltip').parentNode).getPosition();//@rackEl.getPosition()
    return this.rackSpace.showHint({ x: this.ev.clientX - pos.x, y: this.ev.clientY - pos.y }, coords);
  }


  // called from a timeout, translates thumb nav mouse coordinates into rack view coordinates and displays thumb navigation hover hint
  showThumbHint() {
    let left;
    let coords    = Util.resolveMouseCoords(this.thumbEl, this.ev);
    coords.x /= this.thumb.scale * this.rackSpace.scale;
    coords.y /= this.thumb.scale * this.rackSpace.scale;

    const device = this.rackSpace.getDeviceAt(coords.x, coords.y);
    coords = Util.resolveMouseCoords((left = $('tooltip').parentElement) != null ? left : $('tooltip').parentNode, this.ev);
    return this.thumb.showHint(device, coords.x, coords.y);
  }


  // disables mouse events to prevent user interaction during zoom/flip animations. This is probably redundant now following implementation
  // of the update message
  disableMouse() {
    if (this.model.showChart()) { Events.removeEventListener(this.chartEl, 'mousedown', this.evMouseDownChart); }
    if (this.model.showChart()) { Events.removeEventListener(this.chartEl, 'mouseup', this.evMouseUpChart); }
    if (this.model.showChart()) { Events.removeEventListener(this.chartEl, 'mousemove', this.evMouseMoveChart); }

    Events.removeEventListener(this.rackEl, 'mousedown', this.evMouseDownRack);
    Events.removeEventListener(this.rackEl, 'mouseup', this.evMouseUpRack);
    Events.removeEventListener(this.rackEl, 'mousemove', this.evMouseMoveRack);
    Events.removeEventListener(this.rackEl, 'contextmenu', this.evRightClickRack);
    if (this.model.showingRacks()) { Events.removeEventListener(this.rackEl, 'mousewheel', this.evMouseWheelRack); }
    if (this.model.showingRacks()) { Events.removeEventListener(this.rackEl, 'DOMMouseScroll', this.evMouseWheelRack); }

    if (this.thumbEl != null) { Events.removeEventListener(this.thumbEl, 'mousedown', this.evMouseDownThumb); }
    if (this.thumbEl != null) { Events.removeEventListener(this.thumbEl, 'mouseup', this.evMouseUpThumb); }
    if (this.thumbEl != null) { Events.removeEventListener(this.thumbEl, 'mousewheel', this.evMouseWheelThumb); }
    if (this.thumbEl != null) { Events.removeEventListener(this.thumbEl, 'DOMMouseScroll', this.evMouseWheelThumb); }
    if (this.thumbEl != null) { Events.removeEventListener(this.thumbEl, 'dblclick', this.evDoubleClickThumb); }
    if (this.thumbEl != null) { return Events.removeEventListener(this.thumbEl, 'mousemove', this.evMouseMoveThumb); }
  }


  // enables  mouse events on completion of zoom/flip animations. This is probably redundant now following implementation of the update
  // message
  enableMouse() {
    if (this.model.showChart()) { Events.addEventListener(this.chartEl, 'mousedown', this.evMouseDownChart); }
    if (this.model.showChart()) { Events.addEventListener(this.chartEl, 'mouseup', this.evMouseUpChart); }
    if (this.model.showChart()) { Events.addEventListener(this.chartEl, 'mousemove', this.evMouseMoveChart); }

    Events.addEventListener(this.rackEl, 'mousedown', this.evMouseDownRack);
    Events.addEventListener(this.rackEl, 'mouseup', this.evMouseUpRack);
    Events.addEventListener(this.rackEl, 'mousemove', this.evMouseMoveRack);
    Events.addEventListener(this.rackEl, 'contextmenu', this.evRightClickRack);
    if (this.model.showingRacks()) { Events.addEventListener(this.rackEl, 'DOMMouseScroll', this.evMouseWheelRack); }
    if (this.model.showingRacks()) { Events.addEventListener(this.rackEl, 'mousewheel', this.evMouseWheelRack); }

    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'mousedown', this.evMouseDownThumb); }
    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'mouseup', this.evMouseUpThumb); }
    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'mousewheel', this.evMouseWheelThumb); }
    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'DOMMouseScroll', this.evMouseWheelThumb); }
    if (this.thumbEl != null) { Events.addEventListener(this.thumbEl, 'dblclick', this.evDoubleClickThumb); }
    if (this.thumbEl != null) { return Events.addEventListener(this.thumbEl, 'mousemove', this.evMouseMoveThumb); }
  }


  // triggers the thumb navigation to redraw
  updateThumb() {
    return this.thumb.update(this.rackElDims.width, this.rackElDims.height, this.rackSpace.coordReferenceEl.width, this.rackSpace.coordReferenceEl.height, this.rackParent.scrollLeft, this.rackParent.scrollTop);
  }


  // applies above/below/between filter to all devices and stores subset in the view model
  applyFilter() {
    let filter, group;
    const filters         = this.model.filters();
    const selected_metric = this.model.selectedMetric();
    const metrics         = this.model.metricData();
    const selected_stat   = this.model.selectedMetricStat();

    const {
      min
    } = filters[selected_metric];
    const {
      max
    } = filters[selected_metric];

    const filtered_devices = {};
    const groups           = this.model.groups();
    for (group of Array.from(groups)) { filtered_devices[group] = {}; }

    const gt = val => {
      return val > min;
    };

    const lt = val => {
      return val < max;
    };

    const between = val => {
      return (val > min) && (val < max);
    };

    if ((min != null) && (max != null)) {
      filter = between;
    } else if (min != null) {
      filter = gt;
    } else if (max != null) {
      filter = lt;
    } else {
      if (this.model.activeFilter()) {
        this.model.activeFilter(false);
        this.model.filteredDevices(filtered_devices);
      }
      return;
    }

    let is_valid = false;
    // apply filter to each device
    for (group of Array.from(groups)) {
      for (var id in metrics.values[group]) {
        is_valid = true;
        filtered_devices[group][id] = filter(Number(metrics.values[group][id][selected_stat] != null ? metrics.values[group][id][selected_stat] : metrics.values[group][id]));
      }
    }

    // it's possible to be applying a filter before any data has been received
    // (when settings are carried over from the DCPV) in these cases we should
    // set activeFilter to false
    if (!is_valid) {
      this.model.activeFilter(false);
      this.model.filteredDevices(filtered_devices);
      return;
    }

    this.model.activeFilter(true);
    return this.model.filteredDevices(filtered_devices);
  }


  // rack view scroll event handler, updates thumb navigation when necessary
  // @param  ev  the event object which invoked execution
  evScrollRacks() {
    if (!this.zooming && !this.flipping && !(this.thumbEl == null)) { return this.updateThumb(); }
  }

  evRedrawRackSpace() {
    return this.rackSpace.redraw();
  }

  // assetList model value subscriber, commences loading of rack images
  evLoadRackAssets() {
    this.assetCount = 0;
    const assets      = this.model.assetList();

    const powerStripAssets = [PowerStrip.IMG_TOP, PowerStrip.IMG_REPEAT, PowerStrip.IMG_BTM, PowerStrip.IMG_WAIT, Socket.IMG_SOCKET_FRONT_GREY, Socket.IMG_SOCKET_FRONT_GREY_BUSY, Socket.IMG_SOCKET_FRONT_RED, Socket.IMG_SOCKET_FRONT_RED_BUSY, Socket.IMG_SOCKET_FRONT_GREEN, Socket.IMG_SOCKET_FRONT_GREEN_BUSY];
  
    // PowerStrip mandatory images (borders and socket)
    if (this.model.showingPowerStrips() || (this.model.showingRacks() && !this.model.showingFullIrv())) {
      for (var onePSAsset of Array.from(powerStripAssets)) {
        if (!Array.from(assets).includes(onePSAsset)) { assets.push(onePSAsset); }
      }
    }

    for (var asset of Array.from(assets)) {
      AssetManager.get(CanvasController.PRIMARY_IMAGE_PATH + asset, this.evAssetLoaded, this.evAssetFailed);
    }

    return this.model.assetList(assets);
  }


  // thumb navigation mouse down event handler, initialises drag handling
  // @param  ev  the event object which invoked execution
  evMouseDownThumb(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    this.thumbScroll(ev);
    return Events.addEventListener(this.thumbEl, 'mousemove', this.thumbScroll);
  }


  // thum navigation mouse up event handler, cancels drag handling
  // @param  ev  the event object which invoked execution
  evMouseUpThumb(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    this.thumbScroll(ev);
    return Events.removeEventListener(this.thumbEl, 'mousemove', this.thumbScroll);
  }


  // thumb navigation double click event handler, commences zoom operation
  // @param  ev  the event object which invoked execution
  evDoubleClickThumb(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    const coords = Util.resolveMouseCoords(this.thumbEl, ev);
    return this.zoomToPreset(1, (coords.x / this.thumb.width) * this.rackSpace.coordReferenceEl.width, (coords.y / this.thumb.height) * this.rackSpace.coordReferenceEl.height);
  }


  // thumb navigation drag handler, invoked on mouse move with left mouse button depressed. Scrolls the rack view according to thumb
  // navigation mouse coordinates
  // @param  ev  the event object which invoked execution
  thumbScroll(ev) {
    this.rackSpace.arrangePowerStrips();
    const coords    = Util.resolveMouseCoords(this.thumbEl, ev);

    this.rackParent.scrollLeft = ((coords.x / this.thumb.width) * this.rackSpace.coordReferenceEl.width) - (this.rackElDims.width / 2);
    return this.rackParent.scrollTop  = ((coords.y / this.thumb.height) * this.rackSpace.coordReferenceEl.height) - (this.rackElDims.height / 2);
  }


  // face model value subscriber, shows updating message
  switchFace(face) {
    if ((face !== ViewModel.FACE_BOTH) && (this.currentFace !== ViewModel.FACE_BOTH)) {
      if (this.model.showingFullIrv()) { this.showUpdateMsg(); }
      this.flipping = true;
    }

    return this.currentFace = face;
  }

  // face model value subscriber, shows updating message
  showOrHidePowerStripLayer() {
    if (this.model.showingPowerStrips() === false) {
      this.model.showingPowerStrips(true);
      return this.rackSpace.showPowerStripLayer();
    } else {
      this.model.showingPowerStrips(false);
      return this.rackSpace.hidePowerStripLayer();
    }
  }

  updateShowOrHidePowerStripsLink() {
    if (this.model.showingPowerStrips()) {
      return (this.showPowerStripsLink != null ? this.showPowerStripsLink.innerHTML = "Hide PDUs" : undefined);
    } else {
      return (this.showPowerStripsLink != null ? this.showPowerStripsLink.innerHTML = "View PDUs" : undefined);
    }
  }

  // filter bar mouse down event hander, initialises drag handling
  // @param  ev  the event object which invoked execution
  evMouseDownFilter(ev) {
    if (ev.target instanceof HTMLInputElement) { return; }

    ev.preventDefault();
    ev.stopPropagation();

    const coords      = Util.resolveMouseCoords(this.filterBarEl, ev);
    this.slider     = this.filterBar.getSliderAt(coords.x, coords.y);
    this.dragging   = false;
    this.downCoords = coords;

    if (this.slider != null) {
      return Events.addEventListener(this.filterBarEl, 'mousemove', this.evMouseMoveFilter);
    } else {
      return Events.addEventListener(document.window, 'mousemove', this.evMouseMoveFilter);
    }
  }


  // filter bar mouse out event handler
  // @param  ev  the event object which invoked execution
  evMouseOutFilter(ev) {
    return Events.removeEventListener(this.filterBarEl, 'mousemove', this.evMouseMoveFilter);
  }


  // filter bar mouse up event handler, clears drag handling
  // @param  ev  the event object which invoked execution
  evMouseUpFilter(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    this.showUpdateMsg();
    this.filterBar.stopDrag();
    this.hideUpdateMsg();

    Events.removeEventListener(this.filterBarEl, 'mousemove', this.evMouseMoveFilter);
    return Events.removeEventListener(document.window, 'mousemove', this.evMouseMoveFilter);
  }


  // filter bar drag event handler, invoked on mouse move with the left mouse button depressed. Decides if the user is attempting to drag
  // a slider or the bar itself
  evMouseMoveFilter(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    const coords = Util.resolveMouseCoords(this.filterBarEl, ev);

    if (this.slider != null) {
      return this.filterBar.dragSlider(this.slider, coords.x, coords.y);
    }
  }
    //else
    //  if @dragging
    //    @filterBar.dragBar(ev.pageX, ev.pageY)
    //  else
    //    # commence dragging only if the user has moved the mouse a certain distance
    //    @dragging = Math.sqrt(Math.pow(coords.x - @downCoords.x, 2) + Math.pow(coords.y - @downCoords.y, 2)) > IRVController.DRAG_ACTIVATION_DIST
    //    if @dragging
    //      @filterBar.startDrag()
    //      Events.addEventListener(document.window, 'mouseup', @evFilterStopDrag)


  // filter bar drag complete handler, invoked on mouse up during dragging. It'll take you longer to read this comment than it will the
  // code beolw... see? wasn't that a waste of time?
  evFilterStopDrag(ev) {
    this.filterBar.stopDrag();
    return Events.removeEventListener(document.window, 'mousemove', this.evMouseMoveFilter);
  }


  switchPreset() {
    return this.presets.switchPreset();
  }

  // context menu get hint info event handler, this requests from the server additional info on a device to show in the rack view
  // hover hint
  // @param  ev  the event object which invoked execution
  evGetHintInfo(ev) {
    let url = this.resources.path + this.resources.hintData.replace(/\[\[device_id\]\]/g, this.rackSpace.hint.device.id) + '?' + (new Date()).getTime();
    url = url.replace(/\[\[group\]\]/g, this.rackSpace.hint.device.group);

    return new Request.JSON({
      url,
      data       : { virtual_host: this.rackSpace.hint.device.type === 'VirtualHost' },
      headers    : { 'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content') },
      onComplete : this.hintInfoReceived
    }).send();
  }


  // metric poll input change event handler, validates new value and actions change on a timeout
  // @param  ev  the event object which invoked execution
  evEditMetricPoll(ev) {
    Util.setStyle(this.metricPollInput, 'background', this.isValidPoll() ? '' : IRVController.INVALID_POLL_COLOUR);
    return this.pollEditTmr = setTimeout(this.setMetricPoll, IRVController.METRIC_POLL_EDIT_DELAY);
  }


  // metric poll input blur event handler, actions new poll rate
  // @param  ev  the event object which invoked execution
  evSetMetricPoll(ev) {
    return this.setMetricPoll();
  }

  evResetMetricPoller(ev) {
    this.resetFilters();
    this.setAPIFilter();
    return this.resetMetricPoller();
  }

  // reads the metric poll input value, validates it and switches off metric polling or resets as necessary
  setMetricPoll() {
    const new_poll = Math.round(this.metricPollInput.value * 1000);
    if (!this.isValidPoll() || (new_poll === this.model.metricPollRate())) { return; }
  
    // mute subscription
    this.pollSub.dispose();
    this.model.metricPollRate(new_poll);
    // re-subscribe
    this.pollSub = this.model.metricPollRate.subscribe(this.setMetricPollInput);

    if (this.model.selectedMetric() == null) { return; }
    clearInterval(this.metricTmr);
    if (new_poll === 0) {
      // clear metric data
      const groups = this.model.groups();
      const blank  = { values: {} };
      for (var group of Array.from(groups)) { blank.values[group] = {}; }
      this.model.metricData(blank);
      // clear chart
      this.rackSpace.chart.clear();
      return;
    }

    // restart poller
    return this.resetMetricPoller();
  }


  // tests the value of the metric poll input
  // @return boolean, true if value is numeric and permittable
  isValidPoll() {
    const new_poll = Math.round(this.metricPollInput.value * 1000);
    // poll rate is a number, isn't negative and is either zero or above min poll rate
    return !isNaN(new_poll) && (new_poll >= 0) && !((new_poll > 0)  && (new_poll < IRVController.MIN_METRIC_POLL_RATE));
  }


  // metricPoll model value subscriber, sets the metric poll input value should it change
  // @param  poll_rate the new poll rate value
  setMetricPollInput(poll_rate) {
    return this.metricPollInput.value = poll_rate / 1000;
  }


  // filter bar drop event handler, called on mouse up having first dragged the filter bar
  // @param  ev  the event object which invoked execution
  evDropFilterBar(ev) {
    return this.updateLayout();
  }


  // callback invoked on receiving extra hover hint info from the server
  // @param  hint_info an object containing hover hint information as returned by the server
  hintInfoReceived(hint_info) {
    return this.rackSpace.hint.appendData(hint_info);
  }


  // selectedMetricStat model subscriber, the stat represents a specific agreggated metric value. If filtering is active this causes the
  // filter to update based upon the newly selected statistic
  // @param  stat  the name of the newly selected statistic
  evSwitchStat(stat) {
    const selected_metric = this.model.selectedMetric();
    const filter          = this.model.filters()[selected_metric];
    const col_map         = this.model.colourMaps()[selected_metric];
  
    if ((selected_metric == null) || (filter == null) || (col_map == null)) { return; }

    if (((filter.max != null) && (filter.max !== col_map.high)) || ((filter.min != null) && (filter.min !== col_map.low))) { return this.applyFilter(); }
  }


  // There is one subscriber to selectedGroup in the StaticGroupManager class that runs before this one,
  // But we also need this subscriber here to setMetricLevel when the selected group has been blanked.
  evSwitchGroup(group) {
    if (this.model.noGroupSelected()) {
      return this.rackSpace.setMetricLevel(this.currentMetricLevel);
    }
  }

  // graphOrder model value subscriber, sets the agreggated metric statistic based upon the chosen chart order
  // @param  order   the newly selected graph order
  evSwitchGraphOrder(order) {
    switch (order) {
      case 'maximum':
        return this.model.selectedMetricStat('max');
      case 'minimum':
        return this.model.selectedMetricStat('min');
      case 'average':
        return this.model.selectedMetricStat('mean');
      default:
        if (this.model.selectedMetricStat() !== null) { return this.model.selectedMetricStat(IRVController.DEFAULT_METRIC_STAT); }
    }
  }


  // rack view show VM event handler, starts VM metric poller and displays VM popup
  // @param  ev  the event object which invoked execution
  evShowVMs(ev) {
    this.vHostId     = ev.data;
    this.showingVMs  = true;

    if ((this.model.selectedMetric() == null) || (this.model.metricPollRate() === 0)) { return; }

    this.vmMetricTmr = setInterval(this.loadVMMetrics, this.model.metricPollRate());
    return this.loadVMMetrics();
  }


  // rack view hide VM event handler, stops VM metric poller
  // @param  ev  the event object which invoked execution
  evHideVMs(ev) {
    this.showingVMs = false;
    return clearInterval(this.vmMetricTmr);
  }


  // sends request for VM metrics to the server
  loadVMMetrics() {
    return new Request.JSON({
      url        : this.resources.path + this.resources.vmMetricData.replace(/\[\[metric_id\]\]/g, this.model.selectedMetric()) + '?' + (new Date()).getTime(),
      method     : 'post',
      onComplete : this.receivedVMMetrics,
      headers    : { 'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content') },
      data       : { host_id: this.vHostId }
    }).send();
  }


  // called when the server responds with VM metrics, updates model with new metric data
  receivedVMMetrics(vm_metrics) {
    const metrics     = this.parser.parseVMMetrics(vm_metrics);
    const old_metrics = this.model.metricData();
    const groups      = this.model.groups();

    // all other metrics arrive in a separate request so preserve any metric data
    // for those groups
    for (var group of Array.from(groups)) {
      if (group === 'vms') { continue; }
      metrics.values[group] = old_metrics.values[group];
    }

    return this.model.metricData(metrics);
  }
};

IRVController.initClass();
export default IRVController;
