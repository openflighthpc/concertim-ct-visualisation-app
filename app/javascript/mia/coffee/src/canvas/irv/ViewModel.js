/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */


import CanvasViewModel from 'canvas/common/CanvasViewModel'
import Util from 'canvas/common/util/Util'

class ViewModel extends CanvasViewModel {
  static initClass() {
    // startup properties, can be overwritten by url parameters
    this.INIT_VIEW_MODE      = 'Images and bars';
    this.INIT_METRIC_LEVEL   = 'machine';
    this.INIT_GRAPH_ORDER    = 'ascending';
    this.INIT_SCALE_METRICS  = true;
    this.INIT_SHOW_CHART     = true;
    this.INIT_SHOW_FILTER_BAR     = true;
    this.INIT_METRIC         = null;

    this.VIEW_MODE_BOTH         = 'Images and bars';
    this.VIEW_MODE_IMAGES       = 'Images only';
    this.VIEW_MODE_METRICS      = 'Bars only';
    this.VIEW_MODE_BUILD_STATUS = 'Build status';

    this.METRIC_LEVEL_DEVICES  = 'devices';
    this.METRIC_LEVEL_CHASSIS  = 'chassis';
    this.METRIC_LEVEL_ALL      = 'all';
    this.GROUP_NO_VALUE        = 'No group selected';

    this.NORMAL_CHART_ORDERS  = [ 'ascending', 'descending', 'physical position', 'name' ];

    this.EXCLUDED_METRICS     = ['ct.capacity.rack'];

    // statics overwritten by config
    this.COLOUR_SCALE = [{ pos: 0, col: '#000000' }, { pos: 1, col: '#ffffff' }];
  }


  constructor() {
    let group;
    super(...arguments);

    this.loadingAPreset = ko.observable(false);
    this.overLBC = ko.observable(false);

    // RBAC = Rule Base Access Control object, which holds the current users permissions
    this.RBAC = null;

    // display mode settings
    // view mode dictates wether metrics and images are drawn
    this.viewMode  = ko.observable(ViewModel.INIT_VIEW_MODE);
    this.viewModes = ko.observable([ViewModel.VIEW_MODE_IMAGES, ViewModel.VIEW_MODE_METRICS, ViewModel.VIEW_MODE_BOTH, ViewModel.VIEW_MODE_BUILD_STATUS]);

    // string, metric level determines wether to display chassis or device level metrics.
    this.metricLevel = ko.observable(ViewModel.INIT_METRIC_LEVEL);

    // string, chart sort order
    this.graphOrder  = ko.observable(ViewModel.INIT_GRAPH_ORDER);
    this.graphOrders = ko.observable(ViewModel.NORMAL_CHART_ORDERS);

    // boolean, do metric bars on devices scale to reflect their value or just show a colour
    this.scaleMetrics = ko.observable(ViewModel.INIT_SCALE_METRICS);

    // set chart visibility
    this.showChart = ko.observable(ViewModel.INIT_SHOW_CHART);

    this.showFilterBar = ko.observable(ViewModel.INIT_SHOW_FILTER_BAR);

    // set holding area
    this.showHoldingArea = ko.observable(false);

    // string, id of currently selected metric
    this.selectedMetric = ko.observable(ViewModel.INIT_METRIC);

    // int, poll rate period in ms
    this.metricPollRate = ko.observable(ViewModel.INIT_METRIC_POLL_RATE);//.extend({ ignoreNull: true })

    // string, represents which value of an agreggated metric to operate on when filtering
    this.selectedMetricStat = ko.observable();

    // boolean, is the user viewing the entire data centre or a subset?
    this.displayingAllRacks = ko.observable(true);

    // array, list of references to the currently highlighted device(s)
    this.highlighted = ko.observable([]);

    // id groups, both group and id are required to identify an individual device
    this.groups = ko.observable(['racks', 'chassis', 'devices']);

    // temporary storage of device definitions (used in synchronising changes to devices)
    this.modifiedRackDefs = ko.observable();

    // temporary storage of dcrvShowableNonRackChassis
    this.modifiedDcrvShowableNonRackChassis = ko.observable();

    // object, preset definitions using id as the key
    this.presetsById = ko.observable({});

    // string, the name of the currently selected preset
    this.selectedPreset = ko.observable();

    // array, a list of available preset names
    this.presetNames    = ko.dependentObservable(function() {
      const presetNames = Object.values(this.presetsById()).map(p => p.name);
      return Util.sortCaseInsensitive(presetNames);
    }
    , this);

    // boolean, are presets available? Dependencies: presetNames
    this.enablePresetSelection = ko.dependentObservable(function() {
      const presets = this.presetNames();
      return (presets != null) && (presets.length > 0);
    }
    , this);

    // object, group definitions using group id as the key. Initially these contain just the string group name and id. After
    // a group has been selected and it's definition loaded the definition is also stored here to act as a cache
    this.groupsById = ko.observable([]);

    // string, name of the currently selected group
    this.selectedGroup = ko.observable();

    // array of strings, list of available group names
    this.groupNames = ko.dependentObservable(function() {
      const presets      = this.groupsById();
      let preset_names = [];
      for (var i in presets) { preset_names.push(presets[i].name); }
      Util.sortCaseInsensitive(preset_names);
      preset_names = [ViewModel.GROUP_NO_VALUE].concat(preset_names);
      return preset_names;
    }
    , this);

    // boolean, is the group drop-down enabled? Dependencies: groupNames
    this.enableGroupSelection = ko.dependentObservable(function() {
      const groups = this.groupNames();
      return (groups != null) && (groups.length > 0);
    }
    , this);

    // boolean, is a selection active (e.g. by dragging a selection box or clicking 'Focus on')
    this.activeSelection = ko.observable(false);

    this.dragging = ko.observable(false);

    // object, devices in current selection, uses id group as the top-level key and id as the second level key
    this.selectedDevices = ko.observable({});

    // boolean, is a filter active (metrics which satisfy above/below/between filters if any)
    this.activeFilter = ko.observable(false);

    // object, devices in current filter, uses id group as the top-level key and id as the second level key
    this.filteredDevices = ko.observable({});

    // object, stores metric definitions using metric id as the key
    this.metricTemplates = ko.observable([]);

    let blank        = {};
    const groups       = this.groups();
    for (group of Array.from(groups)) { blank[group] = {}; }
    // object, parsed metric data pushed from server. Values are contained in 'values' object
    this.metricData = ko.observable({ values: blank });

    // array, stores the parsed nonrack devices definition JSON
    this.nonrackDevices = ko.observable([]);
    this.dcrvShowableNonRackChassis = ko.observable([]);

    // canvas, a snapshot of the rack view used by the thumb navigation
    this.rackImage = ko.observable();

    blank        = {};
    for (group of Array.from(groups)) { blank[group] = {}; }
    // object, defines the physical dimensions of the breaching devices. Used to draw red boxes in thumb navigation. Uses group as
    // the top-level key, then id
    this.breachZones = ko.observable(blank);

    // float, the current zoom level of the rack view 1 represents 100% where all images will be drawn at their natural size
    this.scale = ko.observable();

    // float, the zoom level the rack view is going to be zoomed to
    this.targetScale = ko.observable();

    // object, stores colour maps for each metric using metric id as the key
    this.colourMaps = ko.observable({});

    // object, stores range based filters against each metric, uses metric id as the key 
    this.filters = ko.observable({});

    // array, dictates colouring of metric values
    this.colourScale = ko.observable(ViewModel.COLOUR_SCALE);
    this.normalColoursArray = ViewModel.COLOUR_SCALE;
    this.invertedColoursArray = [];
  
    let count = 0;
    const len   = this.normalColoursArray.length;
    while (count < len) {
      this.invertedColoursArray[len - count - 1] = { col: this.normalColoursArray[count].col, pos: 1 - this.normalColoursArray[count].pos };
      ++count;
    }


    // boolean, will apply gradient effect to the LBC metrics colouring (bars or lines)
    this.gradientLBCMetric = ko.observable(false);

    this.invertedColours = ko.observable(false);

    // array of strings, list of available metric ids. Dependencies: metricTemplates
    this.metricIds = ko.dependentObservable(function() {
      let metric_ids = [];
      const metrics    = this.metricTemplates();
      for (var metric in metrics) {
        if (!this.isInExcludedMetrics(metrics[metric].name)) { metric_ids.push(metrics[metric].id); }
      }
      return metric_ids;
    }
    , this);

    // boolean, is the metric combo box active? Dependencies: metricIds
    this.enableMetricSelection = ko.dependentObservable(function() {
      const metrics = this.metricIds();
      return (metrics != null) && (metrics.length > 0);
    }
    , this);
  }

  displayingMetrics() {
    return this.viewMode() === ViewModel.VIEW_MODE_METRICS
      || this.viewMode() === ViewModel.VIEW_MODE_BOTH;
  }

  displayingImages() {
    return this.viewMode() === ViewModel.VIEW_MODE_IMAGES
      || this.viewMode() === ViewModel.VIEW_MODE_BOTH;
  }

  displayingBuildStatus() {
    return this.viewMode() == ViewModel.VIEW_MODE_BUILD_STATUS;
  }

  validMetric(metric) {
    let needle;
    return (needle = metric, Array.from(this.metricIds()).includes(needle));
  }

  isInExcludedMetrics(one_metric_name) {
    for (var one_metric_to_exclude of Array.from(ViewModel.EXCLUDED_METRICS)) {
      // Return true if one_metric_name starts with one_metric_to_exclude
      if ((one_metric_name != null) && (one_metric_name.indexOf(one_metric_to_exclude) === 0)) { return true; }
    }
    return false;
  }

  resetSelectedGroup() {
    this.selectedGroup(null);
  }

  // Reset the "metric value filter" filter.
  resetFilter() {
    this.activeFilter(false);
    this.filteredDevices(this.getBlankGroupObject());
  
    const selected_metric          = this.selectedMetric();
    const filters                  = this.filters();
    filters[selected_metric] = {};
    return this.filters(filters);
  }

  // Reset the "selection" filter.  The one activated by dragging a selection
  // box of clicking on Focus on.
  resetSelection() {
    this.activeSelection(false);
    this.selectedDevices(this.getBlankGroupObject());
  }

  resetMetricData() {
    let blank  = { values: {} };
    for (let group of this.groups()) { blank.values[group] = {}; }
    this.metricData(blank);
  }

  noGroupSelected() {
    return (this.selectedGroup() == null) || (this.selectedGroup() === null) || (this.selectedGroup() === ViewModel.GROUP_NO_VALUE);
  }

  getBlankGroupObject() {
    const obj        = {};
    const groups     = this.groups();
    for (var group of Array.from(groups)) { obj[group] = {}; }

    return obj;
  }

  getColoursArray() {
    if (this.invertedColours() === true) {
      return this.invertedColoursArray;
    } else {
      return this.normalColoursArray;
    }
  }
};
ViewModel.initClass();
export default ViewModel;