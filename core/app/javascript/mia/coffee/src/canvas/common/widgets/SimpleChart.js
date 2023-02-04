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
import Events from 'canvas/common/util/Events';

class SimpleChart {
  static initClass() {
    // statics overwritten by config
    this.LABEL_DIVISIONS    = [ 5, 2, 1 ];
    this.LABEL_MIN_GAP      = 20;
    this.LABEL_TICK_SIZE    = 3;
    this.LABEL_FONT         = 'Verdana';
    this.LABEL_FONT_SIZE    = 10;
    this.LABEL_FONT_COLOUR  = '#000';
    this.LABEL_MARGIN       = 4;
  
    this.TITLE_FONT        = 'Verdana';
    this.TITLE_FONT_STYLE  = 'bold';
    this.TITLE_FONT_SIZE   = 14;
    this.TITLE_COLOUR      = '#000';
  
    this.TRUNCATION_SUFFIX  = '...';

    this.MARGIN_LEFT    = 50;
    this.MARGIN_RIGHT   = 50;
    this.MARGIN_TOP     = 50;
    this.MARGIN_BOTTOM  = 50;

    this.FORMAT_LIMIT   = 99999;

    this.AXIS_STROKE_WIDTH  = .5;
    this.AXIS_STROKE        = '#000';

    this.GRID_STROKE_WIDTH  = .5;
    this.GRID_STROKE        = '#888';

    this.LINE_DATUM_HOVER_RADIUS  = 4;

    this.TOOLTIP_CAPTION       = 'substitute data field names like so: [[someField]]';
    this.TOOLTIP_COLOUR_FIELD  = null;

    this.MOUSE_MOVE_THROTTLE_DELAY  = 50;

    // constants and run-time assigned statics
    this.TYPE_BAR   = 0;
    this.TYPE_LINE  = 1;
  }


  // initialisation stuff
  // @param  cvs       the canvas element to draw the chart to
  // @param  tooltip   a reference to a div to be used as the tootltip
  constructor(cvs, tooltip) {
    this.splitTextIntoLines = this.splitTextIntoLines.bind(this);
    this.evMouseMove = this.evMouseMove.bind(this);
    this.testHover = this.testHover.bind(this);
    this.cvs = cvs;
    this.tooltip = tooltip;
    Events.addEventListener(this.cvs, 'mousemove', this.evMouseMove);
    this.tooltipInitColour = Util.getStyle(this.tooltip, 'background');
    this.ctx               = this.cvs.getContext('2d');

    // initialise listener arrays for custom events
    this.listeners   = { onshowtooltip: [], onhidetooltip: [] };
    this.showingHint = false;
  }


  // kills the chart cleaning up anything which might persist if the instance is deleted
  destroy() {
    this.clear();
    this.hideTooltip();
    return Events.removeEventListener(this.cvs, 'mousemove', this.evMouseMove);
  }


  // clears any existing title amd adds the supplied title to the chart
  // @param  title the title as a string
  setTitle(title) {
    this.clearTitle();
    return this.drawTitle(title);
  }


  // removes the chart title from the canvas
  clearTitle() {
    if (this.titleBounds == null) { return; }
    this.ctx.clearRect(this.titleBounds.x, this.titleBounds.y, this.titleBounds.width, this.titleBounds.height);
    return this.titleBounds = null;
  }


  // subscribes a listener to a particular event
  // @param  event     the string event name to subscribe to
  // @param  listener  the external event handling function
  addEventListener(event, listener) {
    if ((this.listeners[event] == null) || (Util.arrayIndexOf(this.listeners[event], listener) !== -1) || (typeof listener !== 'function')) { return; }
    return this.listeners[event].push(listener);
  }


  // unsubscribes a listener from a particular event
  // @param  event     the string event name to unsubscribe from
  // @param  listener  a reference to the external event handling function
  removeEventListener(event, listener) {
    if (this.listeners[event] == null) { return; }
    const idx = Util.arrayIndexOf(this.listeners[event], listener);
    if (idx === -1) { return; }
    return this.listeners.splice(idx, 1);
  }


  // dispatches a custom event. Any additional parameters passed in are relayed on to the event listeners
  // @param  event   the string name of the event
  dispatchEvent(event) {
    const args = [];
    const len  = arguments.length;
    let idx  = 1;
    // compile additional params into an array
    while (idx < len) {
      args.push(arguments[idx]);
      ++idx;
    }

    return Array.from(this.listeners[event]).map((listener) => listener.apply(this, args));
  }


  // public method, draws a bar chart. This is optimised for performance, hence there is some duplication
  // of code and lots of local variables
  // @param  data    an array of objects each representing a datum to plot
  // @param  config  an object containing configuration options
  drawBar(data, config) {
    let centre, datum, height, top;
    this.type = SimpleChart.TYPE_BAR;
    this.clear();

    if (!(data.length > 0)) { return; }

    this.validateConfig(config);
    if (config.title != null) { this.drawTitle(config.title); }
    this.drawAxis();
  
    if (config.sortOn != null) { Util.sortByProperty(data, config.sortOn, config.sortAscending); }

    const datum_width   = (this.cvs.width - SimpleChart.MARGIN_LEFT - SimpleChart.MARGIN_RIGHT) / data.length;
    const multi_series  = config.yValues.length > 1;
    const y_axis        = this.getYAxis(data, config);
    const x_value_key   = config.xValue;
    const y_value_keys  = config.yValues;
    const colour_keys   = config.colours;
    const y_to_px       = y_axis.yToPx;
    let bottom        = this.cvs.height - SimpleChart.MARGIN_BOTTOM;
    const coords        = [];
    const x_label_y_co  = bottom + SimpleChart.LABEL_FONT_SIZE + SimpleChart.LABEL_MARGIN;
    const half_width    = datum_width / 2;
    const draw_x_labels = datum_width >= SimpleChart.LABEL_MIN_GAP;
    let left          = SimpleChart.MARGIN_LEFT;

    this.ctx.font      = SimpleChart.LABEL_FONT_SIZE + 'px ' + SimpleChart.LABEL_FONT;
    this.ctx.textAlign = 'center';

    if (multi_series) {
      for (datum of Array.from(data)) {
        var vals = [];
        for (var idx = 0; idx < y_value_keys.length; idx++) { var y_key = y_value_keys[idx]; vals.push({ val: datum[y_key], col: datum[colour_keys[idx]] }); }
        vals.sort((a, b) => a.val - b.val);

        bottom = this.cvs.height - SimpleChart.MARGIN_BOTTOM;
        centre = left + half_width;

        for (var val of Array.from(vals)) {
          this.ctx.beginPath();
          this.ctx.fillStyle = val.col;

          top    = y_to_px(val.val);
          height = bottom - top;

          this.ctx.fillRect(left, top, datum_width, height);
          bottom = top;
        }

        coords.push({ datum, x: left, y: bottom, centre, width: datum_width, height: this.cvs.height - SimpleChart.MARGIN_BOTTOM - bottom });

        if (draw_x_labels) {
          this.ctx.beginPath();
          this.ctx.fillStyle = SimpleChart.LABEL_FONT_COLOUR;
          this.ctx.fillText(this.truncateText(datum[x_value_key], datum_width), centre, x_label_y_co);
        }

        left += datum_width;
      }
    } else {
      const y_value    = y_value_keys[0];
      const colour_key = colour_keys[0];
      for (datum of Array.from(data)) {
        this.ctx.beginPath();
        this.ctx.fillStyle = datum[colour_key];

        top    = y_to_px(datum[y_value]);
        height = bottom - top;
        centre = left + half_width;

        this.ctx.fillRect(left, top, datum_width, height);
        coords.push({ datum, x: left, y: top, centre, width: datum_width, height });

        if (draw_x_labels) { this.addXLabel(datum[x_value_key], centre, x_label_y_co, datum_width, SimpleChart.LABEL_FONT_SIZE); }

        left += datum_width;
      }
    }

    if ((config.colourMask != null) && (config.colourMask.length > 0)) { this.applyGradientMask(config.colourMask, y_axis); }
    this.coords = coords;
    this.yAxis  = y_axis;
    this.drawYLabels(y_axis);

    return { max: y_axis.max, min: y_axis.min };
  }


  // public method, draws a line chart. This is optimised for performance hence there is some duplication of code
  // and lots of local variables
  // @param  data    an array of objects each representing a datum to plot
  // @param  config  an object containing configuration options
  drawLine(data, config) {
    let datum, left;
    this.type = SimpleChart.TYPE_LINE;
    this.clear();

    if (!(data.length > 0)) { return; }

    this.validateConfig(config);
    if (config.title != null) { this.drawTitle(config.title); }
    this.drawAxis();
  
    if (config.sortOn != null) { Util.sortByProperty(data, config.sortOn, config.sortAscending); }

    const datum_width   = (this.cvs.width - SimpleChart.MARGIN_LEFT - SimpleChart.MARGIN_RIGHT) / (data.length - 1);
    const y_axis        = this.getYAxis(data, config);
    const x_value_key   = config.xValue;
    const y_value_keys  = config.yValues;
    const colour_keys   = config.colours;
    const y_to_px       = y_axis.yToPx;
    const bottom        = this.cvs.height - SimpleChart.MARGIN_BOTTOM;
    const coords        = [];
    const x_label_y_co  = bottom + SimpleChart.LABEL_FONT_SIZE + SimpleChart.LABEL_MARGIN;
    const half_width    = datum_width / 2;
    const draw_x_labels = datum_width >= SimpleChart.LABEL_MIN_GAP;

    this.ctx.font      = SimpleChart.LABEL_FONT_SIZE + 'px ' + SimpleChart.LABEL_FONT;
    this.ctx.textAlign = 'center';

    let first_pass = true;
    for (let idx = 0; idx < y_value_keys.length; idx++) {
      var y_value = y_value_keys[idx];
      left = SimpleChart.MARGIN_LEFT;
      this.ctx.lineWidth   = 1;
      this.ctx.beginPath();
      this.ctx.moveTo(left, y_to_px(data[0][y_value]));

      for (datum of Array.from(data)) {
        var top = y_to_px(datum[y_value]);

        this.ctx.strokeStyle = datum.colour;
        this.ctx.lineTo(left, top);
        if (first_pass) { coords.push({ datum, x: left, y: top }); }

        if (config.fillBelowLine) {
          this.ctx.lineTo(left, this.cvs.height - SimpleChart.MARGIN_BOTTOM);
          this.ctx.moveTo(left,top);
        }

        left += datum_width;

        this.ctx.stroke();
      }

      first_pass = false;
    }

    if (draw_x_labels) {
      left = SimpleChart.MARGIN_LEFT;
      for (datum of Array.from(data)) {
        this.addXLabel(datum[x_value_key], left, x_label_y_co, datum_width, SimpleChart.LABEL_FONT_SIZE);
        left += datum_width;
      }
    }

    if ((config.colourMask != null) && (config.colourMask.length > 0)) { this.applyGradientMask(config.colourMask, y_axis); }
    this.coords = coords;
    this.yAxis  = y_axis;
    this.drawYLabels(y_axis);

    return { max: y_axis.max, min: y_axis.min };
  }


  // public method, draws a line behind the data. The line will always span the entire width of the x-axis. This
  // facilitates the drawing of simple thresholds
  // @param  y       the y value in the units of the y-axis NOT the pixel y coordinate
  // @param  colour  the colour of the line
  // @param  width   the thickness of the line, defaults to 1
  drawBGLine(y, colour, width) {
    if (width == null) { width = 1; }
    return this.drawHorizontalLine(y, colour, width, 'destination-over');
  }

  // public method, draws a line over the data (ForeGround).
  drawFGLine(y, colour, width) {
    if (width == null) { width = 1; }
    return this.drawHorizontalLine(y, colour, width, 'source-over');
  }

  drawHorizontalLine(y, colour, width, globalCompositeO) {
    if ((this.yAxis == null)) { return; }

    const init_comp = this.ctx.globalCompositeOperation;

    this.ctx.strokeStyle              = colour;
    this.ctx.lineWidth                = width;
    this.ctx.globalCompositeOperation = globalCompositeO;  // this allows us to draw under or over what is already there

    const y_co = this.yAxis.yToPx(y);
  
    this.ctx.beginPath();
    this.ctx.moveTo(SimpleChart.MARGIN_LEFT, y_co);
    this.ctx.lineTo(this.cvs.width - SimpleChart.MARGIN_RIGHT, y_co);
    this.ctx.stroke();

    // restore composition to what it was before we started
    return this.ctx.globalCompositeOperation = init_comp;
  }

  // public method, draws a line behind the data with a lable above it, either at the far left, or far right of the line 
  // draw
  // @param  label             the text to render
  // @param  label_position    left or right
  // @param  y       the y value in the units of the y-axis NOT the pixel y coordinate
  // @param  colour  the colour of the line
  // @param  width   the thickness of the line, defaults to 1
  drawBGLineWithLabel(label, label_position, y, colour, width) {
    if (label_position == null) { label_position = "left"; }
    if (width == null) { width = 1; }
    if ((this.yAxis == null) || (y < this.yAxis.range.low) || (y > this.yAxis.range.high)) { return; }

    const x_pos = label_position === "left" ? (SimpleChart.MARGIN_LEFT + 10) : (this.cvs.width - SimpleChart.MARGIN_RIGHT - 10);
    this.drawBGLine(y, colour, width);
    this.ctx.globalCompositeOperation = 'destination-over';  // this allows us to draw under what is already there
    this.ctx.strokeStyle              = SimpleChart.GRID_STROKE;
    this.ctx.lineWidth                = SimpleChart.GRID_STROKE_WIDTH;
    this.ctx.font                     = SimpleChart.LABEL_FONT_SIZE + 'px ' + SimpleChart.LABEL_FONT;
    this.ctx.fillStyle                = colour || SimpleChart.LABEL_FONT_COLOUR;
    return this.ctx.fillText(label, x_pos, this.yAxis.yToPx(y) - 5);
  }

  // public method, draws a box behind the data. The box will always span the entire width of the x-axis. This
  // facilitates the drawing of thresholds
  // @param  y1      upper or lower boundary of rectangle in the units of the y-axis NOT the pixel y coordinate
  // @param  y2      the other boundary of rectangle in the units of the y-axis NOT the pixel y coordinate
  // @param  colour  the colour of the box
  drawBGRect(y1, y2, colour) {
    if ((this.yAxis == null)) { return; }

    const init_comp = this.ctx.globalCompositeOperation;

    this.ctx.fillStyle                = colour;
    this.ctx.globalCompositeOperation = 'destination-over';  // this allows us to draw under what is already there

    // ensure y1 is the lower of the two values
    if (y2 < y1) {
      const tmp = y1;
      y1  = y2;
      y2  = tmp;
    }

    const chart_bottom = this.cvs.height - SimpleChart.MARGIN_BOTTOM;

    y1 = this.yAxis.yToPx(y1);
    if (y1 > chart_bottom) { y1 = chart_bottom; }
    if (y1 < SimpleChart.MARGIN_TOP) { y1 = SimpleChart.MARGIN_TOP; }
    y2 = this.yAxis.yToPx(y2);
    if (y2 > chart_bottom) { y2 = chart_bottom; }
    if (y2 < SimpleChart.MARGIN_TOP) { y2 = SimpleChart.MARGIN_TOP; }

    const height = y2 - y1;

    this.ctx.beginPath();
    this.ctx.rect(SimpleChart.MARGIN_LEFT, y1, this.cvs.width - SimpleChart.MARGIN_LEFT - SimpleChart.MARGIN_RIGHT, height);
    this.ctx.fill();

    // restore composition to what ever it was before we started
    return this.ctx.globalCompositeOperation = init_comp;
  }


  // adds labesl to the y-axis
  // @param  y_axis  an object containing info about the y-axis as well as a function to convert a y value into a y coordinate
  drawYLabels(y_axis) {
    const labels = this.getLabels(y_axis.range.high, y_axis.range.low, this.cvs.height - SimpleChart.MARGIN_TOP - SimpleChart.MARGIN_BOTTOM, SimpleChart.LABEL_MIN_GAP);

    this.ctx.globalCompositeOperation = 'destination-over';
    this.ctx.strokeStyle              = SimpleChart.GRID_STROKE;
    this.ctx.lineWidth                = SimpleChart.GRID_STROKE_WIDTH;
    this.ctx.font                     = SimpleChart.LABEL_FONT_SIZE + 'px ' + SimpleChart.LABEL_FONT;
    this.ctx.fillStyle                = SimpleChart.LABEL_FONT_COLOUR;
    this.ctx.textAlign                = 'right';

    const left           = SimpleChart.MARGIN_LEFT - SimpleChart.LABEL_TICK_SIZE;
    const right          = this.cvs.width - SimpleChart.MARGIN_RIGHT;
    const label_x        = left - SimpleChart.LABEL_MARGIN;
    const label_y_offset = (SimpleChart.LABEL_FONT_SIZE * 2) / 5;

    return (() => {
      const result = [];
      for (var label of Array.from(labels)) {
        this.ctx.beginPath();
        var y_co = Math.round(y_axis.yToPx(Number(label)));
        this.ctx.moveTo(left, y_co);
        this.ctx.lineTo(right, y_co);
        this.ctx.stroke();
        result.push(this.ctx.fillText(this.formatLabel(label), label_x, y_co + label_y_offset));
      }
      return result;
    })();
  }

  formatLabel(oneLabel) {
    if (oneLabel > SimpleChart.FORMAT_LIMIT) {
      return (oneLabel/1000) + "K";
    } else {
      return oneLabel;
    }
  }

  // makes y-axis related calculations such as finding max and min y values, y-axis range calculation and
  // provides a function to convert a y value into a pixel value
  getYAxis(data, config) {
    const y_vals = config.yValues;

    // find min/max considering every series of data
    let max_y  = -Number.MAX_VALUE;
    let min_y  = Number.MAX_VALUE;
    for (var datum of Array.from(data)) {
      for (var value of Array.from(y_vals)) {
        if (datum[value] > max_y) { max_y = datum[value]; }
        if (datum[value] < min_y) { min_y = datum[value]; }
      }
    }

    if (this.thresholdValue) {
      if (this.thresholdValue > max_y) {
        max_y = this.thresholdValue;
      } else if (this.thresholdValue < min_y) {
        min_y = this.thresholdValue;
      }
    }

    // calculate suitable y-axis range to encapsulate min and max
    const y_range  = this.getAxisRange(max_y, min_y);
    // calculate the value of a single pixel in y units
    const y_px_val = (this.cvs.height - SimpleChart.MARGIN_TOP - SimpleChart.MARGIN_BOTTOM) / (y_range.high - y_range.low);
    const y_anchor = this.cvs.height - SimpleChart.MARGIN_BOTTOM;

    // convert y value in units into a y px coordinate
    const y_to_px = y => y_anchor - ((y - y_range.low) * y_px_val);

    return { range: y_range, yToPx: y_to_px, max: max_y, min: min_y };
  }


  // applies some basic validation to a config object ensuring required properties are present and of the correct type
  // @param  config  the config object to validate
  // @throws lots of custom errors
  validateConfig(config) {
    if (config.colours == null) { throw 'SimpleChart.validateConfig no colours property defined, please provide "colours" in key map'; }
    if (Object.prototype.toString.call(config.colours) !== '[object Array]') { throw 'SimpleChart.validateConfig colours must be of type Array'; }
    if (config.xValue == null) { throw 'SimpleChart.validateConfig no x value defined, please provide "xValue" in key map'; }
    if (config.yValues == null) { throw 'SimpleChart.validateConfig no y values defined, please provide "yValues" in key map'; }
    if (Object.prototype.toString.call(config.yValues) !== '[object Array]') { throw 'SimpleChart.validateConfig yValues must be of type Array'; }
    if (config.yValues.length !== config.colours.length) { throw 'SimpleChart.validateConfig colours length doesn\'t match yValues length. Please provide colour data for each series'; }
    if ((config.colourMask != null) && (Object.prototype.toString.call(config.colourMask) !== '[object Array]')) { throw 'SimpleChart.validateConfig colour mask must be of type Array'; }
  }


  // draws the x and y axis lines only
  drawAxis() {
    const right  = this.cvs.width - SimpleChart.MARGIN_RIGHT;
    const bottom = this.cvs.height - SimpleChart.MARGIN_BOTTOM;

    this.ctx.strokeStyle = SimpleChart.AXIS_STROKE;
    this.ctx.lineWidth   = SimpleChart.AXIS_STROKE_WIDTH;

    this.ctx.beginPath();
    this.ctx.moveTo(SimpleChart.MARGIN_LEFT, SimpleChart.MARGIN_TOP);
    this.ctx.lineTo(SimpleChart.MARGIN_LEFT, bottom);
    this.ctx.lineTo(right, bottom);
    return this.ctx.stroke();
  }


  // clears the entire chart and resets the coordinate lookup
  clear() {
    this.coords = [];
    return this.ctx.clearRect(0, 0, this.cvs.width, this.cvs.height);
  }


  // finds the exponent required to express the supplied value in standard form
  // @param  value the value to express in standard form
  // @return exponent as a positive or negative integer  
  findSFExponent(value) {
    const is_standard_form = function(exponent) {
      const adjusted = Math.abs(value / Math.pow(10, exponent));
      return (adjusted >= 1) && (adjusted < 10);
    };

    const delta     = value < 1 ? -1 : 1;   // search up or down?
    let exponent  = 0;
    while (!is_standard_form(exponent)) { exponent += delta; }

    return exponent;
  }


  // chooses a sensible upper and lower bound for an axis
  // @param  max   the maximum data value
  // @param  min   the minimum data value
  // @return an object with properties low and high representing the range of the axis
  getAxisRange(max, min) {
    let high, low;
    const range = max - min;

    // special case if all data is the same value
    if (range === 0) {
      high = Math.ceil(max);
      low  = Math.floor(min);
      if (low === high) { --low; }    // ensure there is some gap
      return { low, high };
    }

    const sf_exponent = this.findSFExponent(range);

    const factor = Math.pow(10, sf_exponent);            // scale of the range
    high   = Math.ceil(max / factor) * factor;     // round up to the nearest factor
    low    = Math.floor(min / factor) * factor;    // round down to the nearest factor
    if ((low === min) && (min !== 0)) { low   -= factor; }  // nudge low down if equal to min
    return { low, high };
  }


  // given the pixel size of an axis and a minimum distance between labels this routine calculates 
  // the most sensible label interval and returns an array of labels to be displayed, as numbers 
  // expressed as strings rounded to a sensible number of dp
  // @param  max       the highest axis value
  // @param  min       the lowest axis value
  // @param  axis_size the pixel size of the axis
  // @param  min_dist  the minimum distance allowed between labels, in pixels
  // @return array of axis labels
  getLabels(max, min, axis_size, min_dist) {
    const range       = max - min;
    const sf_exponent = this.findSFExponent(range);

    const px_val    = (max - min) / axis_size;
    let factor    = Math.pow(10, sf_exponent);
    let dist      = Number.MAX_VALUE;
    const divisions = SimpleChart.LABEL_DIVISIONS;
    const div_len   = divisions.length;
    let div_idx   = -1;

    // consider every possible division until it produces too small a label gap
    while(dist > min_dist) {
      ++div_idx;
      if(div_idx === div_len) {
        div_idx = 0;
        factor /= 10;
      }

      dist = (divisions[div_idx] * factor) / px_val;
    }

    // step back one, this is our best division
    --div_idx;
    if(div_idx === -1) {
      div_idx = div_len - 1;
      factor *= 10;
    }

    const mkrs  = [];
    const div   = divisions[div_idx] * factor;
    const round = div < 1;
    const dp    = round ? String(div).split('.')[1].length : 0;
    let mkr   = Math.ceil(min / div) * div;

    // generate array of markers, format values according to calculated dp
    while(mkr <= max) {
      mkrs.push(mkr.toFixed(dp));
      mkr = round ? Number((mkr + div).toFixed(dp)) : mkr + div;
    }

    return mkrs;
  }


  // tests if a given string fits within a maximum width, truncating when necessary. Measurements are based on the canvas font
  // settings when invoked
  // @param  text      the text to be truncated
  // @param  max_width the width to constrain the text to 
  // @return the truncated string, or unmodified when it doesn't exceed the given width
  truncateText(text, max_width) {
    let {
      width
    } = this.ctx.measureText(text);
    let truncated = false;

    while ((width > max_width) && (text.length > 0)) {
      truncated = true;
      text      = text.substr(0, text.length - 1);
      ({
        width
      } = this.ctx.measureText(text + SimpleChart.TRUNCATION_SUFFIX));
    }

    if (truncated) { return text + SimpleChart.TRUNCATION_SUFFIX; } else { return text; }
  }


  // applies a coloured gradient mask to the data drawn to a chart. This is only used for line charts to apply more meaningful
  // colouring. Gradient masks are applied vertically
  // @param  mask    an array of objects each with properties colour and pos representing the colour and position respectively 
  //                 of each colour stop
  // @param  y_axis  an object containing info in the y-axis as well as a function to convert a y value into a y-coordinate
  applyGradientMask(mask, y_axis) {

    //if the max/min y values are the same, we do not need to show a gradient.
    if(y_axis.max === y_axis.min) { return; }

    Util.sortByProperty(mask, 'pos', true);

    const left   = SimpleChart.MARGIN_LEFT;
    const top    = SimpleChart.MARGIN_TOP;
    const width  = this.cvs.width - left - SimpleChart.MARGIN_RIGHT;
    const height = this.cvs.height - top - SimpleChart.MARGIN_BOTTOM;

    const col_bottom = mask[0].pos;
    let col_top    = mask[mask.length - 1].pos;
    let col_range  = col_top - col_bottom;

    if (col_range === 0) {
      col_range = 1e-5;
      col_top  += col_range;
    }
  
    const init_comp_op = this.ctx.globalCompositeOperation;
    const grd          = this.ctx.createLinearGradient(0, y_axis.yToPx(col_bottom), 0, y_axis.yToPx(col_top));

    for (var colour_stop of Array.from(mask)) { grd.addColorStop((colour_stop.pos - col_bottom) / col_range, colour_stop.colour); }

    this.ctx.beginPath();
    this.ctx.globalCompositeOperation = 'source-atop';
    this.ctx.fillStyle = grd;
    this.ctx.fillRect(left, top, width, height);

    return this.ctx.globalCompositeOperation = init_comp_op;
  }


  // adds the title for the chart. Formatting options are defined in the class static configuration properties
  // also stores the boundaries of the title so it may be cleared from the canvas later
  // @param  title   the title
  drawTitle(title) {
    this.ctx.font      = SimpleChart.TITLE_FONT_STYLE + ' ' + SimpleChart.TITLE_FONT_SIZE + 'px ' + SimpleChart.TITLE_FONT;
    this.ctx.fillStyle = SimpleChart.TITLE_COLOUR;
    this.ctx.textAlign = 'center';
    this.ctx.beginPath();

    const lines       = this.splitTextIntoLines(title, this.ctx.font, this.cvs.width);
    const line_height = SimpleChart.TITLE_FONT_SIZE * 1.2;
    const centre      = this.cvs.width / 2;
    for (let idx = 0; idx < lines.length; idx++) { var line = lines[idx]; this.ctx.fillText(line, centre, line_height * (idx + 1)); }

    return this.titleBounds = {
      x: (this.cvs.width / 2) - (this.ctx.measureText(title).width / 2),
      y: SimpleChart.TITLE_FONT_SIZE * 0.5,
      w: this.ctx.measureText(title).width,
      h: line_height * lines.length
    };
  }


  // breaks a single string into separate lines to fit a given width. Long segments without spaces can still
  // exceed the given width
  // @param  text  the text to be broken
  // @param  font  the font and it's styling as a string in canvas format, e.g. '10px Verdana' or 'bold 2em sans-serif'
  // @param  width the width to which the text should be constrained
  // @return an array of strings, representing the separate lines
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


  // triggered whenever the mouse moves over the chart canvas. This invokes testHover on a timeout
  // to throttle the number of hover tests being performed
  // @param  ev  the onmousemove event
  evMouseMove(ev) {
    clearTimeout(this.mouseMoveTmr);
    return this.mouseMoveTmr = setTimeout(this.testHover, SimpleChart.MOUSE_MOVE_THROTTLE_DELAY, ev);
  }


  // invokes a datum search routine based on the type of chart drawn
  // @param  ev  the onmousemove event which invoked testHover
  testHover(ev) {
    if (this.testHoverLabel(ev)) { return; }

    switch (this.type) {
      case SimpleChart.TYPE_LINE:
        return this.testHoverLine(ev);

      case SimpleChart.TYPE_BAR:
        return this.testHoverBar(ev);
    }
  }


  // tests if the mouse is positioned over a label
  // @param  ev  the onmousemove event which invoked execution
  // @return     boolean indicating wether label interaction has been detected
  testHoverLabel(ev) {
    let mouse_coords = Util.resolveMouseCoords(this.cvs, ev);

    // fail if mouse is above the x-axis
    if (mouse_coords.y <= (this.cvs.height - SimpleChart.MARGIN_BOTTOM)) {
      this.hideTooltip();
      return false;
    }

    // if the pixel is blank (has an alpha channel of zero) it is safe to assume we're not hovering over anything
    if (!(this.ctx.getImageData(mouse_coords.x, mouse_coords.y, 1, 1).data[3] > 0)) {
      this.hideTooltip();
      return false;
    }

    const datum_width  = this.coords[1].x - this.coords[0].x;
    const offset_x     = this.type === SimpleChart.TYPE_BAR ? SimpleChart.MARGIN_LEFT : SimpleChart.MARGIN_LEFT - (datum_width / 2);
    const idx          = Math.floor((mouse_coords.x - offset_x) / datum_width);
    const {
      datum
    } = this.coords[idx];
    mouse_coords = Util.resolveMouseCoords(this.tooltip.parentElement != null ? this.tooltip.parentElement : this.tooltip.parentNode, ev);
    this.showTooltip(datum, mouse_coords.x, mouse_coords.y);
  
    return true;
  }


  // finds the nearest datum to the mouse coordinates and displays the tooltip if within a particular distance
  // @param  ev  the onmousemove event which triggered execution
  testHoverLine(ev) {
    let coord;
    let mouse_coords = Util.resolveMouseCoords(this.cvs, ev);
    const search       = Util.binaryIndexOf(this.coords, mouse_coords.x, 'x');

    // include neighbouring data in search given that we're unlikely to be hovered directly over the exact
    // coordinates of a datum
    const test_data = [ this.coords[search.idx] ];
    if (this.coords[search.idx - 1] != null) { test_data.push(this.coords[search.idx - 1]); }
    if (this.coords[search.idx + 1] != null) { test_data.push(this.coords[search.idx + 1]); }

    const dists = [];
    for (coord of Array.from(test_data)) {
      var dx = coord.x - mouse_coords.x;
      var dy = coord.y - mouse_coords.y;
      dists.push({ dist: Math.sqrt((dx * dx) + (dy * dy)), coord });
    }

    Util.sortByProperty(dists, 'dist', true);

    if (!(dists[0].dist <= SimpleChart.LINE_DATUM_HOVER_RADIUS)) {
      this.hideTooltip();
      return;
    }

    const {
      datum
    } = dists[0].coord;
    if ((datum.device_type == null) && !(datum.instances == null) && !(!datum.instances.length > 0)) { datum.device_type = datum.instances[0].type; }

    mouse_coords = Util.resolveMouseCoords(this.tooltip.parentElement != null ? this.tooltip.parentElement : this.tooltip.parentNode, ev);
    return this.showTooltip(datum, mouse_coords.x, mouse_coords.y);
  }


  // decides if the mouse is hovering over a datum and displays the tooltip if so
  // @param  ev  the onmousemove event which triggered execution
  testHoverBar(ev) {
    let mouse_coords = Util.resolveMouseCoords(this.cvs, ev);

    // if the pixel is blank (has an alpha channel of zero) it is safe to assume we're not hovering over anything
    if (!(this.ctx.getImageData(mouse_coords.x, mouse_coords.y, 1, 1).data[3] > 0)) {
      this.hideTooltip();
      return;
    }

    const search = Util.binaryIndexOf(this.coords, mouse_coords.x, 'centre');
  
    const test_data = [ this.coords[search.idx] ];
    if (this.coords[search.idx - 1] != null) { test_data.push(this.coords[search.idx - 1]); }
    if (this.coords[search.idx + 1] != null) { test_data.push(this.coords[search.idx + 1]); }

    for (var coord of Array.from(test_data)) {
      if ((mouse_coords.x >= coord.x) && (mouse_coords.x <= (coord.x + coord.width)) && (mouse_coords.y >= coord.y) && (mouse_coords.y <= (coord.y + coord.height))) {
        mouse_coords = Util.resolveMouseCoords(this.tooltip.parentElement != null ? this.tooltip.parentElement : this.tooltip.parentNode, ev, true);
        var {
          datum
        } = coord;
        if ((datum.device_type == null) && !(datum.instances == null) && !(!datum.instances.length > 0)) { datum.device_type = datum.instances[0].type; }
        this.showTooltip(datum, mouse_coords.x, mouse_coords.y);
        return;
      }
    }

    return this.hideTooltip();
  }


  // displays a tooltip and constructs it's caption using the relevant datum
  // @param  datum the datum over which the mouse is hovering
  // @param  x     the current relative x-coordinate of the mouse
  // @param  y     the current relative y-coordinate of the mouse
  showTooltip(datum, x, y) {
    let key;
    this.showingHint = true;
    let caption = SimpleChart.TOOLTIP_CAPTION;
    for (key in datum) { var value = datum[key]; caption = Util.substitutePhrase(caption, key, value); }
  
    // remove any unaccounted substitutions
    const keys    = Util.getSubstitutionKeys(caption);
    for (key of Array.from(keys)) { caption = Util.substitutePhrase(caption, key, null); }

    caption = Util.cleanUpSubstitutions(caption);

    this.tooltip.innerHTML = caption;
    const container_dims = (this.tooltip.parentElement != null ? this.tooltip.parentElement : this.tooltip.parentNode).getCoordinates();
    const tip_dims       = this.tooltip.getCoordinates();

    if ((x + tip_dims.width) > (container_dims.width - 10)) { x = container_dims.width - tip_dims.width - 50; }
    if ((y + tip_dims.height) > (container_dims.height - 10)) { y = container_dims.height - tip_dims.height - 50; }

    Util.setStyle(this.tooltip, 'visibility', 'visible');
    Util.setStyle(this.tooltip, 'left', x + 'px');
    Util.setStyle(this.tooltip, 'top', y + 'px');
    if (SimpleChart.TOOLTIP_COLOUR_FIELD != null) { Util.setStyle(this.tooltip, 'background', datum[SimpleChart.TOOLTIP_COLOUR_FIELD]); }

    return this.dispatchEvent('onshowtooltip', datum);
  }


  // hides the tooltip and dispatches onhidetooltip custom event
  hideTooltip() {
    if (!this.showingHint) { return; }
    Util.setStyle(this.tooltip, 'background', this.tooltipInitColour);
    Util.setStyle(this.tooltip, 'visibility', 'hidden');
    this.showingHint = false;
    return this.dispatchEvent('onhidetooltip');
  }


  // adds an x-axis label and draws a faint rectangle over the label, this is used in mouse hover detection
  // long labels are truncated to fit the supplied maximum width
  // @param  caption   the label caption
  // @param  x         the x-coordinate, note that x-axis labels are centre aligned
  // @param  y         the y-coordinate
  // @param  max_width the maximum allowed width for the label
  // @param  height    the label font height, this is used to draw the mouse hover rectangle
  addXLabel(caption, x, y, max_width, height) {
    this.ctx.beginPath();
    this.ctx.fillStyle = SimpleChart.LABEL_FONT_COLOUR;
    this.ctx.fillText(this.truncateText(caption, max_width), x, y);

    // add a (nearly) hidden rectangle overlay. This is used as a 'hit' area for hover detection
    // The mouse hover uses the alpha value of the hovered pixel do decide if anything is there
    // therefore wether or not to decide if the mouse is over a datum or label
    this.ctx.fillStyle = 'rgba(255,255,255,0.01)';
    return this.ctx.fillRect(x - (max_width / 2), y, max_width, -SimpleChart.LABEL_FONT_SIZE);
  }
};
SimpleChart.initClass();
export default SimpleChart;
