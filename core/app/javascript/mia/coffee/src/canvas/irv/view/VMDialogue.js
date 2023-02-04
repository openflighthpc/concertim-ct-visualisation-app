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

import LBC from 'canvas/common/widgets/LBC';
import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import Breacher from 'canvas/irv/view/Breacher';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';

class VMDialogue extends LBC {
  static initClass() {
    // statics overwitten by config
    this.WIDTH           = 0.5;
    this.HEIGHT          = 0.5;
    this.NO_METRICS_MSG  = 'Please select a metric to view virtual machines';
    this.MSG_FILL        = '#000000';
    this.MSG_FONT        = '14px Verdana';
  }


  constructor(vhGroupId, dialogueContainerEl, model) {
    this.close = this.close.bind(this);
    this.evShowChart = this.evShowChart.bind(this);
    this.setSubscriptions = this.setSubscriptions.bind(this);
    this.update = this.update.bind(this);
    this.updateBreaches = this.updateBreaches.bind(this);
    this.splitTextIntoLines = this.splitTextIntoLines.bind(this);
    this.vhGroupId = vhGroupId;
    this.dialogueContainerEl = dialogueContainerEl;
    this.model = model;
    this.dialogueEl           = document.createElement('div');
    this.dialogueEl.id        = 'vm_dialogue';
    this.dialogueEl.innerHTML = '<div id="vm_title">Showing virtual host ' + this.model.deviceLookup().devices[this.vhGroupId].name + '<a id="close_btn"><div style="float:right;width:10px;height=10px;background:red;color:white;">X</div></a></div><div id="vm_chart_container"><div id="chart_tooltip" style="z-index:9999999;" style="padding:40px;" class="tooltip"></div></div>';

    this.dialogueContainerEl.appendChild(this.dialogueEl);
    Util.setStyle(this.dialogueEl, 'position', 'absolute');
    this.chartEl = $('vm_chart_container');

    Events.addEventListener(this.dialogueEl, 'click', this.muteEvent);
    Events.addEventListener(this.dialogueEl, 'dblclick', this.muteEvent);
    Events.addEventListener($('close_btn'), 'click', this.close);

    this.breachSub = this.model.breaches.subscribe(this.updateBreaches);
    this.breachers = [];

    this.gfx = new SimpleRenderer(this.chartEl, 1, 1);
    Util.setStyle(this.gfx.cvs, 'z-index', 999999);
    Util.setStyle(this.gfx.cvs, 'pointer-events', 'none');

    super(this.chartEl, this.model, 'vm_chart');

    this.updateBreaches(this.model.breaches());
    this.setLayout();
  }


  close() {
    this.cvs.width = this.cvs.width + 1;
    Events.dispatchEvent(this.dialogueEl, 'vmdialogueclose');
    return this.destroy();
  }
  

  destroy() {
    this.breachSub.dispose();
    (this.dialogueEl.parentElement != null ? this.dialogueEl.parentElement : this.dialogueEl.parentNode).removeChild(this.dialogueEl);
    return super.destroy();
  }


  updateLayout() {
    this.setLayout();
    return super.updateLayout();
  }


  muteEvent(ev) {
    ev.stopPropagation();
    return ev.preventDefault();
  }


  // override super class evShowChart, force alsways visible
  evShowChart() {
    return super.evShowChart(true);
  }

  //override super class setSubscriptions, force always visible
  setSubscriptions(visible) {
    if (visible == null) { visible = true; }
    return super.setSubscriptions(true);  
  }

  // override super class update. Adds mean average line to drawn chart
  update() {
    super.update();

    // no metrics to display, show message
    if ((this.data == null) || !(this.data.length > 0)) {
      this.ctx.clearRect(0, 0, this.cvs.width, this.cvs.height);
      const lines = this.splitTextIntoLines(VMDialogue.NO_METRICS_MSG, VMDialogue.MSG_FONT, this.cvs.width - 20);
      this.ctx.textAlign = 'center';
      this.ctx.fillStyle = VMDialogue.MSG_FILL;
      this.ctx.font      = VMDialogue.MSG_FONT;
      this.ctx.beginPath();
      for (let idx = 0; idx < lines.length; idx++) { var line = lines[idx]; this.ctx.fillText(line, this.cvs.width / 2, (this.cvs.height / 2) + (idx * 20)); }

      return;
    }

    if ((this.data.length === 0) || (this.chart == null)) { return; }

    this.chart.tooltip = $('chart_tooltip');
    const col_map = this.modelRefs.colourMaps()[this.modelRefs.selectedMetric()];
    let colour  = this.getColour((this.mean - col_map.low) / (col_map.high - col_map.low)).toString(16);
    while (colour.length < 6) { colour  = '0' + colour; }

    // @chart.drawBGLine(@mean, colour)
    const labelPos = this.modelRefs.graphOrder() === "ascending" ? "left" : "right";
    this.chart.drawBGLineWithLabel("Av", labelPos, this.mean, colour);
    return this.updateBreaches(this.model.breaches());
  }


  // override
  getDataSet(inclusion_filter) {
    let group;
    const data             = [];
    const groups           = this.model.groups();
    const included         = {};
    for (group of Array.from(groups)) { included[group]  = {}; }
    const metric_data      = this.model.metricData();
    const vms              = this.model.deviceLookup().byGroup[this.vhGroupId];
    const device_lookup    = this.model.deviceLookup();

    const col_map  = this.model.colourMaps()[this.model.selectedMetric()];
    const col_high = col_map.high;
    const col_low  = col_map.low;
    const range    = col_high - col_low;
    let total    = 0;
    let count    = 0;

    for (var id in metric_data.values.vms) {

      var metric = metric_data.values.vms[id];
      ++count;
      total += Number(metric);
      var temp   = (metric - col_low) / range;
      var col    = this.getColour(temp).toString(16);
      while (col.length < 6) { col    = '0' + col; }

      included.vms[id] = true;
    
      data.push({
        name      : device_lookup.vms[id].name,
        id,
        group     : 'vms',
        pos       : 0,
        metric,
        numMetric : Number(metric),
        colour    : '#' + col,
        instances : null
      });
    }

    this.mean = total / count;

    return { data, sampleSize: count, included };
  }
  

  setLayout() {
    const dims = this.dialogueContainerEl.getCoordinates();

    const dialogue_width  = dims.width * VMDialogue.WIDTH;
    const dialogue_height = dims.height * VMDialogue.HEIGHT;

    Util.setStyle(this.chartEl, 'height', (dialogue_height - 20) + 'px');
    Util.setStyle(this.dialogueEl, 'left', ((dims.width - dialogue_width) / 2) + 'px');
    Util.setStyle(this.dialogueEl, 'top', ((dims.height - dialogue_height) / 2) + 'px');
    Util.setStyle(this.dialogueEl, 'width', dialogue_width + 'px');
    Util.setStyle(this.dialogueEl, 'height', dialogue_height + 'px');

    if (this.cvs != null) {
      Util.setStyle(this.gfx.cvs, 'position', 'absolute');
      Util.setStyle(this.gfx.cvs, 'left', Util.getStyle(this.cvs, 'left'));
      Util.setStyle(this.gfx.cvs, 'top', Util.getStyle(this.cvs, 'top'));
      return this.gfx.setDims(this.cvs.width, this.cvs.height);
    }
  }


  updateBreaches(breaches) {
    for (var breacher of Array.from(this.breachers)) { breacher.destroy(); }
    this.breachers = [];

    if ((this.included == null) || (this.chart == null) || (this.chart.coords == null) || (breaches.devices == null)) { return; }

    return (() => {
      const result = [];
      for (var id in this.included.vms) {
        if (breaches.vms[id]) {
          var datum = this.chart.coords[this.idxById.vms[id]];
          result.push(this.breachers.push(new Breacher('devices', id, this.gfx, datum.x, datum.y, datum.width, datum.height, this.model, false)));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }


  splitTextIntoLines(text, font, width) {
    const init_font = this.ctx.font;
    this.ctx.font = font;

    const parts = text.split(' ');
    const lines = [];

    let idx = 0;
    const len = parts.length;
    while (idx < len) {
      var line = parts[idx];
      ++idx;

      while ((this.ctx.measureText(line + ' ' + parts[idx]).width < width) && (idx < len)) {
        line += ' ' + parts[idx];
        ++idx;
      }

      lines.push(line);
    }

    this.ctx.font = init_font;

    return lines;
  }
};
VMDialogue.initClass();
export default VMDialogue;
