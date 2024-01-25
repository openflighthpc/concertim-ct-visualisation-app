import Util from 'canvas/common/util/Util';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import SimpleChart from 'canvas/common/widgets/SimpleChart';

// LBC manages a chart which might either be rendered as a Line Chart or a Bar
// Chart depending on the available width and the number of data points.  Hence
// the name Line or Bar Chart (LBC).
//
// The actual rendering is delegated to a SimpleChart instance in the update
// method.
//
// This class concerns itself with
//
// * retreiving the data to render from the view model based on the current
//   view model state.  E.g., which metric has been selected, is the chart
//   being displayed, which filters are in effect.
// * updating the data being rendered as the view model state changes.  E.g.,
//   new metric data is made available, a new metric is selected.
// * updating the title of the chart as the data changes.
// * showing tooltips on mouse over.
// * highlighting the chart data for the currently highlighted device.
// * allowing further filtering of the devices via drag and drop.
class LBC {
    // statics overwritten by config
    static TITLE_CAPTION  = 'something about cats';

    static POINTER_OFFSET_X  = 10;
    static POINTER_OFFSET_Y  = 10;

    static SELECT_COUNT_OFFSET_X  = 0;
    static SELECT_COUNT_OFFSET_Y  = 0;
    static SELECT_COUNT_FILL      = '#000000';
    static SELECT_COUNT_FONT      = '12px Karla';
    static SELECT_COUNT_PADDING   = 5;
    static SELECT_COUNT_BG_ALPHA  = 0.5;
    static SELECT_COUNT_BG_FILL   = '#FF00FF';
    static SELECT_COUNT_CAPTION   = 'selected: [[selection_count]]';

    static SELECT_BOX_STROKE        = '#000000';
    static SELECT_BOX_STROKE_WIDTH  = 2;
    static SELECT_BOX_ALPHA         = 0.8;

    static BAR_CHART_MIN_DATUM_WIDTH  = 2;
    static BAR_CHART_MAX_DATUM_WIDTH  = 200;

    static FILL_SINGLE_SERIES_LINE_CHARTS  = true;

    static LINE_POINTER_COLOUR  = '#0';
    static LINE_POINTER_WIDTH   = 1;

    static MODEL_DEPENDENCIES = {
        activeFilter: 'activeFilter',
        activeSelection: 'activeSelection',
        colourMaps: 'colourMaps',
        colourScale: 'colourScale',
        componentClassNames: 'componentClassNames',
        deviceLookup: 'deviceLookup',
        filteredDevices: 'filteredDevices',
        graphOrder: 'chartSortOrder',
        highlighted: 'highlighted',
        metricData: 'metricData',
        metricLevel: 'metricLevel',
        metricTemplates: 'metricTemplates',
        racks: 'racks',
        selectedDevices: 'selectedDevices',
        selectedMetric: 'selectedMetric',
        showChart: 'showChart',
    };

    constructor(containerEl, model, canvasId) {
        this.evShowChart = this.evShowChart.bind(this);
        this.update = this.update.bind(this);
        this.highlightDatum = this.highlightDatum.bind(this);
        this.evShowHint = this.evShowHint.bind(this);
        this.evHideHint = this.evHideHint.bind(this);

        this.containerEl = containerEl;
        this.model = model;
        if (canvasId == null) { canvasId = 'lbc'; }
        this.canvasId = canvasId;
        this.pointerEl = $('pointer');
        this.heightOffset = -this.pointerEl.getCoordinates().height;
        this.over = false;

        // create model reference store
        this.modelRefs = {};
        for (var key in LBC.MODEL_DEPENDENCIES) { var value = LBC.MODEL_DEPENDENCIES[key]; this.modelRefs[key] = this.model[value]; }

        this.subscriptions = [];
        this.showChartSubscription = this.modelRefs.showChart.subscribe(this.evShowChart);
        this.makePositionLookup();
        this.setSubscriptions();

        this.cvs    = document.createElement('canvas');
        this.ctx    = this.cvs.getContext('2d');
        this.cvs.id = this.canvasId;

        this.containerEl.appendChild(this.cvs);
        this.updateLayout();
    }

    updateLayout() {
        const dims      = this.containerEl.getCoordinates();
        this.cvs.width  = dims.width;
        this.cvs.height = dims.height + this.heightOffset;

        if (this.data != null) { this.update(); }
    }

    evShowChart(visible) {
        if (visible) {
            Util.setStyle(this.containerEl, 'display', 'block');
        } else {
            this.clear();
            Util.setStyle(this.containerEl, 'display', 'none');
        }

        this.setSubscriptions(visible);
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
            if (this.modelRefs.gradientLBCMetric != null) { this.subscriptions.push(this.modelRefs.gradientLBCMetric.subscribe(this.update)); }
        } else {
            // prevent any updates happening when the chart is hidden
            this.subscriptions.forEach(sub => sub.dispose());
        }
    }

    update() {
        this.clear();

        const start = (new Date()).getTime();

        const selectedMetric = this.modelRefs.selectedMetric();
        const metricTemplate = this.modelRefs.metricTemplates()[selectedMetric];
        const metricData     = this.modelRefs.metricData();

        // ignore unrecognised metrics or redundant requests (when the metric data isn't
        // for the current metric)
        if ((metricTemplate == null) || (metricData.metricId !== selectedMetric) || (this.cvs.width === 0) || (this.cvs.height === 0)) { return; }

        const set = this.getDataSet(this.inclusionFunction());

        // duplicate the data, for stress testing only
        //tmp = set.data.slice(0)
        //count = 0
        //while(count < 12549)
        //  set.data = set.data.concat(tmp)
        //  ++count

        this.data     = set.data;
        this.included = set.included;

        if (set.data.length > 0) {
            // sort
            let minMax;
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
            const colourScale = this.modelRefs.colourScale();
            const colourMap   = this.modelRefs.colourMaps()[this.modelRefs.selectedMetric()];
            if (this.modelRefs.gradientLBCMetric()) {
                for (var colourStop of colourScale) {
                    var colourStr = colourStop.col.toString(16);
                    while (colourStr.length < 6) { colourStr = '0' + colourStr; }
                    mask.push({ colour: '#' + colourStr, pos: (colourMap.range * colourStop.pos) + colourMap.low });
                }
            }

            const datumWidth = (this.cvs.width - SimpleChart.MARGIN_LEFT - SimpleChart.MARGIN_RIGHT) / set.data.length;
            this.chart      = new SimpleChart(this.cvs, $('tooltip'));
            this.plotLine   = datumWidth < LBC.BAR_CHART_MIN_DATUM_WIDTH;

            const chartConfig = {
                xValue     : 'name',
                yValues    : set.series != null ? set.series : [ 'numMetric' ],
                colours    : set.colours != null ? set.colours : [ 'colour' ],
                colourMask : mask,
                maxDatumWidth : LBC.BAR_CHART_MAX_DATUM_WIDTH,
            };

            this.multiSeries               = chartConfig.yValues.length > 1;
            chartConfig.fillBelowLine = LBC.FILL_SINGLE_SERIES_LINE_CHARTS && !this.multiSeries;

            this.dataToRender = set.data;
            this.chartConfig = chartConfig;
            if (this.plotLine) {
                minMax = this.chart.drawLine(set.data, chartConfig);
            } else {
                minMax = this.chart.drawBar(set.data, chartConfig);
            }

            this.debug('update complete, ' + set.data.length + ' metrics plotted in ' + ((new Date()).getTime() - start) + 'ms');

            const componentClassNames = this.modelRefs.componentClassNames();
            this.idxById = {};
            for (let className of componentClassNames) { this.idxById[className] = {}; }
            for (let idx = 0; idx < set.data.length; idx++) { var datum = set.data[idx]; this.idxById[datum.className][datum.id] = idx; }

            const min = typeof minMax.min === "string" ? minMax.min : Util.formatValue(minMax.min);
            const max = typeof minMax.max === "string" ? minMax.max : Util.formatValue(minMax.max);
            const mid  = Util.formatValue((parseFloat(max) + parseFloat(min)) / 2);

            let title = unescape(LBC.TITLE_CAPTION);
            // swap in title variables
            title = Util.substitutePhrase(title, 'metric_name', metricTemplate.name);
            title = Util.substitutePhrase(title, 'num_metrics', set.data.length);
            title = Util.substitutePhrase(title, 'total_metrics', set.sampleSize);
            title = Util.substitutePhrase(title, 'max_val', max);
            title = Util.substitutePhrase(title, 'min_val', min);
            title = Util.substitutePhrase(title, 'av_val',  mid);
            title = Util.substitutePhrase(title, 'metric_units', (metricTemplate.units != null) && (metricTemplate.units !== "") ? '('+metricTemplate.units+')' : '');
            title = Util.cleanUpSubstitutions(title);

            this.title = title;
            this.chart.setTitle(title);
            this.chart.addEventListener('onshowtooltip', this.evShowHint);
            this.chart.addEventListener('onhidetooltip', this.evHideHint);
        }
    }

    // componentClassNamesToConsider returns the component class (or type)
    // names that should be considered for including in the chart.  E.g.,
    // ['rack'], or ['device', 'chassis'].
    componentClassNamesToConsider() {
        return this.modelRefs.componentClassNames();
    }

    // inclusionFunction returns a function for determining if a given
    // component should be included in the chart.
    inclusionFunction() {
        const selectedDevices = this.modelRefs.selectedDevices();
        const activeSelection = this.modelRefs.activeSelection();
        const filteredDevices = this.modelRefs.filteredDevices();
        const activeFilter    = this.modelRefs.activeFilter();

        // chose a filter based upon current view
        if (activeSelection && activeFilter) {
            return (componentClassName, id) => filteredDevices[componentClassName][id] && selectedDevices[componentClassName][id];
        } else if (activeSelection) {
            return (componentClassName, id) => selectedDevices[componentClassName][id];
        } else if (activeFilter) {
            return (componentClassName, id) => filteredDevices[componentClassName][id];
        } else {
            return (componentClassName, id) => true;
        }
    }

    // queries all metric data to return the subset defined by the current display settings.
    // Accepts an inclusion function which should return true/false to indicate if a member
    // satisfies current selection and filter settings if any. Also returns an object of the
    // included members structured by their class name and id
    getDataSet(inclusion_filter) {
        const data             = [];
        const metricData      = this.modelRefs.metricData();
        const deviceLookup    = this.modelRefs.deviceLookup();
        const included = this.model.getBlankComponentClassNamesObject();

        const colourMap  = this.modelRefs.colourMaps()[metricData.metricId];
        const colourHigh = colourMap.high;
        const colourLow  = colourMap.low;
        const range    = colourHigh - colourLow;

        const values = metricData.values;
        let sampleSize = 0;
        // extract subset of all metrics according to display settings
        for (let className of this.componentClassNamesToConsider()) {
            for (let id in values[className]) {
                ++sampleSize;
                if (inclusion_filter(className, id)) {
                    let device = deviceLookup[className][id];

                    included[className][id] = true;

                    let metric = values[className][id];
                    let temp   = (metric - colourLow) / range;
                    let colour = this.getColour(temp).toString(16);
                    while (colour.length < 6) { colour = '0' + colour; }
                    let name   = device ? (device.name != null ? device.name : id) : 'unknown';

                    data.push({
                        name,
                        id,
                        className,
                        pos       : this.posLookup[className][id],
                        metric,
                        numMetric : Number(metric),
                        colour    : '#' + colour,
                        instances : device.instances
                    });
                }
            }
        }

        const series  = [ 'numMetric' ];
        const colours = [ 'colour' ];
        return { data, sampleSize, included, series, colours };
    }

    destroy() {
        this.clear();
        this.showChartSubscription.dispose();
        this.subscriptions.forEach((sub) => sub.dispose());
    }

    clear() {
        if (this.chart != null) {
            this.chart.destroy();
            this.chart = null;
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

    // highlightDatum highlights the selected datum. It currently does this by
    // drawing a black arrow above the chart entry.
    highlightDatum() {
        const device = this.modelRefs.highlighted()[0];

        if (device == null) {
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
                ctx.stroke();
            } else {
                Util.setStyle(this.pointerEl, 'left', x + LBC.POINTER_OFFSET_X + 'px');
                Util.setStyle(this.pointerEl, 'top', y + LBC.POINTER_OFFSET_Y + 'px');
                Util.setStyle(this.pointerEl, 'visibility', 'visible');

                if (this.hoverCvs != null) {
                    this.containerEl.removeChild(this.hoverCvs);
                    this.hoverCvs = null;
                }
            }
        } else {
            Util.setStyle(this.pointerEl, 'visibility', 'hidden');

            if (this.hoverCvs != null) {
                this.containerEl.removeChild(this.hoverCvs);
                this.hoverCvs = null;
            }
        }
    }

    getSelection(box) {
        const componentClassNames = this.modelRefs.componentClassNames();
        const selection        = {};
        for (let className of componentClassNames) { selection[className] = {}; }
        let activeSelection = false;
        let count            = 0;
        const boxLeft         = box.x;
        const boxRight        = boxLeft + box.width;
        const {
            coords
        } = this.chart;

        const getXCoord = this.plotLine ? (coord) => coord.x : (coord) => coord.centre;

        for (let idx = 0; idx < coords.length; idx++) {
            var coord = coords[idx];
            var xCoord = getXCoord(coord);
            if ((xCoord >= boxLeft) && (xCoord <= boxRight)) {
                var datum = this.data[idx];

                // a datum won't necessarily have an associated device, in the case of a VM
                //
                // We no longer have VMs.  I have no idea if we still need this section
                // of code.
                if ((datum.instances != null) && (datum.instances.length > 0)) {
                    var device = datum.instances[0];
                    selection[device.componentClassName][device.id != null ? device.id : device.itemId] = true;
                    activeSelection = true;
                }

                ++count;
            }
        }

        return { activeSelection, selection, count };
    }

    selectWithinBox(box) {
        const selected = this.getSelection(box);
        this.modelRefs.activeSelection(selected.activeSelection);
        this.modelRefs.selectedDevices(selected.selection);
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
        this.selCount = this.fx.addText({
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
        this.fx.setAttributes(this.selCount, {
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
        this.selectWithinBox(box);
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

        this.fx.setAttributes(this.box, attrs);
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
    }

    evShowHint(datum) {
        this.over = true;
        this.model.overLBC(true);
        if ((datum.instances != null) && (this.modelRefs.highlighted() !== datum.instances)) {
            this.modelRefs.highlighted(datum.instances);
        }
    }

    evHideHint() {
        this.over = false;
        this.model.overLBC(false);
        this.modelRefs.highlighted([]);
    }

    debug(...msg) {
        console.debug('widgets/LBC:', ...msg);
    }
};

export default LBC;
