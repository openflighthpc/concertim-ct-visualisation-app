import Util from 'canvas/common/util/Util';
import Profiler from 'Profiler';


// takes the various JSON structures, reformats if necessary and populates the view model
class Parser {
  // Configuration that can be overwritten by the config.
  OFFLINE_METRIC_VARIANCE  = 0.2;
  OFFLINE                  = true;

  constructor(model) {
    this.model = model;
  }

  parseRackDefs(rack_defs, filter=null) {
    Profiler.begin(Profiler.CRITICAL, this.parseRackDefs);
    const apply_filter = filter !== null;
    let filtered       = false;
    const device_lookup = this.model.getBlankComponentClassNamesObject();
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

  parseOneRack(rack, device_lookup, assets) {
    let image;
    rack.uHeight   = Number(rack.uHeight);
    rack.instances = [];
    device_lookup.racks[rack.id] = rack;
  
    // add any omitted template data
    if (rack.template != null) {
      this.parseTemplate(rack, { rows: 1, columns: 1, images: {}, height: 1, depth: 'f', padding: { left: 0, right: 0, top: 0, bottom: 0 } });
    } else {
      rack.template = { rows: 1, columns: 1, images: {}, height: 1, depth: 'f', padding: { left: 0, right: 0, top: 0, bottom: 0 } };
    }
  
    // delete any images with a zero length string, otherwise add to asset list
    for (image in rack.template.images) {
      if (rack.template.images[image].length === 0) {
        delete rack.template.images[image];
      } else {
        assets[rack.template.images[image]] = true;
      }
    }
  
  
    if (rack.Chassis == null) { rack.Chassis = []; }
    rack.chassis = rack.Chassis;
    if (!(rack.chassis instanceof Array)) { rack.chassis = [rack.chassis]; }
    delete rack.Chassis;
  
    let count2 = 0;
    let len2   = rack.chassis.length;
    while (count2 < len2) {
      var chassis = rack.chassis[count2];
      // !! ignore zero U devices until a later version 
      if ((chassis.type !== 'Chassis') && (chassis.type !== 'RackChassis')) {
        rack.chassis.splice(count2, 1);
        --len2;
        continue;
      }
    
      chassis.instances = [];
  
      // the api supplies all numeric values as strings
      chassis.rows   = Number(chassis.rows);
      chassis.slots  = Number(chassis.slots);
      chassis.cols   = Number(chassis.cols);
      chassis.uStart = Number(chassis.uStart);
      chassis.uEnd   = Number(chassis.uEnd);
  
      device_lookup.chassis[chassis.id] = chassis;
  
      // offset uStart to be zero indexed
      --chassis.uStart;
  
      // add any omitted template data
      if (chassis.template != null) {
        this.parseTemplate(chassis, { rows: 1, columns: 1, images: {}, height: 1, depth: 'f', padding: { left: 0, right: 0, top: 0, bottom: 0 } });
      } else {
        chassis.template = { rows: 1, columns: 1, images: {}, height: 1, depth: 'f', padding: { left: 0, right: 0, top: 0, bottom: 0 } };
      }
  
      if ((chassis.template.height === 1) && (chassis.uStart != null) && (chassis.uEnd != null)) { chassis.template.height  = chassis.uEnd - chassis.uStart; }
  
      var unit = (chassis.template.images != null) ? chassis.template.images.unit : null; 
  
      // delete any images with a zero length string, otherwise add to asset list
      for (image in chassis.template.images) {
        if (chassis.template.images[image].length === 0) {
          delete chassis.template.images[image];
        } else {
          assets[chassis.template.images[image]] = true;
        }
      }
  
      var {
        facing
      } = chassis;
  
      if (chassis.Slots == null) {
        ++count2;
        continue;
      }
      // a chassis with a single machine is described as an object, whereas blade centres
      // are described as an array of object. Make consistent so all are an array of objects
      if (!(chassis.Slots instanceof Array)) { chassis.Slots = [chassis.Slots]; }
  
      var count3 = 0;
      var len3   = chassis.Slots.length;
      while(count3 < len3) {
        var slot    = chassis.Slots[count3];
        var machine = slot.Machine;
  
        // make column naming consistant
        slot.column = Number(slot.col);
        slot.row    = Number(slot.row);
  
        // zero index column and row
        --slot.column;
        --slot.row;
  
        if ((machine != null) && (machine.id != null)) {
          device_lookup.devices[machine.id] = machine;
        
          machine.instances = [];
          machine.column    = slot.column;
          machine.row       = slot.row;
  
          // carry over parent facing value
          machine.facing = facing;
  
          // create machine template
          machine.template = { images: {}, width: 1, height: 1, rotateClockwise: true };
          if (unit != null) { machine.template.images = { front: unit }; }
        }
        ++count3;
      }
        //else
        //  chassis.machines.splice(count, 1)
        //  --len2
      ++count2;
    }
  }

  parseTemplate(item) {
    Profiler.begin(Profiler.CRITICAL, this.parseTemplate);

    item.template.id      = Number(item.template.id);
    item.template.rows    = Number(item.template.rows);
    item.template.columns = Number(item.template.columns);
    item.template.height  = Number(item.template.height);
    item.template.depth   = Number(item.template.depth);
    item.template.rackable = Number(item.template.rackable);
    item.template.simple  = item.template.simple === "true";

    if (item.template.images == null) {
      item.template.images  = {};
    }

    item.template.padding = {};
    item.template.padding.left   = Number(item.template.padding_left);   delete item.template.padding_left;
    item.template.padding.right  = Number(item.template.padding_right);  delete item.template.padding_right;
    item.template.padding.top    = Number(item.template.padding_top);    delete item.template.padding_top;
    item.template.padding.bottom = Number(item.template.padding_bottom); delete item.template.padding_bottom;

    return Profiler.end(Profiler.CRITICAL, this.parseTemplate);
  }

  parseMetrics(metrics) {
    Profiler.begin(Profiler.CRITICAL);
    if (metrics == null) { metrics = { name: '', values: {}, selection: {} }; }

    metrics.metricId = metrics.name;
    delete metrics.name;

    const device_lookup = this.model.deviceLookup();
    const componentClassNames = this.model.componentClassNames();

    // turn array into an object indexed by id for fast access
    if (metrics.values == null) { metrics.values = {}; }
    if (metrics.selection == null) { metrics.selection = {}; }
    for (let className of Array.from(componentClassNames)) {
      if (metrics.values[className] == null) { metrics.values[className] = {}; }
      if (metrics.selection[className] == null) { metrics.selection[className] = {}; }
    }

    const values_obj = {};
    const sel_obj = {};
    for (let className in metrics.values) {
      var set = {};
      var sel = {};
      for (var metric of Array.from(metrics.values[className])) {

        // ignore unrecognised metrics, may be present due to zero U devices and NRADS
        if (device_lookup[className][metric.id] == null) { continue; }

        set[metric.id] = Util.formatValue(Number(metric.value));
        sel[metric.id] = true;
      }

      values_obj[className] = set;
      sel_obj[className] = sel;
    }

    metrics.values = values_obj;
    metrics.selection = sel_obj;

    Profiler.end(Profiler.CRITICAL);
    return metrics;
  }


  parseMetricTemplates(metric_templates) {
    Profiler.begin(Profiler.CRITICAL);
    const metric_obj = {};
    for (var metric of Array.from(metric_templates)) { metric_obj[metric.id] = metric; }
    Profiler.end(Profiler.CRITICAL);
    return metric_obj;
  }

};

export default Parser;
