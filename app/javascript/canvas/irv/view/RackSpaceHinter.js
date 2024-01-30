import Chassis from 'canvas/irv/view/Chassis';
import Hint from 'canvas/irv/view/Hint';
import ImageLink from 'canvas/irv/view/ImageLink';
import Link from 'canvas/irv/view/Link';
import Machine from 'canvas/irv/view/Machine';
import Rack from 'canvas/irv/view/Rack';
import Util from 'canvas/common/util/Util';

class RackCaptionBuilder {
    constructor(rack) {
        this.captionTemplate = RackSpaceHinter.RACK_TEXT;
        this.rack = rack;
    }

    build(metric, _metricTemplate) {
        let caption = this.captionTemplate;
        caption = Util.substitutePhrase(caption, 'name', this.rack.name);
        caption = Util.substitutePhrase(caption, 'u_height', this.rack.uHeight);
        caption = Util.substitutePhrase(caption, 'url', this.rack.template.url);
        caption = Util.substitutePhrase(caption, 'metric_min', metric.min);
        caption = Util.substitutePhrase(caption, 'metric_max', metric.max);
        caption = Util.substitutePhrase(caption, 'metric_mean', metric.mean);
        caption = Util.substitutePhrase(caption, 'metric_total', metric.total);
        caption = Util.substitutePhrase(caption, 'metric_value', metric.value);
        caption = Util.substitutePhrase(caption, 'buildStatus', this.rack.buildStatus);
        caption = Util.substitutePhrase(caption, 'cost', this.rack.cost);

        caption = Util.cleanUpSubstitutions(caption);

        return caption;
    }
}

class ChassisCaptionBuilder {
    constructor(chassis) {
        this.captionTemplate = RackSpaceHinter.CHASSIS_TEXT;
        this.chassis = chassis;
    }

    build(metric, metricTemplate) {
        const chassis = this.chassis;
        const metricPresent = metric.min || metric.max || metric.mean || metric.total || metric.value;
        const metricName = (metricTemplate.name && metricPresent) ? metricTemplate.name : null;

        let caption = this.captionTemplate;
        caption = Util.substitutePhrase(caption, 'name', chassis.name);
        caption = Util.substitutePhrase(caption, 'parent_name', this.parentName());
        caption = Util.substitutePhrase(caption, 'metric_name', metricName);
        caption = Util.substitutePhrase(caption, 'u_height', chassis.uHeight);
        caption = Util.substitutePhrase(caption, 'num_rows', chassis.complex ? chassis.template.rows : null);
        caption = Util.substitutePhrase(caption, 'slots_per_row', chassis.complex ? chassis.template.columns : null);
        caption = Util.substitutePhrase(caption, 'u_position', this.position());
        caption = Util.substitutePhrase(caption, 'slots_available', chassis.complex ? (chassis.template.rows * chassis.template.columns) - chassis.children.length : null);
        caption = Util.substitutePhrase(caption, 'metric_min', metric.min);
        caption = Util.substitutePhrase(caption, 'metric_max', metric.max);
        caption = Util.substitutePhrase(caption, 'metric_mean', metric.mean);
        caption = Util.substitutePhrase(caption, 'metric_total', metric.total);
        caption = Util.substitutePhrase(caption, 'metric_value', metric.value);

        caption = Util.cleanUpSubstitutions(caption);

        return caption;
    }

    parentName() {
        return this.chassis.parent() instanceof Rack ? this.chassis.parent().name : null;
    }

    position() {
        const chassis = this.chassis;
        if (chassis.parent() instanceof Rack) {
            if (chassis.uHeight > 1) {
                const uStart = chassis.uStart() + 1;
                const uEnd = chassis.uStart() + chassis.uHeight;
                return `${uStart}U-${uEnd}U`;
            } else {
                return (chassis.uStart() + 1) + 'U';
            }
        } else {
            return null;
        }
    }
}

class MachineCaptionBuilder {
    constructor(device) {
        this.captionTemplate = RackSpaceHinter.DEVICE_TEXT;
        this.device = device;
    }

    build(metric, metricTemplate) {
        const device = this.device;
        let caption = this.captionTemplate;
        caption = Util.substitutePhrase(caption, 'name', device.name);
        caption = Util.substitutePhrase(caption, 'parent_name', this.parentName());
        caption = Util.substitutePhrase(caption, 'rack_name', this.rackName());
        caption = Util.substitutePhrase(caption, 'metric_name', metricTemplate.name);
        caption = Util.substitutePhrase(caption, 'position', this.position());
        caption = Util.substitutePhrase(caption, 'u_height', this.uHeight());
        caption = Util.substitutePhrase(caption, 'metric_min', metric.min);
        caption = Util.substitutePhrase(caption, 'metric_max', metric.max);
        caption = Util.substitutePhrase(caption, 'metric_mean', metric.mean);
        caption = Util.substitutePhrase(caption, 'metric_total', metric.total);
        caption = Util.substitutePhrase(caption, 'metric_value', metric.value);
        caption = Util.substitutePhrase(caption, 'buildStatus', device.buildStatus);
        caption = Util.substitutePhrase(caption, 'cost', device.cost);

        caption = Util.cleanUpSubstitutions(caption);

        return caption;
    }

    parentName() {
        if (this.device.parent().complex) {
            return this.device.parent().name;
        } else {
            return null;
        }
    }

    rackName() {
        if (this.isInRack()) {
            return this.chassisCaptionBuilder().parentName();
        } else {
            return null;
        }
    }

    uHeight() {
        if (this.device.parent().complex) {
            return null;
        } else {
            return this.device.parent().uHeight;
        }
    }

    position() {
        const device = this.device;
        if (device.parent().complex) {
            return `column: ${device.column + 1}, row: ${device.row + 1}`;
        } else if (this.isInRack()) {
            return this.chassisCaptionBuilder().position();
        } else {
            return null;
        }
    }

    isInRack() {
        return this.device.parent().parent() instanceof Rack;
    }

    chassisCaptionBuilder() {
        const chassis = this.device.parent();
        return new ChassisCaptionBuilder(chassis);
    }
}

// RackSpaceHinter manages a mouse hover tooltip for the interactive rack view
// page.
//
// Currently it supports tooltips for racks, chassis and devices (aka machines).
class RackSpaceHinter {
    static RACK_TEXT = '<span>Rack: [[name]]</span>';
    static CHASSIS_TEXT = '<span>Chassis: [[name]]</span>';
    static DEVICE_TEXT = '<span>Device: [[name]]</span>';

    constructor(containerEl, model) {
        this.hint = new Hint(containerEl, model);
        this.model = model;
    }


    // show displays a hint for the given device at the given coordinates. This
    // grabs all relevant values from the device and substitutes them in to the
    // hint text
    show(device, x, y) {
        // ignore blades if viewing chassis level metrics
        if (device.pluggable && (this.model.metricLevel() === 'chassis')) { device = device.parent(); }
        if (device instanceof ImageLink || device instanceof Link) { device = device.parent(); }

        const captionBuilder = this.captionBuilder(device); 
        const caption = captionBuilder.build(this.formattedMetric(device), this.metricTemplate());

        this.hint.showMessage(caption, x, y);
    }

    hide() {
        this.hint.hide();
    }

    captionBuilder(device) {
        if (device instanceof Rack) {
            return new RackCaptionBuilder(device);
        } else if (device instanceof Chassis) {
            return new ChassisCaptionBuilder(device);
        } else {
            return new MachineCaptionBuilder(device);
        }
    }

    metricTemplate() {
        const metrics = this.model.metricData();
        if (this.model.metricTemplates()[metrics.metricId] == null) {
            return {};
        } else {
            return this.model.metricTemplates()[metrics.metricId];
        }
    }

    formattedMetric(device) {
        const metrics = this.model.metricData();
        const metricTemplate = this.metricTemplate();
        let metricValue = (metrics.values[device.componentClassName] != null) ? metrics.values[device.componentClassName][device.id] : null;
        const formattedMetric = {}
        if ((typeof metricValue === 'object') && (metricValue !== null)) {
            if (metricValue.min != null)  { formattedMetric.min   = metricTemplate.format.replace(/%s/, metricValue.min); }
            if (metricValue.max != null)  { formattedMetric.max   = metricTemplate.format.replace(/%s/, metricValue.max); }
            if (metricValue.mean != null) { formattedMetric.mean  = metricTemplate.format.replace(/%s/, metricValue.mean); }
            if (metricValue.sum != null)  { formattedMetric.total = metricTemplate.format.replace(/%s/, metricValue.sum); }
        } else if (metricValue != null) {
            formattedMetric.value = metricTemplate.format.replace(/%s/, metricValue);
        }
        return formattedMetric;
    }
};

export default RackSpaceHinter;
