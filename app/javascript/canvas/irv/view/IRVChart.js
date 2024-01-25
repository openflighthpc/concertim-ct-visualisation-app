import LBC from 'canvas/common/widgets/LBC';
import ViewModel from 'canvas/irv/ViewModel';

// IRVChart renders the metric chart at the bottom of the interactive rack view.
//
// It extends LBC and adds functionality specific to the IRV.  E.g.,
// subscribing to changes to the racks data structure, overriding the mouse
// hover hint, IRV specific filtering.
class IRVChart extends LBC {
    // statics overwritten by config
    static SERIES_FADE_ALPHA = 0.3;

    setSubscriptions(visible) {
        if (visible == null) { visible = this.modelRefs.showChart(); }
        super.setSubscriptions(visible);

        if (visible) {
            this.subscriptions.push(this.modelRefs.metricLevel.subscribe(this.update));
            this.subscriptions.push(this.modelRefs.racks.subscribe(this.makePositionLookup.bind(this)));
        }
    }

    // Override
    evShowHint(datum) {
        this.datum = datum;
        this.over = true;
        this.model.overLBC(true);
        if (this.datum.instances != null) {
            for (var instance of Array.from(this.datum.instances)) {
                if (instance.viewableDevice() || (this.model.faceBoth() === false)) {
                    instance.select();
                }
            }
        }
    }

    // Override
    evHideHint() {
        this.over = false;
        this.model.overLBC(false);
        if (this.datum.instances != null) {
            Array.from(this.datum.instances).forEach(instance => instance.deselect());
        }
    }

    // Overridden to respect the view model's metricLevel.
    componentClassNamesToConsider() {
        const componentClassNames = this.modelRefs.componentClassNames();
        const metricLevel = this.modelRefs.metricLevel();
        return metricLevel === ViewModel.METRIC_LEVEL_ALL ? componentClassNames : [ metricLevel ];
    }

    // Overridden to reject unknown devices.
    inclusionFunction() {
        const orig = super.inclusionFunction()
        const deviceLookup = this.modelRefs.deviceLookup();

        return (componentClassName, id) => {
            let include = orig(componentClassName, id);
            return include && deviceLookup[componentClassName][id] != null;
        }
    }

    // makePositionLookup populates this.posLookup object which is used for
    // sorting by physical position.
    //
    // this.posLookup is a 2 dimensional hash.  The first key is the
    // component's type (e.g., 'rack' or 'device') and the second is its id.
    makePositionLookup() {
        const componentClassNames = this.modelRefs.componentClassNames();
        this.posLookup = {};
        for (let className of componentClassNames) { this.posLookup[className] = {}; }

        const racks = this.modelRefs.racks();
        let uCount = 0;
        for (let rack of racks) {
            this.posLookup.racks[rack.id] = uCount;
            if (rack.chassis == null) { continue; }
            for (let chassis of rack.chassis) {
                const pos = chassis.uStart + uCount;
                this.posLookup.chassis[chassis.id] = pos;
                for (let slot of chassis.Slots) {
                    if (slot.Machine != null) {
                        this.posLookup.devices[slot.Machine.id] = pos;
                    }
                }
            }
            uCount += rack.uHeight;
        }
    }
};

export default IRVChart;
