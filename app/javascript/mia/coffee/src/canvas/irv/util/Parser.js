/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import CanvasParser from 'canvas/common/CanvasParser';
import Util from 'canvas/common/util/Util';
import Profiler from '../../../../../javascript/irv/Profiler';


// takes the various JSON structures, reformats if necessary and populates the view model
class Parser extends CanvasParser {
  static initClass() {
    this.OFFLINE_METRIC_VARIANCE  = .2;
    this.OFFLINE                  = true;
  }


  constructor(model) {
    super(...arguments);
    this.model = model;
  }


  parseRackDefs(rack_defs, filter=null) {
    Profiler.begin(Profiler.CRITICAL, this.parseRackDefs);
    const apply_filter = filter === null ? false : true;

    // format data and create lookup table based on rack/chassis/device id
    const groups        = this.model.groups();
    let filtered      = false;
    const device_lookup = { byGroup: {} };
    for (var group of Array.from(groups)) { device_lookup[group] = {}; }
    const assets = {};
  
    if (Object.keys(rack_defs).length === 0) {
      rack_defs = {};
    } else {
      rack_defs = rack_defs.Racks.Rack;
      if (!(rack_defs instanceof Array)) { rack_defs = [rack_defs]; }

      // colate list of assets to preload, use an object to negate duplication
      let count  = 0;
      let len    = rack_defs.length;
      while (count < len) {
        var rack = rack_defs[count];

        if (apply_filter && !filter[rack.id]) {
          filtered = true;
          --len;
          rack_defs.splice(count, 1);
          continue;
        }

        this.parseOneRack(rack, device_lookup, assets);

        ++count;
      }
    }
    
    // turn asset object into array
    const asset_list = [];
    for (var asset in assets) { asset_list.push(asset); }

    Profiler.end(Profiler.CRITICAL, this.parseRackDefs);
    return { filtered, assetList: asset_list, racks: rack_defs, deviceLookup: device_lookup };
  }

  parseMetrics(metrics) {
    let group;
    Profiler.begin(Profiler.CRITICAL, this.parseMetrics);
    if (metrics == null) { metrics = { name: '', values: {}, selection: {} }; }

    metrics.metricId = metrics.name;
    delete metrics.name;

    const device_lookup = this.model.deviceLookup();
    const groups        = this.model.groups();

    // turn array into an object indexed by id for fast access
    if (metrics.values == null) { metrics.values = {}; }
    if (metrics.selection == null) { metrics.selection = {}; }
    for (group of Array.from(groups)) {
      if (metrics.values[group] == null) { metrics.values[group] = {}; }
      if (metrics.selection[group] == null) { metrics.selection[group] = {}; }
    }

    const values_obj = {};
    const sel_obj = {};
    for (group in metrics.values) {
      var set = {};
      var sel = {};
      for (var metric of Array.from(metrics.values[group])) {

        // ignore unrecognised metrics, may be present due to zero U devices and NRADS
        if (device_lookup[group][metric.id] == null) { continue; }

        set[metric.id] = Util.formatValue(Number(metric.value));
        sel[metric.id] = true;
      }

      values_obj[group] = set;
      sel_obj[group] = sel;
    }

    metrics.values = values_obj;
    metrics.selection = sel_obj;

    Profiler.end(Profiler.CRITICAL, this.parseMetrics);
    return metrics;
  }


  parseMetricTemplates(metric_templates) {
    Profiler.begin(Profiler.CRITICAL, this.parseMetricTemplates);
    const metric_obj = {};
    for (var metric of Array.from(metric_templates)) { metric_obj[metric.id] = metric; }
    Profiler.end(Profiler.CRITICAL, this.parseMetricTemplates);
    return metric_obj;
  }

};
Parser.initClass();
export default Parser;
