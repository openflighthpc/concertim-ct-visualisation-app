/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import MultiMetric from 'canvas/common/widgets/MultiMetric';

class VHMetric extends MultiMetric {

  // overrides default multi-metric getValue routine. Ignore 'total' property and generates a sorted array from min, max and mean
  // @param  val   an object containing virtual host metrics
  // @return       a sorted list of virtual host agreggated metrics
  getValue(val) {
    if (val == null) { return; }
    return [ val.min, val.mean, val.max ];
  }
}

export default VHMetric;
