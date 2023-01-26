/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// magical orientation agnostic colour slidertron. Here be dragons.

import Util from '../util/Util';
import Events from '../util/Events';
import SimpleRenderer from '../gfx/SimpleRenderer';
import Hint from '../../irv/view/Hint';

class FilterBar {
  static initClass() {
    // statics overwritten by config
    // length/thickness used here as they're more orientation agnostic
    // than width/height
    this.THICKNESS      = 50;
    this.LENGTH         = .8;
    this.PADDING        = 20;
    this.DEFAULT_ALIGN  = 0;

    this.DRAG_TAB_SHAPE           = [{ x: -5, y: -15 }, { x: 5, y: -15 }, { x: 5, y: -5 }, { x: 0, y: 0 }, { x: -5, y: -5 }];
    this.DRAG_TAB_FILL            = '#bbbbbb';
    this.DRAG_TAB_STROKE          = '#333333';
    this.DRAG_TAB_STROKE_WIDTH    = 2;
    this.DRAG_TAB_DISABLED_ALPHA  = .3;
    this.DRAG_UPDATE_DELAY        = 500;

    this.CUTOFF_LINE_STROKE        = '#000000';
    this.CUTOFF_LINE_STROKE_WIDTH  = 10;
    this.CUTOFF_LINE_ALPHA         = .2;
  
    this.INPUT_WIDTH         = 40;
    this.INPUT_SPACING       = 10;
    this.INPUT_UPDATE_DELAY  = 1000;

    this.FONT       = 'Karla';
    this.FONT_SIZE  = 14;
    this.FONT_FILL  = '#000000';

    this.DRAG_BOX_STROKE        = '#ff00ff';
    this.DRAG_BOX_STROKE_WIDTH  = 20;
    this.DRAG_BOX_ALPHA         = .5;

    this.LABEL_MIN_SEPARATION  = 15;
  
    this.MODEL_DEPENDENCIES = {
      colourScale    : "colourScale",
      colourMaps     : "colourMaps",
      filters        : "filters",
      activeFilter   : "activeFilter",
      selectedMetric : "selectedMetric",
      showFilterBar  : "showFilterBar"
    };

    // run-time assigned statics
    this.DRAG_TAB_SHAPE_V  = null;
    this.NORMAL_COLOURS    = null;
    this.REVERSE_COLOURS   = null;

    // constants
    this.ALIGN_TOP     = 0;
    this.ALIGN_BOTTOM  = 1;
    this.ALIGN_LEFT    = 2;
    this.ALIGN_RIGHT   = 3;
  }


  constructor(containerEl, parentEl, model) {
    // create vertical drag-tab shape from a transformed horizontal drag tab
    this.setGradientColours = this.setGradientColours.bind(this);
    this.setFilter = this.setFilter.bind(this);
    this.resetFilters = this.resetFilters.bind(this);
    this.update = this.update.bind(this);
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
      for (var coord of Array.from(FilterBar.DRAG_TAB_SHAPE)) { FilterBar.DRAG_TAB_SHAPE_V.push({ x: coord.y, y: coord.x }); }
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
    const bar_thickness = FilterBar.THICKNESS - (FilterBar.PADDING * 2);
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
  
    for (var colour of Array.from(colours)) {
      var col = colour.col.toString(16);
      while (col.length < 6) { col = '0' + col; }
      this.grd.addColorStop(colour.pos, '#' + col);
    }
  
    this.ctx.fillStyle = this.grd;
    return this.ctx.fillRect(0, 0, this.gradient.width, this.gradient.height);
  }



  setFilter() {
    if (this.map == null) { return; }

    const model_filter = this.model[FilterBar.MODEL_DEPENDENCIES.filters]()[this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]()];
    this.filter      = {};
    this.filter.max  = model_filter.max != null ? model_filter.max : this.map.high;
    this.filter.min  = model_filter.min != null ? model_filter.min : this.map.low;

    return this.update();
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
    return this.update();
  }

  getSelectedPreset() {
    if (this.model.selectedPreset() == null) { return null; }

    const object = this.model.presetsById();
    for (var p_id in object) {
      var p_object = object[p_id];
      if (p_object.name === this.model.selectedPreset()) { return p_object; }
    }

    return null;
  }

  // If there is a preset selected, and it has colourMaps, and the metric selected is the metric in the preset, 
  // then use the preset colour maps as min and max for reset.
  // (the user could have changed the metric seleted, but left unchanged the selected preset)
  // Otherwise, use the metric min and max.
  setMapMinMax() {
    const selected_preset = this.getSelectedPreset();

    if ((selected_preset != null) && (selected_preset.values["colourMaps"] != null) && (selected_preset.values["selectedMetric"].split('"').join('') === this.model.selectedMetric())) {
      const presetColourMaps = JSON.parse(selected_preset.values["colourMaps"]);
      this.map.high = presetColourMaps.high;
      return this.map.low = presetColourMaps.low;
    } else {
      this.map.high = this.map.original_high;
      return this.map.low = this.map.original_low;
    }
  }

  

  updateLayout(orientation_changed) {
    let new_height, new_width;
    if (orientation_changed == null) { orientation_changed = false; }
    const parent_x      = Util.getStyleNumeric(this.parentEl, 'left');
    const parent_y      = Util.getStyleNumeric(this.parentEl, 'top');
    const parent_width  = Util.getStyleNumeric(this.parentEl, 'width');
    const parent_height = Util.getStyleNumeric(this.parentEl, 'height');

    this.setAnchor(parent_x, parent_y, parent_width, parent_height);

    if (this.cvs == null) { this.cvs = document.createElement('canvas'); }
    this.ctx = this.cvs.getContext('2d');

    if (this.horizontal) {
      new_width      = parent_width * FilterBar.LENGTH;
      new_height     = FilterBar.THICKNESS;
      this.layoutOffsetX = (FilterBar.INPUT_SPACING * 2) + FilterBar.INPUT_WIDTH;
    } else {
      new_width      = FilterBar.THICKNESS;
      new_height     = parent_height * FilterBar.LENGTH;
      this.layoutOffsetY = (FilterBar.INPUT_SPACING * 2) + this.inputHeight;
    }

    // redraw gradient only if the dimensions have changed
    if ((new_width !== this.width) || (new_height !== this.height)) {
      this.width     = new_width;
      this.height    = new_height;
      this.cvs.width  = this.width - (this.layoutOffsetX * 2);
      this.cvs.height = this.height - (this.layoutOffsetY * 2);

      this.gradient = this.cvs;

      this.setGradientColours();

      this.gfx.setDims(this.width, this.height);
      if (this.assets != null) { this.gfx.setAttributes(this.assets.bar, { img: this.cvs, width: this.cvs.width, height: this.cvs.height, sliceWidth: this.cvs.width, sliceHeight: this.cvs.height }); }

      if (orientation_changed) {
        const cutoff_line_shape = this.horizontal ? [{ x: 0, y: 0 }, { x: 0, y: this.gradient.height }] : [{ x: 0, y: 0 }, { x: this.gradient.width, y: 0 }];
        const slider_shape      = this.horizontal ? FilterBar.DRAG_TAB_SHAPE : FilterBar.DRAG_TAB_SHAPE_V;
        this.gfx.remove(this.assets.sliderA);
        this.gfx.remove(this.assets.sliderB);

        this.gfx.setAttributes(this.assets.bar, { x: this.layoutOffsetX, y: this.layoutOffsetY });
        this.gfx.setAttributes(this.assets.lineA, { coords: cutoff_line_shape, x: this.layoutOffsetX, y: this.layoutOffsetY });
        this.gfx.setAttributes(this.assets.lineB, { coords: cutoff_line_shape, x: this.layoutOffsetX, y: this.layoutOffsetY });
        //@gfx.setAttributes(@assets.labelA, { x: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE })
        //@gfx.setAttributes(@assets.labelB, { x: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE })
        //@gfx.setAttributes(@assets.sliderA, { coords: slider_shape, x: @layoutOffsetX, y: @layoutOffsetY })
        //@gfx.setAttributes(@assets.sliderB, { coords: slider_shape, x: @layoutOffsetX, y: @layoutOffsetY })
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

        this.assets.sliderA = this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: slider_shape, x: this.layoutOffsetX, y: this.layoutOffsetY });
        this.assets.sliderB = this.gfx.addPoly({ stroke: FilterBar.DRAG_TAB_STROKE, strokeWidth: FilterBar.DRAG_TAB_STROKE_WIDTH, fill: FilterBar.DRAG_TAB_FILL, coords: slider_shape, x: this.layoutOffsetX, y: this.layoutOffsetY });
      }

      if (this.map != null) { this.update(); }
    }

    const rh_bound     = (parent_x + parent_width) - this.width;
    const bottom_bound = (parent_y + parent_height) - this.height;
    let container_x  = this.anchor.x - (this.width / 2);
    if (container_x > rh_bound) { container_x  = rh_bound; }
    if (container_x < parent_x) { container_x  = parent_x; }
    const container_y  = this.anchor.y; //- (@height / 2)
    //container_y  = bottom_bound if container_y > bottom_bound
    //container_y  = parent_y if container_y < parent_y

    Util.setStyle(this.containerEl, 'left', container_x + 'px');
    Util.setStyle(this.containerEl, 'top', container_y + 'px');
    Util.setStyle(this.containerEl, 'width', this.width + 'px');
    Util.setStyle(this.containerEl, 'height', this.height + 'px');

    if (this.horizontal) {
      const y = (this.height - this.inputHeight) / 2;
      Util.setStyle(this.inputMin, 'top', y + 'px');
      Util.setStyle(this.inputMin, 'left', FilterBar.INPUT_SPACING + 'px');
      Util.setStyle(this.inputMax, 'top', y + 'px');
      return Util.setStyle(this.inputMax, 'left', (this.width - FilterBar.INPUT_SPACING - FilterBar.INPUT_WIDTH) + 'px');
    } else {
      Util.setStyle(this.inputMax, 'top', (this.height - FilterBar.INPUT_SPACING - this.inputHeight) + 'px');
      Util.setStyle(this.inputMax, 'left', ((this.width - FilterBar.INPUT_WIDTH) / 2) + 'px');
      Util.setStyle(this.inputMin , 'top', FilterBar.INPUT_SPACING + 'px');
      return Util.setStyle(this.inputMin , 'left', ((this.width - FilterBar.INPUT_WIDTH) / 2) + 'px');
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
    let bar_bounds, high, low, max_caption, max_coord, max_label_offset, min_caption, min_coord, min_label_offset, overlap, val_range;
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

    const min_alpha = this.filter.min === low ? FilterBar.DRAG_TAB_DISABLED_ALPHA : 1;
    const max_alpha = this.filter.max === high ? FilterBar.DRAG_TAB_DISABLED_ALPHA : 1;

    if (this.horizontal) {
      val_range = (this.map.high - this.map.low) / this.gradient.width;
      min_coord = ((this.filter.min - this.map.low) / val_range) + this.layoutOffsetX;
      max_coord = ((this.filter.max - this.map.low) / val_range) + this.layoutOffsetX;

      if (isNaN(min_coord) || isNaN(max_coord)) {
        min_coord   = -9999999;
        max_coord   = -9999999;
        min_caption = '';
        max_caption = '';
      } else {
        min_caption = Util.formatValue(this.filter.min);
        max_caption = Util.formatValue(this.filter.max);
      }

      bar_bounds       = this.gfx.getBounds(this.assets.bar);
      const min_label_width  = this.gfx.cvs.getContext('2d').measureText(min_caption).width;
      min_label_offset = min_label_width / 2;
      let min_label_x      = min_coord;
      if ((min_label_x - min_label_offset) < bar_bounds.x) { min_label_x      = bar_bounds.x + min_label_offset; }
      if ((min_label_x + min_label_offset) > (bar_bounds.x + bar_bounds.width)) { min_label_x      = (bar_bounds.x + bar_bounds.width) - min_label_offset; }

      const max_label_width  = this.gfx.cvs.getContext('2d').measureText(max_caption).width;
      max_label_offset = max_label_width / 2;
      let max_label_x      = max_coord;
      if ((max_label_x - max_label_offset) < bar_bounds.x) { max_label_x      = bar_bounds.x + max_label_offset; }
      if ((max_label_x + max_label_offset) > (bar_bounds.x + bar_bounds.width)) { max_label_x      = (bar_bounds.x + bar_bounds.width) - max_label_offset; }

      // prevent overlapping labels
      overlap = ((min_label_x + min_label_offset) - (max_label_x - max_label_offset)) + FilterBar.LABEL_MIN_SEPARATION;
      if (overlap > 0) {
        // offset min label
        min_label_x -= overlap / 2;
        // prevent min label from being pushed outside of the bar
        if ((min_label_x - min_label_offset) < bar_bounds.x) {
          // adjust min label to nudge it up to the end of the bar
          min_label_x = bar_bounds.x + min_label_offset;
          // nudge max label up to the end of min label
          max_label_x = min_label_x + min_label_offset + FilterBar.LABEL_MIN_SEPARATION + max_label_offset;
        } else {
          // offset max label
          max_label_x += overlap / 2;
          // prevent max label from being pushed off the right hand edge of the bar
          if ((max_label_x + max_label_offset) > (bar_bounds.x + bar_bounds.width)) {
            // place max label at right hand edge
            max_label_x = (bar_bounds.x + bar_bounds.width) - max_label_offset;
            // nudge min label up to the left hand edge of max label
            min_label_x = max_label_x - max_label_offset - FilterBar.LABEL_MIN_SEPARATION - min_label_offset;
          }
        }
      }

      this.gfx.setAttributes(this.assets.lineA, { x: min_coord });
      this.gfx.setAttributes(this.assets.lineB, { x: max_coord });
      this.gfx.setAttributes(this.assets.labelA, { caption: min_caption, x: min_label_x });
      this.gfx.setAttributes(this.assets.labelB, { caption: max_caption, x: max_label_x });
      this.gfx.setAttributes(this.assets.sliderA, { x: min_coord, alpha: min_alpha });
      this.gfx.setAttributes(this.assets.sliderB, { x: max_coord, alpha: max_alpha });

      return this.gfx.redraw();
    } else {
      val_range = (this.map.high - this.map.low) / this.gradient.height;
      min_coord = ((this.filter.min - this.map.low) / val_range) + this.layoutOffsetY;
      max_coord = ((this.filter.max - this.map.low) / val_range) + this.layoutOffsetY;

      if (isNaN(min_coord) || isNaN(max_coord)) {
        min_coord   = -9999999;
        max_coord   = -9999999;
        min_caption = ' ';
        max_caption = ' ';
      } else {
        min_caption = Util.formatValue(this.filter.min);
        max_caption = Util.formatValue(this.filter.max);
      }

      this.gfx.remove(this.assets.labelA);
      this.gfx.remove(this.assets.labelB);

      this.gfx.setAttributes(this.assets.lineA, { y: min_coord });
      this.gfx.setAttributes(this.assets.lineB, { y: max_coord });
      this.assets.labelA = this.gfx.addImg({ img: this.rotateLabel(min_caption), x: FilterBar.THICKNESS - FilterBar.PADDING, y: 0 });
      this.assets.labelB = this.gfx.addImg({ img: this.rotateLabel(max_caption), x: FilterBar.THICKNESS - FilterBar.PADDING, y: 0 });
      this.gfx.setAttributes(this.assets.sliderA, { y: min_coord, alpha: min_alpha });
      this.gfx.setAttributes(this.assets.sliderB, { y: max_coord, alpha: max_alpha });

      bar_bounds       = this.gfx.getBounds(this.assets.bar);
      min_label_offset = this.gfx.getAttribute(this.assets.labelA, 'height') / 2;
      let min_label_y      = min_coord - min_label_offset;
      if (min_label_y < bar_bounds.y) { min_label_y      = bar_bounds.y; }
      if ((min_label_y + (min_label_offset * 2)) > (bar_bounds.y + bar_bounds.height)) { min_label_y      = (bar_bounds.y + bar_bounds.height) - (min_label_offset * 2); }

      max_label_offset = this.gfx.getAttribute(this.assets.labelB, 'height') / 2;
      let max_label_y      = max_coord - max_label_offset;
      if (max_label_y < bar_bounds.y) { max_label_y      = bar_bounds.y; }
      if ((max_label_y + (max_label_offset * 2)) > (bar_bounds.y + bar_bounds.height)) { max_label_y      = (bar_bounds.y + bar_bounds.height) - (max_label_offset * 2); }

      // prevent overlapping labels
      overlap = ((min_label_y + min_label_offset) - (max_label_y - max_label_offset)) + FilterBar.LABEL_MIN_SEPARATION;
      if (overlap > 0) {
        // offset min label
        min_label_y -= overlap / 2;
        // prevent min label from being pushed outside of the bar
        if (min_label_y < bar_bounds.y) {
          // adjust min label to nudge it up to the end of the bar
          min_label_y = bar_bounds.y;
          // nudge max label up to the end of min label
          max_label_y = min_label_y + (min_label_offset * 2) + FilterBar.LABEL_MIN_SEPARATION;
        } else {
          // offset max label
          max_label_y += overlap / 2;
          // prevent max label from being pushed off the right hand edge of the bar
          if ((max_label_y + (max_label_offset * 2)) > (bar_bounds.y + bar_bounds.height)) {
            // place max label at right hand edge
            max_label_y = (bar_bounds.y + bar_bounds.height) - (max_label_offset * 2);
            // nudge min label up to the left hand edge of max label
            min_label_y = max_label_y - FilterBar.LABEL_MIN_SEPARATION - (min_label_offset * 2);
          }
        }
      }


      this.gfx.setAttributes(this.assets.labelA, { y: min_label_y });
      this.gfx.setAttributes(this.assets.labelB, { y: max_label_y });

      return this.gfx.redraw();
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


  dragSlider(slider_id, x, y) {
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

    const a_pos   = this.gfx.getAttribute(this.assets.sliderA, coord);
    const b_pos   = this.gfx.getAttribute(this.assets.sliderB, coord);
    let new_val = (((coords[coord] - offset) / this.gradient[dim]) * (this.map.high - this.map.low)) + this.map.low;

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

    if (new_val < low) {
      new_val       = low;
      coords[coord] = offset;
    } else if (new_val > high) {
      new_val       = high;
      coords[coord] = this.width - offset;
    }

    // convert new value to the coordinate space
    let new_coord  = (new_val - low) / ((high - low) / this.gradient[dim]);
    new_coord += offset;

    // update filter values
    if (new_val > this.fixedFlt) {
      this.filter.min = this.fixedFlt;
      this.filter.max = new_val;
    } else {
      this.filter.min = new_val;
      this.filter.max = this.fixedFlt;
    }

    clearTimeout(this.syncDelay);
    this.syncDelay = setTimeout(this.updateFilter, FilterBar.DRAG_UPDATE_DELAY);

    return this.update();
  }


  startDrag() {
    const parent_x      = Util.getStyleNumeric(this.parentEl, 'left');
    const parent_y      = Util.getStyleNumeric(this.parentEl, 'top');
    const parent_width  = Util.getStyleNumeric(this.parentEl, 'width');
    const parent_height = Util.getStyleNumeric(this.parentEl, 'height');
    const mid_x         = parent_x + (parent_width / 2);
    const mid_y         = parent_y + (parent_height / 2);

    this.anchorPoints = [];
    this.anchorPoints.push({ align: FilterBar.ALIGN_LEFT, x: parent_x, y: mid_y });
    this.anchorPoints.push({ align: FilterBar.ALIGN_RIGHT, x: parent_x + parent_width, y: mid_y });
    this.anchorPoints.push({ align: FilterBar.ALIGN_TOP, x: mid_x, y: parent_y });
    this.anchorPoints.push({ align: FilterBar.ALIGN_BOTTOM, x: mid_x, y: parent_y + parent_height });

    this.dragBox = this.gfx.addRect({ stroke: FilterBar.DRAG_BOX_STROKE, strokeWidth: FilterBar.DRAG_BOX_STROKE_WIDTH, alpha: FilterBar.DRAG_BOX_ALPHA, x: 0, y: 0, width: this.width, height: this.height });
    return this.gfx.redraw();
  }


  stopDrag() {
    if (this.dragBox != null) {
      this.gfx.remove(this.dragBox);
      this.gfx.redraw();
      this.dragBox = null;
      return Events.dispatchEvent(this.containerEl, 'filterBarSetAnchor');
    } else {
      clearTimeout(this.syncDelay);
      this.updateFilter();
      return this.allowDrag = true;
    }
  }


  dragBar(x, y) {
    let anchor;
    let dist = [];
    for (anchor of Array.from(this.anchorPoints)) { dist.push({ anchor, dist: Math.sqrt(Math.pow(anchor.x - x, 2) + Math.pow(anchor.y - y, 2)) }); }
    dist    = Util.sortByProperty(dist, 'dist', true);
    const nearest = dist[0];
    if (nearest.anchor.align !== this.alignment) {
      this.alignment     = nearest.anchor.align;
      //old_horizontal = @horizontal
      this.horizontal    = (this.alignment === FilterBar.ALIGN_BOTTOM) || (this.alignment === FilterBar.ALIGN_TOP);
      //if @horizontal isnt old_horizontal
      //  @gfx.remove(@assets.labelA)
      //  @gfx.remove(@assets.labelB)
      //
      //  if @horizontal
      //    @assets.labelA = @gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, align: 'center' })
      //    @assets.labelB = @gfx.addText({ font: FilterBar.FONT_SIZE + 'px ' + FilterBar.FONT, fill: FilterBar.FONT_FILL, x: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE, align: 'center' })
      //  else
      //    @assets.labelA = @gfx.addImg({ img: @rotateLabel(' '), x: FilterBar.THICKNESS - FilterBar.PADDING - FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE})
      //    @assets.labelB = @gfx.addImg({ img: @rotateLabel(' '), x: FilterBar.THICKNESS - FilterBar.PADDING - FilterBar.FONT_SIZE, y: FilterBar.THICKNESS - FilterBar.PADDING + FilterBar.FONT_SIZE })

      return this.updateLayout(true);
    }
  }

  hide() {
    Util.setStyle(this.inputMin, 'visibility', 'hidden');
    Util.setStyle(this.inputMax, 'visibility', 'hidden');
    return Util.setStyle(this.containerEl, 'visibility', 'hidden');
  }

  show() {
    Util.setStyle(this.containerEl, 'visibility', 'visible');
    Util.setStyle(this.inputMin, 'visibility', 'visible');
    return Util.setStyle(this.inputMax, 'visibility', 'visible');
  }

  evShowBar(visible) {
    if (visible) {
      return this.show();
    } else {
      return this.hide();
    }
  }

  setMap() {
    this.show();

    if (this.mapSub != null) {
      this.mapSub.dispose();
      this.mapSub = null;
    }

    const selected_metric = this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]();

    if (this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selected_metric] == null) {
      this.hide();
      this.mapSub = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps].subscribe(this.setMap);
      return;
    }

    this.map = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selected_metric];

    const filter = this.model[FilterBar.MODEL_DEPENDENCIES.filters]()[selected_metric];

    const {
      low
    } = this.map;
    const {
      high
    } = this.map;

    //if @map.high < @map.low
    //  tmp       = @map.high
    //  @map.high = @map.low
    //  @map.low  = tmp
    //  low       = @map.high
    //  high      = @map.low

    // careful to create a copy of the model filter object here otherwise we'll be 
    // quietly modifying the model while we play with the local reference of filter
    this.filter = {
      min : filter.min != null ? filter.min : low,
      max : filter.max != null ? filter.max : high
    };

    if (this.inputChangedManually === false) {
      if (this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps]()[selected_metric].inverted === true) {
        this.inputMin.value = this.map.high;
        this.inputMax.value = this.map.low;
      } else {
        this.inputMin.value = this.map.low;
        this.inputMax.value = this.map.high;
      }
    }
    this.inputChangedManually = false;
  
    this.update();
    return this.mapSub = this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps].subscribe(this.setMap);
  }
    

  updateFilter() {
    this.filterSub.dispose();

    const selected_metric = this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]();

    const min_active = (this.filter.min !== this.map.low) && (this.filter.min !== this.map.high);
    const max_active = (this.filter.max !== this.map.high) && (this.filter.max !== this.map.low);

    const filters = this.model[FilterBar.MODEL_DEPENDENCIES.filters]();

    const new_filter = {};
    if (min_active) { new_filter.min = this.filter.min; }
    if (max_active) { new_filter.max = this.filter.max; }

    filters[this.model[FilterBar.MODEL_DEPENDENCIES.selectedMetric]()] = new_filter;
    this.model[FilterBar.MODEL_DEPENDENCIES.filters](filters);
    this.model[FilterBar.MODEL_DEPENDENCIES.activeFilter](min_active || max_active);

    this.setSelectedDevicesFromFilteredDevices();

    return this.filterSub = this.model[FilterBar.MODEL_DEPENDENCIES.filters].subscribe(this.setFilter);
  }

  // When a filtering has happened, we also want to create a active selection from those
  // filterd devices, so if the user changes the metric name, the selection is still active.
  setSelectedDevicesFromFilteredDevices() {
    const groups           = this.model.groups();
    const selection        = {};
    for (var group of Array.from(groups)) { selection[group] = {}; }
    let active_selection = false;

    const object = this.model.filteredDevices();
    for (var group_key in object) {
      var group_filters = object[group_key];
      for (var item_id in group_filters) {
        var item_filter = group_filters[item_id];
        if (item_filter === true) {
          active_selection = true;
          selection[group_key][item_id] = true;
        }
      }
    }

    this.model.activeSelection(active_selection);
    return this.model.selectedDevices(selection);
  }

  evBlurInput(ev) {
    this.boxChanged = ev.target;
    clearTimeout(this.changeTmr);
    return this.updateMap();
  }


  evInputChanged(ev) {
    this.boxChanged = ev.target;
    clearTimeout(this.changeTmr);
    if (ev.keyCode === 13) {
      this.updateMap();
      this.inputMin.blur();
      return this.inputMax.blur();
    } else {
      return this.changeTmr = setTimeout(this.updateMap, FilterBar.INPUT_UPDATE_DELAY);
    }
  }

  validateInputs() {
    let invalid = false;
    let message_x = this.anchor.x;
    const message_y = this.anchor.y-10;
    if ((this.boxChanged != null ? this.boxChanged.id : undefined) === this.inputMax.id) {
      message_x += (Util.getStyleNumeric(this.boxChanged, 'left')/2);
      invalid = Number(this.inputMax.value) < Number(this.inputMin.value);
    } else {
      message_x -= (this.width/2);
      invalid = Number(this.inputMin.value) > Number(this.inputMax.value);
    }

    if (invalid) {
      this.hint.showMessage("Invalid input. If you want to invert the colours, please use the toolbox option on the left.",message_x,message_y);
      Util.setStyle(this.boxChanged, 'background-color', 'lightpink');
      return false;
    } else {
      this.hint.hide();
      Util.setStyle(this.inputMin, 'background-color', '');
      Util.setStyle(this.inputMax, 'background-color', '');
      return true;
    }
  }

  updateMap(inverted_colours) {
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
      //@map.high   = val + 1 if @map.high <= val
      this.map.low    = val;
      changed     = true;
    }

    if (changed || (inverted_colours != null)) {
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
      return this.model[FilterBar.MODEL_DEPENDENCIES.colourMaps](maps);
    }
  }


  setAnchor(parent_x, parent_y, parent_width, parent_height) {
    switch (this.alignment) {
      case FilterBar.ALIGN_BOTTOM:
        return this.anchor = { x: parent_x + (parent_width / 2), y: parent_y + parent_height };
      case FilterBar.ALIGN_TOP:
        return this.anchor = { x: parent_x + (parent_width / 2), y: parent_y };
      case FilterBar.ALIGN_LEFT:
        return this.anchor = { x: parent_x, y: parent_y + (parent_height / 2) };
      default:
        return this.anchor = { x: parent_x + parent_width, y: parent_y + (parent_height / 2) };
    }
  }
};
FilterBar.initClass();
export default FilterBar;
