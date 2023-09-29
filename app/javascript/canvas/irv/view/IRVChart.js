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
import ViewModel from 'canvas/irv/ViewModel';

class IRVChart extends LBC {
  constructor(...args) {
    super(...args);
    // this.setSubscriptions = this.setSubscriptions.bind(this);
    // this.evShowHint = this.evShowHint.bind(this);
    // this.evHideHint = this.evHideHint.bind(this);
    // this.applySeriesFadeDefault = this.applySeriesFadeDefault.bind(this);
    // this.applySeriesFadeSortMin = this.applySeriesFadeSortMin.bind(this);
    // this.applySeriesFadeSortMean = this.applySeriesFadeSortMean.bind(this);
  }

  static initClass() {
    // statics overwritten by config
    this.SERIES_FADE_ALPHA  = 0.3;
  }


  setSubscriptions(visible) {
    if (visible == null) { visible = this.modelRefs.showChart(); }
    super.setSubscriptions();

    if (visible) {
      this.subscriptions.push(this.modelRefs.metricLevel.subscribe(this.update));
      this.subscriptions.push(this.modelRefs.racks.subscribe(this.makePositionLookup));

      return this.makePositionLookup();
    }
  }


  hexToRGBA(hex) {
    return `rgba(${Number('0x' + hex.substr(1, 2))},${Number('0x' + hex.substr(3, 2))},${Number('0x' + hex.substr(5, 2))},${IRVChart.SERIES_FADE_ALPHA})`;
  }


  // Override
  evShowHint(datum) {
    this.datum = datum;
    this.over = true;
    this.model.overLBC(true);
    if (this.datum.instances != null) {
      return (() => {
        const result = [];
        for (var instance of Array.from(this.datum.instances)) {
          if (instance.viewableDevice() || (this.model.faceBoth() === false)) { result.push(instance.select()); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }
  }


  // Override
  evHideHint() {
    this.over = false;
    this.model.overLBC(false);
    if (this.datum.instances != null) {
      return Array.from(this.datum.instances).map((instance) =>
        instance.deselect());
    }
  }

  // Override
  getDataSet(inclusion_filter) {

    let colours, device, id, metric, name, series, values;
    const data             = [];
    const metric_data      = this.modelRefs.metricData();
    const metric_templates = this.modelRefs.metricTemplates();
    const metric_template  = metric_templates[metric_data.metricId];
    const selected_metric  = this.modelRefs.selectedMetric();
    const device_lookup    = this.modelRefs.deviceLookup();
    const componentClassNames = this.modelRefs.componentClassNames();
    let metric_level     = this.modelRefs.metricLevel();
    const included         = {};
    for (let className of Array.from(componentClassNames)) { included[className]  = {}; }

    const col_map  = this.modelRefs.colourMaps()[metric_data.metricId];
    const col_high = col_map.high;
    const col_low  = col_map.low;
    const range    = col_high - col_low;

    let sample_count = 0;

    // extract subset of all metrics according to display settings
    const classNamesToConsider = metric_level === ViewModel.METRIC_LEVEL_ALL ? componentClassNames : [ metric_level ];

    //values  = metric_data.values[metric_level]
    series  = [ 'numMetric' ];
    colours = [ 'colour' ];

    for (let className of Array.from(classNamesToConsider)) {

      let classValues = metric_data.values[className];

      for (id in classValues) {
        metric = classValues[id];
        ++sample_count;
        if (inclusion_filter(className, id)) {
          device = device_lookup[className][id];

          if (device == null) { continue; }

          included[className][id] = true;

          var temp = (metric - col_low) / range;
          var col  = this.getColour(temp).toString(16);
          while (col.length < 6) { col  = '0' + col; }
          name = (device.name != null ? device.name : id);
        
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

    return { data, series, colours, sampleSize: sample_count, included };
  }


  applySeriesFadeDefault(min, max, mean) {
    return { min, max, mean };
  }


  applySeriesFadeSortMin(min, max, mean) {
    return { min, max: this.hexToRGBA(max), mean: this.hexToRGBA(mean) };
  }


  applySeriesFadeSortMean(min, max, mean) {
    return { min, max: this.hexToRGBA(max), mean };
  }
};
IRVChart.initClass();
export default IRVChart;
