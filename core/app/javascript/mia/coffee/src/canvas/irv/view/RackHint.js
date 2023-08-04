/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Hint from 'canvas/irv/view/Hint';
import  Rack from 'canvas/irv/view/Rack';
import  Chassis from 'canvas/irv/view/Chassis';
import  Machine from 'canvas/irv/view/Machine';
import  Events from 'canvas/common/util/Events';
import  Util from 'canvas/common/util/Util';

class RackHint extends Hint {
  static initClass() {

    // statics overwritten by config
    this.RACK_TEXT        = '<span style="font-weight: 700">Rack: [[name]]</span><br><ul style="list-style-type: none;"><li>Height: [[u_height]]U</ul>';
    this.CHASSIS_TEXT     = '<span style="font-weight: 700">Chassis: [[name]]</span><br><ul style="list-style-type: none;"><li>[[parent_name]]<li>[[metric_name]]<li>[[metric_value]]<li>[[u_height]]<li>[[num_rows]]<li>[[slots_per_row]]<li>[[u_position]]<li>[[slots_avaliable]]</ul>';
    this.DEVICE_TEXT      = '<span style="font-weight: 700">Device: [[name]]</span><br><ul style="list-style-type: none;"><li>';
    this.NO_METRIC        = 'No metric data available';
    this.MORE_INFO_DELAY  = 1000;
  }


  constructor(container_el, model) {
    super(container_el, model);
    this.getMore = this.getMore.bind(this);
    this.appendData = this.appendData.bind(this);
  }


  // displays a hint for a given device, this grabs all relevant values from the device and substitutes them in to the hint text
  // @param  device  the device to query
  // @param  x       the x coordinate where the hint should be located
  // @param  y       the y coordinate where the hint should be located
  show(device, x, y) {
    let caption, metric_max, metric_mean, metric_min, metric_total, position;
    const metrics         = this.model.metricData();
    const metric_template = (this.model.metricTemplates()[metrics.metricId] != null) ? this.model.metricTemplates()[metrics.metricId] : {};
    let metric_value    = (metrics.values[device.group] != null) ? metrics.values[device.group][device.id] : null;

    if ((typeof metric_value === 'object') && (metric_value !== null)) {
      if (metric_value.min != null) { metric_min   = metric_template.format.replace(/%s/, metric_value.min); }
      if (metric_value.max != null) { metric_max   = metric_template.format.replace(/%s/, metric_value.max); }
      if (metric_value.mean != null) { metric_mean  = metric_template.format.replace(/%s/, metric_value.mean); }
      if (metric_value.sum != null) { metric_total = metric_template.format.replace(/%s/, metric_value.sum); }
      metric_value = null;
    } else if (metric_value != null) {
      metric_value = metric_template.format.replace(/%s/, metric_value);
    }

    if (device instanceof Rack) {
      caption = RackHint.RACK_TEXT;
      caption = Util.substitutePhrase(caption, 'name', device.name);
      caption = Util.substitutePhrase(caption, 'u_height', device.uHeight);
      caption = Util.substitutePhrase(caption, 'url', device.template.url);
      caption = Util.substitutePhrase(caption, 'metric_min', metric_min);
      caption = Util.substitutePhrase(caption, 'metric_max', metric_max);
      caption = Util.substitutePhrase(caption, 'metric_mean', metric_mean);
      caption = Util.substitutePhrase(caption, 'metric_total', metric_total);
      caption = Util.substitutePhrase(caption, 'metric_value', metric_value);
      caption = Util.substitutePhrase(caption, 'buildStatus', device.buildStatus);
      caption = Util.substitutePhrase(caption, 'cost', device.cost);

      caption = Util.cleanUpSubstitutions(caption);
    } else if (device instanceof Chassis) {
      const metric_name = (metric_template.name && (metric_min || metric_max || metric_mean || metric_total || metric_value)) ? metric_template.name : null;
      caption = RackHint.CHASSIS_TEXT;
      caption = Util.substitutePhrase(caption, 'name', device.name);
      caption = Util.substitutePhrase(caption, 'parent_name', device.parent() instanceof Rack ? device.parent().name : null);
      caption = Util.substitutePhrase(caption, 'metric_name', metric_name);
      caption = Util.substitutePhrase(caption, 'u_height', device.uHeight);
      caption = Util.substitutePhrase(caption, 'num_rows', device.complex ? device.template.rows : null);
      caption = Util.substitutePhrase(caption, 'slots_per_row', device.complex ? device.template.columns : null);
      position = device.parent() instanceof Rack ? (device.uHeight > 1 ? `${(device.uStart() + 1)}U-${(device.uStart() + device.uHeight)}U` : (device.uStart() + 1) + 'U') : null;
      caption = Util.substitutePhrase(caption, 'u_position', position);
      caption = Util.substitutePhrase(caption, 'slots_available', device.complex ? (device.template.rows * device.template.columns) - device.children.length : null);
      caption = Util.substitutePhrase(caption, 'metric_min', metric_min);
      caption = Util.substitutePhrase(caption, 'metric_max', metric_max);
      caption = Util.substitutePhrase(caption, 'metric_mean', metric_mean);
      caption = Util.substitutePhrase(caption, 'metric_total', metric_total);
      caption = Util.substitutePhrase(caption, 'metric_value', metric_value);

      caption = Util.cleanUpSubstitutions(caption);
    } else {
      let parent_name, u_height;
      caption = RackHint.DEVICE_TEXT;
      position = null;

      if (device.parent().complex) {
        parent_name = device.parent().name;
        u_height    = null;
        position    = `column: ${device.column + 1}, row: ${device.row + 1}`;
      } else {
        parent_name = null;
        u_height    = device.parent().uHeight;
        if (device.parent().parent() instanceof Rack) {
          position    = device.parent().uHeight > 1 ? `${(device.parent().uStart() + 1)}U-${(device.parent().uStart() + device.parent().uHeight)}U` : (device.parent().uStart() + 1) + 'U';
        }
      }

      caption = Util.substitutePhrase(caption, 'name', device.name);
      caption = Util.substitutePhrase(caption, 'parent_name', parent_name);
      caption = Util.substitutePhrase(caption, 'rack_name', device.parent().parent() instanceof Rack ? device.parent().parent().name : null);
      caption = Util.substitutePhrase(caption, 'metric_name', metric_template.name);
      caption = Util.substitutePhrase(caption, 'position', position);
      caption = Util.substitutePhrase(caption, 'u_height', u_height);
      caption = Util.substitutePhrase(caption, 'metric_min', metric_min);
      caption = Util.substitutePhrase(caption, 'metric_max', metric_max);
      caption = Util.substitutePhrase(caption, 'metric_mean', metric_mean);
      caption = Util.substitutePhrase(caption, 'metric_total', metric_total);
      caption = Util.substitutePhrase(caption, 'metric_value', metric_value);
      caption = Util.substitutePhrase(caption, 'buildStatus', device.buildStatus);
      caption = Util.substitutePhrase(caption, 'cost', device.cost);

      caption = Util.cleanUpSubstitutions(caption);
    }

    this.device  = device;
    this.moreTmr = setTimeout(this.getMore, RackHint.MORE_INFO_DELAY);
    return super.show(caption, x, y);
  }


  hide() {
    super.hide();
    return clearTimeout(this.moreTmr);
  }


  getMore() {
    return Events.dispatchEvent(this.hintEl, 'getHintInfo');
  }


  appendData(data) {
    if (this.visible) {
      const append = this.buildAppend(data, 0);
      this.hintEl.innerHTML += append;
      return this.refreshPosition();
    }
  }

  buildAppend(data, indent) {
    let append = '';
    for (const [key, value] of Object.entries(data)) {
      if (value == null || value === "") {
        continue;
      } else if (typeof value === "object" && !Array.isArray(value)) {
        append += `<strong>${key}:</strong><br>`;
        append += this.buildAppend(value, indent+1);
      } else {
        append += `<span style="padding-left: ${indent * 10}px">${key}: ${value}</span><br>`;
      }
    }
    return append;
  }
};
RackHint.initClass();
export default RackHint;
