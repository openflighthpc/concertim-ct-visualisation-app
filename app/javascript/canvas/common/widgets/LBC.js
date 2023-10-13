/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import SimpleChart from 'canvas/common/widgets/SimpleChart';

class LBC {
  static initClass() {
    // statics overwritten by configuration.json
    // Not sure why we set them here if their values are ultimately
    // irrelevant.
    this.TITLE_CAPTION  = 'something about cats';

    this.POINTER_OFFSET_X  = 10;
    this.POINTER_OFFSET_Y  = 10;

    this.SELECT_COUNT_OFFSET_X  = 0;
    this.SELECT_COUNT_OFFSET_Y  = 0;
    this.SELECT_COUNT_FILL      = '#000000';
    this.SELECT_COUNT_FONT      = '12px Karla';
    this.SELECT_COUNT_PADDING   = 5;
    this.SELECT_COUNT_BG_ALPHA  = 0.5;
    this.SELECT_COUNT_BG_FILL   = '#FF00FF';
    this.SELECT_COUNT_CAPTION   = 'selected: [[selection_count]]';
  
    this.SELECT_BOX_STROKE        = '#000000';
    this.SELECT_BOX_STROKE_WIDTH  = 2;
    this.SELECT_BOX_ALPHA         = 0.8;

    this.BAR_CHART_MIN_DATUM_WIDTH  = 2;

    this.FILL_SINGLE_SERIES_LINE_CHARTS  = true;

    this.LINE_POINTER_COLOUR  = '#0';
    this.LINE_POINTER_WIDTH   = 1;

    this.MODEL_DEPENDENCIES = { showChart: 'showChart', selectedDevices: 'selectedDevices', filteredDevices: 'filteredDevices',
                                metricData: 'metricData', colourMaps: 'colourMaps', colourScale: 'colourScale',
                                graphOrder: 'chartSortOrder', racks: 'racks', highlighted: 'highlighted',
                                metricLevel: 'metricLevel', metricTemplates: 'metricTemplates', selectedMetric: 'selectedMetric',
                                metricChart: 'metricChart', deviceLookup: 'deviceLookup', componentClassNames: 'componentClassNames',
                                activeSelection: 'activeSelection', activeFilter: 'activeFilter' };


    // constants and run-time assigned statics
    this.AXIS_SPACER  = 10;
  }


  constructor(containerEl, model, canvasId) {
    this.updateLayout = this.updateLayout.bind(this);
    this.evShowChart = this.evShowChart.bind(this);
    this.setSubscriptions = this.setSubscriptions.bind(this);
    this.update = this.update.bind(this);
    this.clear = this.clear.bind(this);
    this.highlightDatum = this.highlightDatum.bind(this);
    this.makePositionLookup = this.makePositionLookup.bind(this);
    this.evShowHint = this.evShowHint.bind(this);
    this.evHideHint = this.evHideHint.bind(this);
    this.containerEl = containerEl;
    this.model = model;
    if (canvasId == null) { canvasId = 'lbc'; }
    this.canvasId = canvasId;
    this.pointerEl    = $('pointer');
    this.noDataEl     = $('no-metrics-data');
    this.heightOffset = -this.pointerEl.getCoordinates().height;
    this.over         = false;

    // create model reference store
    this.modelRefs      = {};
    for (var key in LBC.MODEL_DEPENDENCIES) { var value = LBC.MODEL_DEPENDENCIES[key]; this.modelRefs[key] = this.model[value]; }

    this.subscriptions = [];
    this.visSub        = this.modelRefs.showChart.subscribe(this.evShowChart);
    this.setSubscriptions();

    const componentClassNames     = this.modelRefs.componentClassNames();
    this.posLookup = {};
    for (let className of Array.from(componentClassNames)) { this.posLookup[className] = {}; }

    this.cvs    = document.createElement('canvas');
    this.ctx    = this.cvs.getContext('2d');
    this.cvs.id = this.canvasId;

    this.containerEl.appendChild(this.cvs);
    this.updateLayout();
  }


  updateLayout() {
    const dims        = this.containerEl.getCoordinates();
    this.cvs.width  = dims.width;
    this.cvs.height = dims.height + this.heightOffset;

    if (this.data != null) { return this.update(); }
  }


  evShowChart(visible) {
    if (visible) {
      Util.setStyle(this.containerEl, 'display', 'block');
    } else {
      this.clear();
      Util.setStyle(this.containerEl, 'display', 'none');
    }

    return this.setSubscriptions(visible);
  }


  setSubscriptions(visible) {
    if (visible == null) { visible = this.modelRefs.showChart(); }
    if (visible) {
      if (this.modelRefs.selectedDevices != null) { this.subscriptions.push(this.modelRefs.selectedDevices.subscribe(this.update)); }
      if (this.modelRefs.filteredDevices != null) { this.subscriptions.push(this.modelRefs.filteredDevices.subscribe(this.update)); }
      if (this.modelRefs.metricData != null) { this.subscriptions.push(this.modelRefs.metricData.subscribe(this.update)); }
      if (this.modelRefs.colourMaps != null) { this.subscriptions.push(this.modelRefs.colourMaps.subscribe(this.update)); }
      if (this.modelRefs.graphOrder != null) { this.subscriptions.push(this.modelRefs.graphOrder.subscribe(this.update)); }
      if (this.modelRefs.highlighted != null) { this.subscriptions.push(this.modelRefs.highlighted.subscribe(this.highlightDatum)); }
      if (this.modelRefs.metricLevel != null) { this.subscriptions.push(this.modelRefs.metricLevel.subscribe(this.update)); }
      if (this.modelRefs.gradientLBCMetric != null) { return this.subscriptions.push(this.modelRefs.gradientLBCMetric.subscribe(this.update)); }
    } else {
      // prevent any updates happening when the chart is hidden
      return Array.from(this.subscriptions).map((sub) => sub.dispose());
    }
  }


  update() {
    let is_included;
    this.clear();

    const start = (new Date()).getTime();

    const selected_metric = this.modelRefs.selectedMetric();
    const metric_template = this.modelRefs.metricTemplates()[selected_metric];
    const metric_data     = this.modelRefs.metricData();

    // ignore unrecognised metrics or redundant requests (when the metric data isn't
    // for the current metric)
    if ((metric_template == null) || (metric_data.metricId !== selected_metric) || (this.cvs.width === 0) || (this.cvs.height === 0)) { return; }

    const selected_devices = this.modelRefs.selectedDevices();
    const active_selection = this.modelRefs.activeSelection();
    const filtered_devices = this.modelRefs.filteredDevices();
    const active_filter    = this.modelRefs.activeFilter();

    // subset filters
    const test_selection = (componentClassName, id) => selected_devices[componentClassName][id];

    const test_filter = (componentClassName, id) => filtered_devices[componentClassName][id];

    const test_both = (componentClassName, id) => filtered_devices[componentClassName][id] && selected_devices[componentClassName][id];

    const test_none = (componentClassName, id) => true;

    // chose a filter based upon current view
    if (active_selection && active_filter) {
      is_included = test_both;
    } else if (active_selection) {
      is_included = test_selection;
    } else if (active_filter) {
      is_included = test_filter;
    } else {
      is_included = test_none;
    }

    const set       = this.getDataSet(is_included);

    // duplicate the data, for stress testing only
    //tmp = set.data.slice(0)
    //count = 0
    //while(count < 12549)
    //  set.data = set.data.concat(tmp)
    //  ++count
  
    this.data     = set.data;
    this.included = set.included;

    if (set.data.length > 0) {
      Util.setStyle(this.noDataEl, 'display', 'none');
      // sort
      let max_min;
      switch (this.modelRefs.graphOrder()) {
        case 'ascending':
          Util.sortByProperty(set.data, 'numMetric', true);
          break;
        case 'descending':
          Util.sortByProperty(set.data, 'numMetric', false);
          break;
        case 'physical position':
          Util.sortByProperty(set.data, 'pos', true);
          break;
        case 'item name': case 'name':
          Util.sortByProperty(set.data, 'name', true);
          break;
        case 'maximum':
          Util.sortByProperty(set.data, ((set.data[0].numMax != null) ? 'numMax' : 'numMetric'), true);
          break;
        case 'minimum':
          Util.sortByProperty(set.data, ((set.data[0].numMin != null) ? 'numMin' : 'numMetric'), true);
          break;
        case 'average':
          Util.sortByProperty(set.data, ((set.data[0].numMean != null) ? 'numMean' : 'numMetric'), true);
          break;
      }

      const mask      = [];
      const col_scale = this.modelRefs.colourScale();
      const col_map   = this.modelRefs.colourMaps()[this.modelRefs.selectedMetric()];
      if (this.modelRefs.gradientLBCMetric()) {
        for (var col_stop of Array.from(col_scale)) {
          var col_str = col_stop.col.toString(16);
          while (col_str.length < 6) { col_str = '0' + col_str; }
          mask.push({ colour: '#' + col_str, pos: (col_map.range * col_stop.pos) + col_map.low });
        }
      }

      const datum_width = (this.cvs.width - SimpleChart.MARGIN_LEFT - SimpleChart.MARGIN_RIGHT) / set.data.length;
      this.chart      = new SimpleChart(this.cvs, $('tooltip'));
      this.plotLine   = datum_width < LBC.BAR_CHART_MIN_DATUM_WIDTH;

      const chart_config = {
        xValue     : 'name',
        yValues    : set.series != null ? set.series : [ 'numMetric' ],
        colours    : set.colours != null ? set.colours : [ 'colour' ],
        colourMask : mask
      };

      this.multiSeries               = chart_config.yValues.length > 1;
      chart_config.fillBelowLine = LBC.FILL_SINGLE_SERIES_LINE_CHARTS && !this.multiSeries;

      this.dataToRender = set.data;
      this.chartConfig = chart_config;
      if (this.plotLine) {
        max_min = this.chart.drawLine(set.data, chart_config);
      } else {
        max_min = this.chart.drawBar(set.data, chart_config);
      }

      // ensure enough space is provided for y-axis labels
      //num_commas  = Math.floor((String(Math.round(scale.high)).length - 1) / 3)
      //len         = String(Math.round(scale.high)).length + (if scale.dp is 0 then 0 else scale.dp + 1)
      //test_label  = ''
      //test_label += '8' while test_label.length < len
      //test_label += ',' while test_label.length < len + num_commas
      //max_width   = @cvs.getContext('2d').measureText(test_label).width

      console.log('update complete, ' + set.data.length + ' metrics plotted in ' + ((new Date()).getTime() - start) + 'ms');
    
      const componentClassNames = this.modelRefs.componentClassNames();
      this.idxById = {};
      for (let className of Array.from(componentClassNames)) { this.idxById[className] = {}; }
      for (let idx = 0; idx < set.data.length; idx++) { var datum = set.data[idx]; this.idxById[datum.className][datum.id] = idx; }

      const the_min = typeof max_min.min === "string" ? max_min.min : Util.formatValue(max_min.min);
      const the_max = typeof max_min.max === "string" ? max_min.max : Util.formatValue(max_min.max);
      const the_av  = Util.formatValue((parseFloat(the_max) + parseFloat(the_min)) / 2);
      let title = unescape(LBC.TITLE_CAPTION);
      // swap in title variables
      title = Util.substitutePhrase(title, 'metric_name', metric_template.name);
      title = Util.substitutePhrase(title, 'num_metrics', set.data.length);
      title = Util.substitutePhrase(title, 'total_metrics', set.sampleSize);
      title = Util.substitutePhrase(title, 'max_val', the_max);
      title = Util.substitutePhrase(title, 'min_val', the_min);
      title = Util.substitutePhrase(title, 'av_val',  the_av);
      title = Util.substitutePhrase(title, 'metric_units', (metric_template.units != null) && (metric_template.units !== "") ? '('+metric_template.units+')' : '');
      title = Util.cleanUpSubstitutions(title);

      this.title = title;
      this.chart.setTitle(title);
      this.chart.addEventListener('onshowtooltip', this.evShowHint);
      this.chart.addEventListener('onhidetooltip', this.evHideHint);
    } else if(this.modelRefs.metricChart() === "current") {
      Util.setStyle(this.noDataEl, 'display', 'block');
    }
  }


  // queries all metric data to return the subset defined by the current display settings.
  // Accepts an inclusion function which should return true/false to indicate if a member
  // satisfies current selection and filter settings if any. Also returns an object of the
  // included members structured by their class name and id
  getDataSet(inclusion_filter) {
    let componentClassName;
    const data             = [];
    const metric_data      = this.modelRefs.metricData();
    const metric_templates = this.modelRefs.metricTemplates();
    const metric_template  = metric_templates[metric_data.metricId];
    const selected_metric  = this.modelRefs.selectedMetric();
    const device_lookup    = this.modelRefs.deviceLookup();
    const componentClassNames = this.modelRefs.componentClassNames();
    const included         = {};
    for (let className of Array.from(componentClassNames)) { included[className]  = {}; }

    const col_map  = this.modelRefs.colourMaps()[metric_data.metricId];
    const col_high = col_map.high;
    const col_low  = col_map.low;
    const range    = col_high - col_low;

    const component_classes_to_consider = componentClassNames;
    const values = metric_data.values;

    let sample_count = 0;
    // extract subset of all metrics according to display settings
    for (let className of Array.from(component_classes_to_consider)) {
      for (var id in values[className]) {
        ++sample_count;
        if (inclusion_filter(className, id)) {
          var device = device_lookup[className][id];

          included[className][id] = true;

          var metric = values[className][id];
          var temp   = (metric - col_low) / range;
          var col    = this.getColour(temp).toString(16);
          while (col.length < 6) { col    = '0' + col; }
          var name   = device ? (device.name != null ? device.name : id) : 'unknown';
        
          data.push({
            name,
            id,
            className,
            pos       : this.posLookup[className][id],
            metric,
            numMetric : Number(metric),
            colour    : '#' + col,
            instances : device.instances
          });
        }
      }
    }

    return { data, sampleSize: sample_count, included };
  }


  destroy() {
    this.clear();
    this.visSub.dispose();
    return Array.from(this.subscriptions).map((sub) => sub.dispose());
  }


  clear() {
    if (this.chart != null) {
      this.chart.destroy();
      return this.chart = null;
    }
  }


  getColour(val) {
    const colours = this.model.getColoursArray();
    if ((val <= 0) || isNaN(val)) { return colours[0].col; }
    if (val >= 1) { return colours[colours.length - 1].col; }

    let count = 0;
    const len   = colours.length;
    while (val > colours[count].pos) { ++count; }
    const low  = colours[count - 1];
    const high = colours[count];

    return Util.blendColour(low.col, high.col, (val - low.pos) / (high.pos - low.pos));
  }


  highlightDatum() {
    const device = this.modelRefs.highlighted()[0];
    if (device == null || this.modelRefs.metricChart() !== 'current') {
      Util.setStyle(this.pointerEl, 'visibility', 'hidden');
      if (this.hoverCvs != null) {
        this.containerEl.removeChild(this.hoverCvs);
        this.hoverCvs = null;
      }
      return;
    }

    const id = device.id != null ? device.id : device.itemId;
    if ((this.chart != null) && !this.over && (this.included != null) && (this.included[device.componentClassName] != null) && this.included[device.componentClassName][id] && (this.idxById[device.componentClassName][id] != null)) {
      const coords = this.chart.coords[this.idxById[device.componentClassName][id]];
      const x      = this.plotLine ? coords.x : coords.centre;
      const {
        y
      } = coords;

      if (this.plotLine && this.multiSeries) {
        let ctx;
        if (this.hoverCvs != null) {
          ctx = this.hoverCvs.getContext('2d');
          ctx.clearRect(0, 0, this.hoverCvs.width, this.hoverCvs.height);
        } else {
          const dims = this.cvs.getCoordinates(this.containerEl);

          this.hoverCvs        = document.createElement('canvas');
          this.hoverCvs.width  = dims.width;
          this.hoverCvs.height = dims.height;

          Util.setStyle(this.hoverCvs, 'position', 'absolute');
          Util.setStyle(this.hoverCvs, 'left', dims.left);//Util.getStyle(@chart.cvs, 'left'))
          Util.setStyle(this.hoverCvs, 'top', dims.top);//Util.getStyle(@chart.cvs, 'top'))

          this.containerEl.appendChild(this.hoverCvs);

          ctx             = this.hoverCvs.getContext('2d');
          ctx.strokeStyle = LBC.LINE_POINTER_COLOUR;
          ctx.lineWidth   = LBC.LINE_POINTER_WIDTH;
        }

        ctx.beginPath();
        ctx.moveTo(x, this.chart.cvs.height - SimpleChart.MARGIN_BOTTOM);
        ctx.lineTo(x, SimpleChart.MARGIN_TOP);
        return ctx.stroke();
      } else {
        Util.setStyle(this.pointerEl, 'left', x + LBC.POINTER_OFFSET_X + 'px');
        Util.setStyle(this.pointerEl, 'top', y + LBC.POINTER_OFFSET_Y + 'px');
        Util.setStyle(this.pointerEl, 'visibility', 'visible');

        if (this.hoverCvs != null) {
          this.containerEl.removeChild(this.hoverCvs);
          return this.hoverCvs = null;
        }
      }
    } else {
      Util.setStyle(this.pointerEl, 'visibility', 'hidden');

      if (this.hoverCvs != null) {
        this.containerEl.removeChild(this.hoverCvs);
        return this.hoverCvs = null;
      }
    }
  }


  getSelection(box) {
    const componentClassNames = this.modelRefs.componentClassNames();
    const selection        = {};
    for (let className of Array.from(componentClassNames)) { selection[className] = {}; }
    let active_selection = false;
    let count            = 0;
    const box_left         = box.x;
    const box_right        = box_left + box.width;
    const {
      coords
    } = this.chart;

    const get_line_co = coord => coord.x;

    const get_bar_co = coord => coord.centre;

    const get_co = this.plotLine ? get_line_co : get_bar_co;

    const line_co_within_box = coord => (coord.x >= box_left) && (coord.x <= box_right);

    const bar_co_within_box = coord => (coord.centre >= box_left) && (coord.centre <= box_right);

    //within_box = if @plotLine then line_co_within_box else bar_co_within_box

    //left_search = Util.binaryIndexOf(coords, box.x, if @plotLine then 'centre' else 'x')

    //if coords[left_search.idx - 1]? and within_box(coords[left_search.idx - 1])
    //  start_idx = left_search.idx - 1
    //else if within_box(coords[left_search.idx])
    //  start_idx = left_search.idx
    //else if coords[left_search.idx + 1]? and within_box(coords[left_search.idx + 1])
    //  start_idx = left_search.idx + 1
    //else
    //  return { activeSelection: false, selection: selection, count: 0 }

    //right_search = Util.binaryIndexOf(coords, box.right, if @plotLine then 'centre' else 'x')

    //if coords[right_search.idx + 1]? and within_box(coords[right_search.idx + 1])
    //  end_idx = right_search.idx + 1
    //else if within_box(coords[right_search.idx])
    //  end_idx = right_search.idx
    //else if coords[right_search.idx - 1]? and within_box(coords[right_search.idx - 1])
    //  end_idx = right_search.idx - 1
    //console.log start_idx, end_idx, right_search, (if coords[right_search.idx + 1]? then within_box(coords[right_search.idx + 1]) else '+1 undefined'), (if coords[right_search.idx - 1]? then within_box(coords[right_search.idx - 1]) else '-1 undefined')
    //console.log box.right, right_search unless end_idx?
    //idx = start_idx
    //while idx <= end_idx
    //  device = coords[idx].datum.instances[0]
    //  selection[device.componentClassName][device.id ? device.itemId] = true
    //  ++idx

    //return { activeSelection: true, selection: selection, count: end_idx - start_idx + 1 }

    for (let idx = 0; idx < coords.length; idx++) {
      var coord = coords[idx];
      var x_coord = get_co(coord);
      if ((x_coord >= box_left) && (x_coord <= box_right)) {
        var datum = this.data[idx];

        // a datum won't necessarily have an associated device, in the case of a VM
        //
        // We no longer have VMs.  I have no idea if we still need this section
        // of code.
        if ((datum.instances != null) && (datum.instances.length > 0)) {
          var device = datum.instances[0];
          selection[device.componentClassName][device.id != null ? device.id : device.itemId] = true;
          active_selection = true;
        }

        ++count;
      }
    }

    return { activeSelection: active_selection, selection, count };
  }


  selectWithinBox(box) {
    const selected = this.getSelection(box);
    this.modelRefs.activeSelection(selected.activeSelection);
    return this.modelRefs.selectedDevices(selected.selection);
  }


  startDrag(x, y) {
    // overlay a canvas where the selection box will be drawn
    this.fx = new SimpleRenderer(this.containerEl, this.cvs.width, this.cvs.height, 1, LBC.FPS);
    Util.setStyle(this.fx.cvs, 'position', 'absolute');
    Util.setStyle(this.fx.cvs, 'left', 0);
    Util.setStyle(this.fx.cvs, 'top', 0);
    this.boxAnchor = { x, y };

    // create box shape
    this.box = this.fx.addRect({
      x,
      y,
      stroke      : LBC.SELECT_BOX_STROKE,
      strokeWidth : LBC.SELECT_BOX_STROKE_WIDTH,
      alpha       : LBC.SELECT_BOX_ALPHA,
      width       : 1,
      height      : 1});

    // create label
    return this.selCount = this.fx.addText({
      x       : x + LBC.SELECT_COUNT_OFFSET_X,
      y       : y + LBC.SELECT_COUNT_OFFSET_Y,
      fill    : LBC.SELECT_COUNT_FILL,
      bgFill  : LBC.SELECT_COUNT_BG_FILL,
      bgAlpha : LBC.SELECT_COUNT_BG_ALPHA,
      font    : LBC.SELECT_COUNT_FONT,
      padding : LBC.SELECT_COUNT_PADDING,
      caption : ''});
  }


  drag(x, y) {
    this.dragBox(x, y);
    const box = {
      x      : this.fx.getAttribute(this.box, 'x'),
      y      : this.fx.getAttribute(this.box, 'y'),
      width  : this.fx.getAttribute(this.box, 'width'),
      height : this.fx.getAttribute(this.box, 'height')
    };

    box.left   = box.x;
    box.top    = box.y;
    box.right  = box.left + box.width;
    box.bottom = box.top + box.height;

    // update selection count
    return this.fx.setAttributes(this.selCount, {
      caption : LBC.SELECT_COUNT_CAPTION.replace(/\[\[selection_count\]\]/g, this.getSelection(box).count),
      x       : box.x + LBC.SELECT_COUNT_OFFSET_X,
      y       : box.y + LBC.SELECT_COUNT_OFFSET_Y
    });
  }


  stopDrag(x, y) {
    this.fx.destroy();
  
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
    return this.selectWithinBox(box);
  }


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


  // creates posLookup object which uses [device_type + id] as the key and pos idx as the value, for sorting by physical position
  makePositionLookup() {
    const componentClassNames = this.modelRefs.componentClassNames();
    this.posLookup        = {};
    for (let className of Array.from(componentClassNames)) { this.posLookup[className] = {}; }

    const racks   = this.modelRefs.racks();
    let u_count = 0;
    return (() => {
      const result = [];
      for (var rack of Array.from(racks)) {
        this.posLookup.racks[rack.id] = u_count;
        if (rack.chassis == null) { continue; }
        for (var chassis of Array.from(rack.chassis)) {
          var pos = chassis.uStart + u_count;
          this.posLookup.chassis[chassis.id] = pos;
          for (var slot of Array.from(chassis.Slots)) {
            if (slot.Machine != null) { this.posLookup.devices[slot.Machine.id] = pos; }
          }
        }
        result.push(u_count += rack.uHeight);
      }
      return result;
    })();
  }


  evShowHint(datum) {
    this.over = true;
    this.model.overLBC(true);
    if ((datum.instances != null) && (this.modelRefs.highlighted() !== datum.instances)) { return this.modelRefs.highlighted(datum.instances); }
  }


  evHideHint() {
    this.over = false;
    this.model.overLBC(false);
    return this.modelRefs.highlighted([]);
  }
};
LBC.initClass();
export default LBC;
