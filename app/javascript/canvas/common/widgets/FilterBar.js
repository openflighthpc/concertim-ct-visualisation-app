import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import SimpleRenderer from 'canvas/common/gfx/SimpleRenderer';
import Hint from 'canvas/irv/view/Hint';

// FilterBar is a magical orientation agnostic colour slidertron.
//
// Here be dragons.
//
// It is used to 
//
// 1. filter selected devices according to whether the metric falls in a
//    particular range.
// 2. select the red and green end values for the colour range used for
//    colouring metric bars.
class FilterBar {

    // statics overwritten by config
    // length/thickness used here as they're more orientation agnostic
    // than width/height
    static THICKNESS      = 50;
    static LENGTH         = .8;
    static PADDING        = 20;
    static DEFAULT_ALIGN  = 0;

    static DRAG_TAB_SHAPE           = [{ x: -5, y: -15 }, { x: 5, y: -15 }, { x: 5, y: -5 }, { x: 0, y: 0 }, { x: -5, y: -5 }];
    static DRAG_TAB_FILL            = '#bbbbbb';
    static DRAG_TAB_STROKE          = '#333333';
    static DRAG_TAB_STROKE_WIDTH    = 2;
    static DRAG_TAB_DISABLED_ALPHA  = .3;
    static DRAG_UPDATE_DELAY        = 500;

    static CUTOFF_LINE_STROKE        = '#000000';
    static CUTOFF_LINE_STROKE_WIDTH  = 10;
    static CUTOFF_LINE_ALPHA         = .2;

    static INPUT_WIDTH         = 40;
    static INPUT_SPACING       = 10;
    static INPUT_UPDATE_DELAY  = 1000;

    static FONT       = 'Karla';
    static FONT_SIZE  = 14;
    static FONT_FILL  = '#000000';

    static LABEL_MIN_SEPARATION  = 15;

    static MODEL_DEPENDENCIES = {
        colourScale    : "colourScale",
        colourMaps     : "colourMaps",
        filters        : "filters",
        activeFilter   : "activeFilter",
        selectedMetric : "selectedMetric",
        showFilterBar  : "showFilterBar"
    };

    // run-time assigned statics
    static DRAG_TAB_SHAPE_V  = null;


    // constants
    static ALIGN_TOP     = 0;
    static ALIGN_BOTTOM  = 1;
    static ALIGN_LEFT    = 2;
    static ALIGN_RIGHT   = 3;


    constructor(containerEl, parentEl, model) {
        // create vertical drag-tab shape from a transformed horizontal drag tab
        this.setFilter = this.setFilter.bind(this);
        this.evShowBar = this.evShowBar.bind(this);
        this.setMap = this.setMap.bind(this);
        this.updateFilter = this.updateFilter.bind(this);
        this.evBlurInput = this.evBlurInput.bind(this);
        this.evInputChanged = this.evInputChanged.bind(this);
        this.updateMap = this.updateMap.bind(this);

        this.containerEl = containerEl;
        this.parentEl = parentEl;
        this.model = model;
        if (FilterBar.DRAG_TAB_SHAPE_V == null) {
            FilterBar.DRAG_TAB_SHAPE_V = [];
            for (var coord of FilterBar.DRAG_TAB_SHAPE) { FilterBar.DRAG_TAB_SHAPE_V.push({ x: coord.y, y: coord.x }); }
        }

        this.hint = new Hint(this.containerEl, this.model);

        this.model.invertedColours.subscribe(this.updateMap);
        this.alignment  = FilterBar.DEFAULT_ALIGN;
        this.horizontal = (this.alignment === FilterBar.ALIGN_BOTTOM) || (this.alignment === FilterBar.ALIGN_TOP);

        // set input sizes and event listeners
        this.inputMax = $('input_max');
        this.inputMin = $('input_min');
        Util.setStyle(this.inputMax, 'width', FilterBar.INPUT_WIDTH + "px");
        Util.setStyle(this.inputMin, 'width', FilterBar.INPUT_WIDTH + "px");
        this.inputHeight = Util.getStyleNumeric(this.inputMax, 'height');

        Events.addEventListener(this.inputMax, 'blur', this.evBlurInput);
        Events.addEventListener(this.inputMax, 'keyup', this.evInputChanged);
        Events.addEventListener(this.inputMin, 'blur', this.evBlurInput);
        Events.addEventListener(this.inputMin, 'keyup', this.evInputChanged);
        this.inputChangedManually = false;

        // create gfx. Frame rate is zero, we'll force a redraw on demand
        this.gfx = new SimpleRenderer(this.containerEl, this.width, this.height, 1, 0);
        Util.setStyle(this.gfx.cvs, 'position', 'absolute');
        Util.setStyle(this.gfx.cvs, 'left', 0);
        Util.setStyle(this.gfx.cvs, 'top', 0);
        this.gfx.cvs.getContext('2d').rotate(Math.PI / 2);

        // layout offsets
        this.layoutOffsetX = FilterBar.PADDING;
        this.layoutOffsetY = FilterBar.PADDING;

        this.allowDrag = true;

        if (this.horizontal) {
            this.layoutOffsetX = (FilterBar.INPUT_SPACING * 2) + FilterBar.INPUT_WIDTH;
        } else {
            this.layoutOffsetY = (FilterBar.INPUT_SPACING * 2) + FilterBar.INPUT_HEIGHT;
        }

        this.updateLayout();
        // UI assets
        this.assets = {
            bar     : this.gfx.addImg({ img: this.gradient, x: this.layoutOffsetX, y: this.layoutOffsetY }),
            lineA   : this.gfx.addPoly({ stroke: FilterBar.CUTOFF_LINE_STROKE, strokeWidth: FilterBar.CUTOFF_LINE_STROKE_WIDTH, alpha: FilterBar.CUTOFF_LINE_ALPHA, x: this.layoutOffsetX, y: this.layoutOffsetY, coords: [{ x: 0, y: 0 }, { x: 0, y: this.gradient.height }] }),
            lineB   : this.gfx.addPoly({ stroke: FilterBar.CUTOFF_LINE_STROKE, strokeWidth: FilterBar.CUTOFF_LINE_STROKE_WIDTH, alpha: FilterBar.CUTOFF_LINE_ALPHA, x: this.layoutOffsetX, y: this.layoutOffsetY, coords: [{ x: 0, y: 0 }, { x: 0, y: this.gradient.height }] }),
            sliderA : this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: FilterBar.DRAG_TAB_SHAPE, x: this.layoutOffsetX, y: this.layoutOffsetY }),
            sliderB : this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: FilterBar.DRAG_TAB_SHAPE, x: this.layoutOffsetX, y: this.layoutOffsetY })
        };

        if (this.horizontal) {
            this.assets.labelA = this.gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, align: 'center' });
            this.assets.labelB = this.gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, align: 'center' });
        } else {
            this.assets.labelA = this.gfx.addImg({ img: this.rotateLabel(' '), x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE});
            this.assets.labelB = this.gfx.addImg({ img: this.rotateLabel(' '), x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE });
        }

        this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric].subscribe(this.setMap);
        this.filterSub = this.model[FilterBar.MODEL_DEPENDENCIES.filters].subscribe(this.setFilter);
        this.model[FilterBar.MODEL_DEPENDENCIES.showFilterBar].subscribe(this.evShowBar);

        if (this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]() != null) {
            this.setMap();
            if (this.map != null) {
                this.update();
            }
        } else {
            Util.setStyle(this.containerEl, 'visibility', 'hidden');
        }
    }

    setGradientColours() {
        if (this.horizontal) {
            this.grd            = this.ctx.createLinearGradient(0, 0, this.width - (this.layoutOffsetX * 2), 0);
        } else {
            this.grd            = this.ctx.createLinearGradient(0, 0, 0, this.height - (this.layoutOffsetY * 2) );
        }

        this.ctx.clearRect(0, 0, this.gradient.width, this.gradient.height);
        const colours = this.model.getColoursArray();

        for (var colour of colours) {
            var col = colour.col.toString(16);
            while (col.length < 6) { col = '0' + col; }
            this.grd.addColorStop(colour.pos, '#' + col);
        }

        this.ctx.fillStyle = this.grd;
        this.ctx.fillRect(0, 0, this.gradient.width, this.gradient.height);
    }



    setFilter() {
        if (this.map == null) { return; }

        const modelFilter = this.model[FilterBar.MODEL_DEPENDENCIES.filters]()[this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]()];
        this.filter      = {};
        this.filter.max  = modelFilter.max != null ? modelFilter.max : this.map.high;
        this.filter.min  = modelFilter.min != null ? modelFilter.min : this.map.low;

        this.update();
    }

    resetFilters() {
        if (this.map == null) { return; }

        this.setMapMinMax();

        this.inputMin.value = this.map.low;
        this.inputMax.value = this.map.high;

        this.filter      = {};
        this.filter.max  = this.map.high;
        this.filter.min  = this.map.low;

        this.updateFilter();
        this.update();
    }

    getSelectedPreset() {
        if (this.model.selectedPreset() == null) { return null; }

        for (var id in this.model.presetsById()) {
            var preset = object[id];
            if (preset.name === this.model.selectedPreset()) { return preset; }
        }

        return null;
    }

    // If there is a preset selected, and it has colourMaps, and the metric selected is the metric in the preset, 
    // then use the preset colour maps as min and max for reset.
    // (the user could have changed the metric seleted, but left unchanged the selected preset)
    // Otherwise, use the metric min and max.
    setMapMinMax() {
        const selectedPreset = this.getSelectedPreset();

        if ((selectedPreset != null) && (selectedPreset.values["colourMaps"] != null) && (selectedPreset.values["selectedMetric"] === this.model.selectedMetric())) {
            const presetColourMaps = selectedPreset.values["colourMaps"];
            this.map.high = presetColourMaps.high;
            this.map.low = presetColourMaps.low;
        } else {
            this.map.high = this.map.original_high;
            this.map.low = this.map.original_low;
        }
    }



    updateLayout(orientationChanged) {
        let newHeight, newWidth;
        if (orientationChanged == null) { orientationChanged = false; }
        const parentX      = Util.getStyleNumeric(this.parentEl, 'left');
        const parentY      = Util.getStyleNumeric(this.parentEl, 'top');
        const parentWidth  = Util.getStyleNumeric(this.parentEl, 'width');
        const parentHeight = Util.getStyleNumeric(this.parentEl, 'height');

        this.setAnchor(parentX, parentY, parentWidth, parentHeight);

        if (this.cvs == null) { this.cvs = document.createElement('canvas'); }
        this.ctx = this.cvs.getContext('2d');

        if (this.horizontal) {
            newWidth      = parentWidth * FilterBar.LENGTH;
            newHeight     = FilterBar.THICKNESS;
            this.layoutOffsetX = (FilterBar.INPUT_SPACING * 2) + FilterBar.INPUT_WIDTH;
        } else {
            newWidth      = FilterBar.THICKNESS;
            newHeight     = parentHeight * FilterBar.LENGTH;
            this.layoutOffsetY = (FilterBar.INPUT_SPACING * 2) + this.inputHeight;
        }

        // redraw gradient only if the dimensions have changed
        if ((newWidth !== this.width) || (newHeight !== this.height)) {
            this.width     = newWidth;
            this.height    = newHeight;
            this.cvs.width  = this.width - (this.layoutOffsetX * 2);
            this.cvs.height = this.height - (this.layoutOffsetY * 2);

            this.gradient = this.cvs;

            this.setGradientColours();

            this.gfx.setDims(this.width, this.height);
            if (this.assets != null) { this.gfx.setAttributes(this.assets.bar, { img: this.cvs, width: this.cvs.width, height: this.cvs.height, sliceWidth: this.cvs.width, sliceHeight: this.cvs.height }); }

            if (orientationChanged) {
                const cutoffLineShape = this.horizontal ? [{ x: 0, y: 0 }, { x: 0, y: this.gradient.height }] : [{ x: 0, y: 0 }, { x: this.gradient.width, y: 0 }];
                const sliderShape      = this.horizontal ? FilterBar.DRAG_TAB_SHAPE : FilterBar.DRAG_TAB_SHAPE_V;
                this.gfx.remove(this.assets.sliderA);
                this.gfx.remove(this.assets.sliderB);

                this.gfx.setAttributes(this.assets.bar, { x: this.layoutOffsetX, y: this.layoutOffsetY });
                this.gfx.setAttributes(this.assets.lineA, { coords: cutoffLineShape, x: this.layoutOffsetX, y: this.layoutOffsetY });
                this.gfx.setAttributes(this.assets.lineB, { coords: cutoffLineShape, x: this.layoutOffsetX, y: this.layoutOffsetY });
                this.gfx.remove(this.assets.labelA);
                this.gfx.remove(this.assets.labelB);

                if (this.horizontal) {

                    this.assets.labelA = this.gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, align: 'center' });
                    this.assets.labelB = this.gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE, align: 'center' });
                } else {
                    this.assets.labelA = this.gfx.addImg({ img: this.rotateLabel(' '), x: FilterBar.THICKNESS - FilterBar.PADDING - FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE });
                    this.assets.labelB = this.gfx.addImg({ img: this.rotateLabel(' '), x: FilterBar.THICKNESS - FilterBar.PADDING - FilterBar.FONT_SIZE, y: (FilterBar.THICKNESS - FilterBar.PADDING) + FilterBar.FONT_SIZE });
                }

                if (this.dragBox != null) { this.gfx.setAttributes(this.dragBox, { width: this.width, height: this.height }); }

                this.assets.sliderA = this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: sliderShape, x: this.layoutOffsetX, y: this.layoutOffsetY });
                this.assets.sliderB = this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: sliderShape, x: this.layoutOffsetX, y: this.layoutOffsetY });
            }

            if (this.map != null) { this.update(); }
        }

        const rhBound     = (parentX + parentWidth) - this.width;
        let containerX  = this.anchor.x - (this.width / 2);
        if (containerX > rhBound) { containerX  = rhBound; }
        if (containerX < parentX) { containerX  = parentX; }
        const containerY  = this.anchor.y;

        Util.setStyle(this.containerEl, 'left', containerX + 'px');
        Util.setStyle(this.containerEl, 'top', containerY + 'px');
        Util.setStyle(this.containerEl, 'width', this.width + 'px');
        Util.setStyle(this.containerEl, 'height', this.height + 'px');

        if (this.horizontal) {
            const y = (this.height - this.inputHeight) / 2;
            Util.setStyle(this.inputMin, 'top', y + 'px');
            Util.setStyle(this.inputMin, 'left', FilterBar.INPUT_SPACING + 'px');
            Util.setStyle(this.inputMax, 'top', y + 'px');
            Util.setStyle(this.inputMax, 'left', (this.width - FilterBar.INPUT_SPACING - FilterBar.INPUT_WIDTH) + 'px');
        } else {
            Util.setStyle(this.inputMax, 'top', (this.height - FilterBar.INPUT_SPACING - this.inputHeight) + 'px');
            Util.setStyle(this.inputMax, 'left', ((this.width - FilterBar.INPUT_WIDTH) / 2) + 'px');
            Util.setStyle(this.inputMin , 'top', FilterBar.INPUT_SPACING + 'px');
            Util.setStyle(this.inputMin , 'left', ((this.width - FilterBar.INPUT_WIDTH) / 2) + 'px');
        }
    }


    rotateLabel(caption, font, size, colour) {
        if (font == null) { font = FilterBar.FONT; }
        if (size == null) { size = FilterBar.FONT_SIZE; }
        if (colour == null) { colour = FilterBar.FONT_FILL; }
        const cvs        = document.createElement('canvas');
        const ctx        = cvs.getContext('2d');
        ctx.font   = FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT;
        const {
            width
        } = ctx.measureText(caption);
        cvs.width  = FilterBar.FONT_SIZE;
        cvs.height = width;

        // re-assign font, this gets reset after setting the canvas size
        ctx.font      = FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT;
        ctx.translate(2 * FilterBar.FONT_SIZE, width);
        ctx.rotate(-Math.PI/ 2);
        ctx.fillStyle = FilterBar.FONT_FILL;
        ctx.fillText(caption, 0, -FilterBar.FONT_SIZE);
        return cvs;
    }


    update() {
        let barBounds, high, low, maxCaption, maxCoord, maxLabelOffset, minCaption, minCoord, minLabelOffset, overlap, valRange;
        const colours  = this.model[FilterBar.MODEL_DEPENDENCIES.colourScale]();
        const inverted = this.map.low > this.map.high;
        if (inverted) {
            low  = this.map.high;
            high = this.map.low;
        } else {
            ({
                low
            } = this.map);
            ({
                high
            } = this.map);
        }

        const minAlpha = this.filter.min === low ? FilterBar.DRAG_TAB_DISABLED_ALPHA : 1;
        const maxAlpha = this.filter.max === high ? FilterBar.DRAG_TAB_DISABLED_ALPHA : 1;

        if (this.horizontal) {
            valRange = (this.map.high - this.map.low) / this.gradient.width;
            minCoord = ((this.filter.min - this.map.low) / valRange) + this.layoutOffsetX;
            maxCoord = ((this.filter.max - this.map.low) / valRange) + this.layoutOffsetX;

            if (isNaN(minCoord) || isNaN(maxCoord)) {
                minCoord   = -9999999;
                maxCoord   = -9999999;
                minCaption = '';
                maxCaption = '';
            } else {
                minCaption = Util.formatValue(this.filter.min);
                maxCaption = Util.formatValue(this.filter.max);
            }

            barBounds       = this.gfx.getBounds(this.assets.bar);
            const minLabelWidth  = this.gfx.cvs.getContext('2d').measureText(minCaption).width;
            minLabelOffset = minLabelWidth / 2;
            let minLabelX      = minCoord;
            if ((minLabelX - minLabelOffset) < barBounds.x) { minLabelX      = barBounds.x + minLabelOffset; }
            if ((minLabelX + minLabelOffset) > (barBounds.x + barBounds.width)) { minLabelX      = (barBounds.x + barBounds.width) - minLabelOffset; }

            const maxLabelWidth  = this.gfx.cvs.getContext('2d').measureText(maxCaption).width;
            maxLabelOffset = maxLabelWidth / 2;
            let maxLabelX      = maxCoord;
            if ((maxLabelX - maxLabelOffset) < barBounds.x) { maxLabelX      = barBounds.x + maxLabelOffset; }
            if ((maxLabelX + maxLabelOffset) > (barBounds.x + barBounds.width)) { maxLabelX      = (barBounds.x + barBounds.width) - maxLabelOffset; }

            // prevent overlapping labels
            overlap = ((minLabelX + minLabelOffset) - (maxLabelX - maxLabelOffset)) + FilterBar.LABEL_MIN_SEPARATION;
            if (overlap > 0) {
                // offset min label
                minLabelX -= overlap / 2;
                // prevent min label from being pushed outside of the bar
                if ((minLabelX - minLabelOffset) < barBounds.x) {
                    // adjust min label to nudge it up to the end of the bar
                    minLabelX = barBounds.x + minLabelOffset;
                    // nudge max label up to the end of min label
                    maxLabelX = minLabelX + minLabelOffset + FilterBar.LABEL_MIN_SEPARATION + maxLabelOffset;
                } else {
                    // offset max label
                    maxLabelX += overlap / 2;
                    // prevent max label from being pushed off the right hand edge of the bar
                    if ((maxLabelX + maxLabelOffset) > (barBounds.x + barBounds.width)) {
                        // place max label at right hand edge
                        maxLabelX = (barBounds.x + barBounds.width) - maxLabelOffset;
                        // nudge min label up to the left hand edge of max label
                        minLabelX = maxLabelX - maxLabelOffset - FilterBar.LABEL_MIN_SEPARATION - minLabelOffset;
                    }
                }
            }

            this.gfx.setAttributes(this.assets.lineA, { x: minCoord });
            this.gfx.setAttributes(this.assets.lineB, { x: maxCoord });
            this.gfx.setAttributes(this.assets.labelA, { caption: minCaption, x: minLabelX });
            this.gfx.setAttributes(this.assets.labelB, { caption: maxCaption, x: maxLabelX });
            this.gfx.setAttributes(this.assets.sliderA, { x: minCoord, alpha: minAlpha });
            this.gfx.setAttributes(this.assets.sliderB, { x: maxCoord, alpha: maxAlpha });

            this.gfx.redraw();
        } else {
            valRange = (this.map.high - this.map.low) / this.gradient.height;
            minCoord = ((this.filter.min - this.map.low) / valRange) + this.layoutOffsetY;
            maxCoord = ((this.filter.max - this.map.low) / valRange) + this.layoutOffsetY;

            if (isNaN(minCoord) || isNaN(maxCoord)) {
                minCoord   = -9999999;
                maxCoord   = -9999999;
                minCaption = ' ';
                maxCaption = ' ';
            } else {
                minCaption = Util.formatValue(this.filter.min);
                maxCaption = Util.formatValue(this.filter.max);
            }

            this.gfx.remove(this.assets.labelA);
            this.gfx.remove(this.assets.labelB);

            this.gfx.setAttributes(this.assets.lineA, { y: minCoord });
            this.gfx.setAttributes(this.assets.lineB, { y: maxCoord });
            this.assets.labelA = this.gfx.addImg({ img: this.rotateLabel(minCaption), x: FilterBar.THICKNESS - FilterBar.PADDING, y: 0 });
            this.assets.labelB = this.gfx.addImg({ img: this.rotateLabel(maxCaption), x: FilterBar.THICKNESS - FilterBar.PADDING, y: 0 });
            this.gfx.setAttributes(this.assets.sliderA, { y: minCoord, alpha: minAlpha });
            this.gfx.setAttributes(this.assets.sliderB, { y: maxCoord, alpha: maxAlpha });

            barBounds       = this.gfx.getBounds(this.assets.bar);
            minLabelOffset = this.gfx.getAttribute(this.assets.labelA, 'height') / 2;
            let minLabelY      = minCoord - minLabelOffset;
            if (minLabelY < barBounds.y) { minLabelY      = barBounds.y; }
            if ((minLabelY + (minLabelOffset * 2)) > (barBounds.y + barBounds.height)) { minLabelY      = (barBounds.y + barBounds.height) - (minLabelOffset * 2); }

            maxLabelOffset = this.gfx.getAttribute(this.assets.labelB, 'height') / 2;
            let maxLabelY      = maxCoord - maxLabelOffset;
            if (maxLabelY < barBounds.y) { maxLabelY      = barBounds.y; }
            if ((maxLabelY + (maxLabelOffset * 2)) > (barBounds.y + barBounds.height)) { maxLabelY      = (barBounds.y + barBounds.height) - (maxLabelOffset * 2); }

            // prevent overlapping labels
            overlap = ((minLabelY + minLabelOffset) - (maxLabelY - maxLabelOffset)) + FilterBar.LABEL_MIN_SEPARATION;
            if (overlap > 0) {
                // offset min label
                minLabelY -= overlap / 2;
                // prevent min label from being pushed outside of the bar
                if (minLabelY < barBounds.y) {
                    // adjust min label to nudge it up to the end of the bar
                    minLabelY = barBounds.y;
                    // nudge max label up to the end of min label
                    maxLabelY = minLabelY + (minLabelOffset * 2) + FilterBar.LABEL_MIN_SEPARATION;
                } else {
                    // offset max label
                    maxLabelY += overlap / 2;
                    // prevent max label from being pushed off the right hand edge of the bar
                    if ((maxLabelY + (maxLabelOffset * 2)) > (barBounds.y + barBounds.height)) {
                        // place max label at right hand edge
                        maxLabelY = (barBounds.y + barBounds.height) - (maxLabelOffset * 2);
                        // nudge min label up to the left hand edge of max label
                        minLabelY = maxLabelY - FilterBar.LABEL_MIN_SEPARATION - (minLabelOffset * 2);
                    }
                }
            }


            this.gfx.setAttributes(this.assets.labelA, { y: minLabelY });
            this.gfx.setAttributes(this.assets.labelB, { y: maxLabelY });

            this.gfx.redraw();
        }
    }


    getSliderAt(x, y) {
        let bounds = this.gfx.getBounds(this.assets.sliderA);
        if ((x >= bounds.x) && (x <= (bounds.x + bounds.width)) && (y >= bounds.y) && (y <= (bounds.y + bounds.height))) {
            this.fixedFlt = this.filter.max;
            return this.assets.sliderA;
        }

        bounds = this.gfx.getBounds(this.assets.sliderB);
        if ((x >= bounds.x) && (x <= (bounds.x + bounds.width)) && (y >= bounds.y) && (y <= (bounds.y + bounds.height))) {
            this.fixedFlt = this.filter.min;
            return this.assets.sliderB;
        }

        return null;
    }


    dragSlider(sliderId, x, y) {
        let coord, dim, high, low, offset;
        if (!this.allowDrag) { return; }

        const coords = {
            x,
            y
        };

        if (this.horizontal) {
            coord  = 'x';
            dim    = 'width';
            offset = this.layoutOffsetX;
        } else {
            coord  = 'y';
            dim    = 'height';
            offset = this.layoutOffsetY;
        }

        let newVal = (((coords[coord] - offset) / this.gradient[dim]) * (this.map.high - this.map.low)) + this.map.low;

        if (this.map.high > this.map.low) {
            ({
                high
            } = this.map);
            ({
                low
            } = this.map);
        } else {
            high = this.map.low;
            low  = this.map.high;
        }

        if (newVal < low) {
            newVal       = low;
            coords[coord] = offset;
        } else if (newVal > high) {
            newVal       = high;
            coords[coord] = this.width - offset;
        }

        // update filter values
        if (newVal > this.fixedFlt) {
            this.filter.min = this.fixedFlt;
            this.filter.max = newVal;
        } else {
            this.filter.min = newVal;
            this.filter.max = this.fixedFlt;
        }

        clearTimeout(this.syncDelay);
        this.syncDelay = setTimeout(this.updateFilter, FilterBar.DRAG_UPDATE_DELAY);

        this.update();
    }


    stopDrag() {
        clearTimeout(this.syncDelay);
        this.updateFilter();
        this.allowDrag = true;
    }


    hide() {
        Util.setStyle(this.inputMin, 'visibility', 'hidden');
        Util.setStyle(this.inputMax, 'visibility', 'hidden');
        Util.setStyle(this.containerEl, 'visibility', 'hidden');
    }

    show() {
        Util.setStyle(this.containerEl, 'visibility', 'visible');
        Util.setStyle(this.inputMin, 'visibility', 'visible');
        Util.setStyle(this.inputMax, 'visibility', 'visible');
    }

    evShowBar(visible) {
        if (visible) {
            this.show();
        } else {
            this.hide();
        }
    }

    setMap() {
        this.show();

        if (this.mapSub != null) {
            this.mapSub.dispose();
            this.mapSub = null;
        }

        const selectedMetric = this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]();

        if (this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selectedMetric] == null) {
            this.hide();
            this.mapSub = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps].subscribe(this.setMap);
            return;
        }

        this.map = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selectedMetric];

        const filter = this.model[FilterBar.MODEL_DEPENDENCIES.filters]()[selectedMetric];

        const {
            low
        } = this.map;
        const {
            high
        } = this.map;

        // careful to create a copy of the model filter object here otherwise we'll be 
        // quietly modifying the model while we play with the local reference of filter
        this.filter = {
            min : filter.min != null ? filter.min : low,
            max : filter.max != null ? filter.max : high
        };

        if (this.inputChangedManually === false) {
            if (this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selectedMetric].inverted === true) {
                this.inputMin.value = this.map.high;
                this.inputMax.value = this.map.low;
            } else {
                this.inputMin.value = this.map.low;
                this.inputMax.value = this.map.high;
            }
        }
        this.inputChangedManually = false;

        this.update();
        this.mapSub = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps].subscribe(this.setMap);
    }


    updateFilter() {
        this.filterSub.dispose();

        const minActive = (this.filter.min !== this.map.low) && (this.filter.min !== this.map.high);
        const maxActive = (this.filter.max !== this.map.high) && (this.filter.max !== this.map.low);

        const filters = this.model[FilterBar.MODEL_DEPENDENCIES.filters]();

        const newFilter = {};
        if (minActive) { newFilter.min = this.filter.min; }
        if (maxActive) { newFilter.max = this.filter.max; }

        filters[this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]()] = newFilter;
        this.model[FilterBar.MODEL_DEPENDENCIES.filters](filters);
        this.model[FilterBar.MODEL_DEPENDENCIES.activeFilter](minActive || maxActive);

        this.setSelectedDevicesFromFilteredDevices();

        this.filterSub = this.model[FilterBar.MODEL_DEPENDENCIES.filters].subscribe(this.setFilter);
    }

    // When a filtering has happened, we also want to create a active selection from those
    // filtered devices, so if the user changes the metric name, the selection is still active.
    setSelectedDevicesFromFilteredDevices() {
        const selection        = this.model.getBlankComponentClassNamesObject();
        let activeSelection = false;

        const object = this.model.filteredDevices();
        for (let className in object) {
            let classFilters = object[className];
            for (let itemId in classFilters) {
                let itemFilter = classFilters[itemId];
                if (itemFilter === true) {
                    activeSelection = true;
                    selection[className][itemId] = true;
                }
            }
        }

        this.model.activeSelection(activeSelection);
        this.model.selectedDevices(selection);
    }

    evBlurInput(ev) {
        this.boxChanged = ev.target;
        clearTimeout(this.changeTmr);
        this.updateMap();
    }


    evInputChanged(ev) {
        this.boxChanged = ev.target;
        clearTimeout(this.changeTmr);
        if (ev.keyCode === 13) {
            this.updateMap();
            this.inputMin.blur();
            this.inputMax.blur();
        } else {
            this.changeTmr = setTimeout(this.updateMap, FilterBar.INPUT_UPDATE_DELAY);
        }
    }

    validateInputs() {
        let invalid = false;
        let messageX = this.anchor.x;
        const messageY = this.anchor.y-10;
        if ((this.boxChanged != null ? this.boxChanged.id : undefined) === this.inputMax.id) {
            messageX += (Util.getStyleNumeric(this.boxChanged, 'left')/2);
            invalid = Number(this.inputMax.value) < Number(this.inputMin.value);
        } else {
            messageX -= (this.width/2);
            invalid = Number(this.inputMin.value) > Number(this.inputMax.value);
        }

        if (invalid) {
            this.hint.showMessage("Invalid input. If you want to invert the colours, please use the toolbox option on the left.",messageX,messageY);
            Util.setStyle(this.boxChanged, 'background-color', 'lightpink');
            return false;
        } else {
            this.hint.hide();
            Util.setStyle(this.inputMin, 'background-color', '');
            Util.setStyle(this.inputMax, 'background-color', '');
            return true;
        }
    }

    updateMap(invertedColours) {
        if (this.validateInputs() !== true) { return; }
        this.inputChangedManually = true;
        let changed = false;

        let val = Number(this.inputMax.value);
        if (!isNaN(val) && (this.map.high !== val)) {
            if ((this.filter.max > val) || (this.filter.max === this.map.high)) { this.filter.max = val; }
            if (this.filter.min > val) { this.filter.min = val; }
            //@map.low    = val - 1 if @map.low >= val
            this.map.high   = val;
            changed     = true;
        }

        val = Number(this.inputMin.value);
        if (!isNaN(val) && (this.map.low !== val)) {
            if (this.filter.max < val) { this.filter.max = val; }
            if ((this.filter.min < val) || (this.filter.min === this.map.low)) { this.filter.min = val; }
            this.map.low    = val;
            changed     = true;
        }

        if (changed || (invertedColours != null)) {
            let map;
            this.setGradientColours();
            this.inputMax.setAttribute('value', this.map.high);
            this.inputMin.setAttribute('value', this.map.low);
            this.update();
            this.updateFilter();

            const range = this.map.high === this.map.low ? 1e-100 : Math.abs(this.map.high - this.map.low);

            if (this.model.invertedColours() === true) {
                this.model[FilterBar.MODEL_DEPENDENCIES.colourScale](this.model.invertedColoursArray);
                map = { high: this.map.high, low: this.map.low, inverted: false, range };
            } else {
                this.model[FilterBar.MODEL_DEPENDENCIES.colourScale](this.model.normalColoursArray);
                ({
                    map
                } = this);
                map.inverted = false;
                map.range    = range;
            }

            const maps = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]();
            maps[this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]()] = map;
            this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps](maps);
        }
    }


    setAnchor(parentX, parentY, parentWidth, parentHeight) {
        switch (this.alignment) {
            case FilterBar.ALIGN_BOTTOM:
                this.anchor = { x: parentX + (parentWidth / 2), y: parentY + parentHeight };
                break;
            case FilterBar.ALIGN_TOP:
                this.anchor = { x: parentX + (parentWidth / 2), y: parentY };
                break;
            case FilterBar.ALIGN_LEFT:
                this.anchor = { x: parentX, y: parentY + (parentHeight / 2) };
                break;
            default:
                this.anchor = { x: parentX + parentWidth, y: parentY + (parentHeight / 2) };
                break;
        }
    }
};

export default FilterBar;
