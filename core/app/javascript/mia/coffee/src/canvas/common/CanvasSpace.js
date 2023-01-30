/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from './util/Util';
import SimpleRenderer from './gfx/SimpleRenderer';

import RackObject from '../../canvas/irv/view/RackObject';
import Rack from '../../canvas/irv/view/Rack';
import Chassis from '../../canvas/irv/view/Chassis';
import Machine from '../../canvas/irv/view/Machine';
import PowerStrip from '../../canvas/irv/view/PowerStrip';
import ViewModel from '../../canvas/irv/ViewModel';
import Profiler from 'Profiler'

class CanvasSpace {
  static initClass() {
    // statics overwritten by config
    this.PADDING              = 100;
    this.H_PADDING            = 100;
    this.POWER_STRIP_PADDING  = 50;
    this.RACK_H_SPACING       = 50;
    this.RACK_V_SPACING       = 100;
    this.FPS                  = 24;
    this.BOTH_VIEW_PAIR_PADDING    = 150;
    this.ADDITIONAL_ROW_TOLERANCE  = 3;

    this.U_LBL_SCALE_CUTOFF        = .20;
    this.NAME_LBL_SCALE_CUTOFF     = .01;
  }

  // XXX This class has a single derived class; this constructor isn't compatible
  // with calling super in the derieved class. So its disabled until I figure
  // out if something better is needed.
  // constructor(rackEl, chartEl, model, rackParent) {
  //   this.draw = this.draw.bind(this);
  //   this.rackEl = rackEl;
  //   this.chartEl = chartEl;
  //   this.model = model;
  //   this.rackParent = rackParent;
  //   Profiler.begin(Profiler.DEBUG);
  //   this.createGfx();
  //
  //   this.scrollAdjust = Util.getScrollbarThickness();
  //
  //   RackObject.MODEL     = this.model;
  //   RackObject.RACK_GFX  = this.rackGfx;
  //
  //   this.setUpRacks();
  //
  //   this.setScale();
  //
  //   this.draw();
  //   this.centreRacks();
  //   Profiler.end(Profiler.DEBUG);
  // }

  createGfx() {
    return this.rackGfx  = this.createGfxLayer(this.rackEl, 0, 0, 1, 1, 1);   // bottom layer, draws rack and device images
  }

  setScale() {
    let final_scale;
    const max_scale = 0.30;
    const max_height = $('interactive_canvas_view').getCoordinates().height;
    if (((this.tallestRack+CanvasSpace.PADDING)*max_scale) > max_height) {
      final_scale = max_scale * (max_height/((this.tallestRack+CanvasSpace.PADDING)*max_scale));
    } else {
      final_scale = max_scale;
    }
    return this.rackGfx.setScale(final_scale);
  }

  // draw all racks
  draw() {
    Profiler.begin(Profiler.CRITICAL);
    for (var rack of Array.from(this.racks)) { rack.draw(false, false); }
    return Profiler.end(Profiler.CRITICAL);
  }

  setUpRacks() {
    this.racks = [];

    this.max_u  = 0;
    const racks  = this.model.racks();

    this.tallestRack = 0;
    for (var rack of Array.from(racks)) {
      if (rack.uHeight > this.max_u) { this.max_u = rack.uHeight; }
      var new_rack = new Rack(rack);
      this.racks.push(new_rack);
      if (new_rack.hasFocus()) {
        new_rack.refreshRackFocus(this.model);
      }
      var thisRackHeight = Rack.IMAGES_BY_TEMPLATE[rack.template.id].slices.front.top.height + Rack.IMAGES_BY_TEMPLATE[rack.template.id].slices.front.btm.height + (RackObject.U_PX_HEIGHT * rack.uHeight);
      if (thisRackHeight > this.tallestRack) { this.tallestRack = thisRackHeight; }
    }
    
    this.rowHeight   = (CanvasSpace.PADDING * 2) + this.tallestRack;

    return this.arrangeRacks();
  }

  // determine how the racks are layed out. This is a two phase operation: (1) find the number of rows/cols with a width/heigth ratio
  // which most closely matches the width/height ratio of the containing div (this should geometrically be the arrangement which results in
  // minimum whitespace) (2) systematically adjust the row width in an attempt to reduce the number of empty spaces on the last row. This
  // is to avoid the situation where the row width is say 20 racks but the last row has only three racks (and a lot of white space after
  // it). The second phase can lead to a significant digression from the first phase.
  arrangeRacks() {
    let row_width;
    const alternate_pad  = front_and_rear ? CanvasSpace.BOTH_VIEW_PAIR_PADDING : 0;
    const delta          = front_and_rear ? 2 : 1;
    const factor         = 1.5;

    const dims             = Util.getElementDimensions(this.rackEl);
    const dims_ratio       = dims.width / dims.height;
    const num_racks        = this.racks.length;
    let total_rack_width = 0;
    for (var oneR of Array.from(this.racks)) {
      total_rack_width += oneR.width + CanvasSpace.RACK_H_SPACING + alternate_pad;
    }
    const average_rack_width = total_rack_width/num_racks;
    let best_width     = total_rack_width;
    let best_fit_ratio = 0;
    let count          = 0;
    var front_and_rear = this.model.face() === ViewModel.FACE_BOTH;
    // calculate row width which produces dimensions that most closely match the ratio of container width and height
    // aka best fit row width
    let num_rows = 0;
    let total_width = 0;
    let total_height = 0;
    while (count < num_racks) {
      total_width   += ((this.racks[count].width + CanvasSpace.RACK_H_SPACING)*delta) + alternate_pad;
      num_rows      = Math.ceil(total_rack_width / total_width);
      total_height  = (((this.tallestRack + CanvasSpace.RACK_V_SPACING) * num_rows) - CanvasSpace.RACK_V_SPACING) + (CanvasSpace.PADDING * 2);
      var ratio         = (total_width / total_height) * factor;

      if (Math.abs(ratio - dims_ratio) < Math.abs(best_fit_ratio - dims_ratio)) {
        best_width     = total_width;
        best_fit_ratio = ratio;
      }

      count += delta;
    }

    const max_row_width = best_width;
  
    // re calculate the row_width to distribute all the items in all the rows
    if (total_rack_width > max_row_width) {
      num_rows  = Math.ceil(total_rack_width / max_row_width);
      row_width = Math.abs((total_rack_width/num_rows)+average_rack_width);
    } else {
      row_width = total_rack_width;
      num_rows  = 1;
    }

    this.num_rows = num_rows;

    let actual_width = row_width;
    let actual_height = (num_rows * this.tallestRack) + ((num_rows - 1) * CanvasSpace.RACK_V_SPACING);
    actual_width  += CanvasSpace.PADDING * 2;
    actual_height += CanvasSpace.PADDING * 2;

    if (this.model.showingPowerStrips() && (this.powerStrips.length > 0)) {
      actual_width += (PowerStrip.POWERSTRIP_H_PADDING*2)+((this.powerStrips[0].width+PowerStrip.POWERSTRIP_H_SPACING)*this.powerStrips.length);
    }

    //Adding extra padding when showing DCRV, so the user has more space in the top, to start a selection rubber band.
    if (this.model.showingFullIrv()) {
      actual_height += (CanvasSpace.PADDING * 2);
    }

    this.racksWidth  = actual_width;
    if (this.model.showingFullIrv() || this.model.showingRacks()) {
      const scale_x = (dims.width - this.scrollAdjust) / actual_width;
      const scale_y = (dims.height - this.scrollAdjust) / actual_height;
      const final_scale = scale_x > scale_y ? scale_y : scale_x;

      const actual_width_div = Math.floor(actual_width * final_scale);

      this.racksWidth += CanvasSpace.H_PADDING*2;
    }

    this.racksHeight = actual_height;

    // set rack coordinates using @tallestRack to offset shorter racks
    count = 0;
    let acum_rack_width = 0;
    let prev = 0;
    let row_num = 0;
    while (count < num_racks) {
      var rack_x;
      prev = row_num;
      var col_num = count - (row_num * row_width);
      var rack    = this.racks[count];
      if ((acum_rack_width + rack.width) > actual_width) {
        row_num += 1;
        acum_rack_width = 0;
      }
      var rack_y = (CanvasSpace.PADDING + ((this.tallestRack + CanvasSpace.RACK_V_SPACING) * row_num) + this.tallestRack) - rack.height;
      if (num_racks === 1) {
        rack_x  = (this.racksWidth/2) - (rack.width/2);
      } else {
        if (this.model.showingRacks() && !this.model.showingFullIrv()) {
          rack_x  = ((this.racksWidth/2) - (rack.width + (CanvasSpace.RACK_H_SPACING/2))) + acum_rack_width;
        } else {
          // In DCRV racks are rendered a bit lower in the Y axis, since there is more padding.
          if (this.num_rows > 1) { rack_y  += CanvasSpace.PADDING; }
          rack_x  = CanvasSpace.H_PADDING + CanvasSpace.PADDING + acum_rack_width;
        }
      }
      rack.setCoords(rack_x, rack_y);
      acum_rack_width += rack.width + CanvasSpace.RACK_H_SPACING;
      ++count;
    }

    return this.rackGfx.setDims(this.racksWidth, this.racksHeight);
  }

  // this visually centres all racks according to the available space in the containing div
  centreRacks() {
    const rack_dims = this.rackEl.getCoordinates();
    const cvs_dims  = this.rackGfx.cvs.getCoordinates();
    const offset    = { x: rack_dims.width - this.scrollAdjust - cvs_dims.width, y: rack_dims.height - this.scrollAdjust - cvs_dims.height };
  
    if (offset.x < 0) { offset.x = 0; }
    if (offset.y < 0) { offset.y = 0; }

    const centre_x = (offset.x / 2) + 'px';
    const centre_y = (offset.y / 2) + 'px';

    Util.setStyle(this.rackGfx.cvs, 'left', centre_x);

    return Util.setStyle(this.rackGfx.cvs, 'top', centre_y);
  }

  // creates an instance of a SimpleRenderer layer
  // @param  container   a reference to a DOM element to which the layer will be appended
  // @param  x           float, the pixel x coordinate to position the new layer
  // @param  y           float, the pixel y coordinate to position the new layer
  // @param  width       int, the width of the layer
  // @param  height      int, the height of the new layer
  // @param  scale       optional float, the initial scale of the new layer
  createGfxLayer(container, x, y, width, height, scale) {
    if (scale == null) { scale = 1; }
    const gfx = new SimpleRenderer(container, width, height, scale, CanvasSpace.FPS);
    Util.setStyle(gfx.cvs, 'position', 'absolute');
    Util.setStyle(gfx.cvs, 'left', x + 'px');
    Util.setStyle(gfx.cvs, 'top', y + 'px');

    // For debugging canvas layer purposes.
    // Util.setStyle(gfx.cvs, 'background', 'blue')
    // Util.setStyle(gfx.cvs, 'opacity', '0.2')
    //if layer_name?
    //  gfx.addText(
    //    x       : 0
    //    y       : 300
    //    font    : "20px Karla"
    //    align   : "left"
    //    caption : layer_name
    //    alpha   : 1
    //    fill    : "#000000")

    return gfx;
  }
};
CanvasSpace.initClass();
export default CanvasSpace;
