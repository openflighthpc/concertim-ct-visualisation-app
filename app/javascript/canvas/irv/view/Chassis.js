/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import BarMetric from 'canvas/common/widgets/BarMetric';
import AssetManager from 'canvas/irv/util/AssetManager';
import ViewModel from 'canvas/irv/ViewModel';
import RackObject from 'canvas/irv/view/RackObject';
import Machine from 'canvas/irv/view/Machine';
import Highlight from 'canvas/irv/view/Highlight';
import ChassisLabel from 'canvas/irv/view/ChassisLabel';
import Profiler from 'Profiler';


class Chassis extends RackObject {
  static initClass() {

    // statics overwritten by config
    this.DEPTH_SHADE_FILL       = '#0';
    this.DEPTH_SHADE_MAX_ALPHA  = .8;
    this.UNKNOWN_FILL           = '#ff00ff';
    this.DEFAULT_WIDTH          = 370;
  }


  constructor(def, parent) {
    let face;
    super(def, 'chassis', parent);
    this.setMetricVisibility = this.setMetricVisibility.bind(this);
    this.uHeight      = def.template.height;
    this.model        = def.template.model;

    // max image dimensions are used to define the metric dims
    let max_width  = 0;
    let max_height = 0;
    this.facing = def.facing;

    this.images = {};
    if (def.template.images.front != null) {
      face          = this.frontFacing ? ViewModel.FACE_FRONT : ViewModel.FACE_REAR;
      this.images[face] = AssetManager.CACHE[RackObject.IMAGE_PATH + def.template.images.front];
      if (this.images[face].width > max_width) { max_width     = this.images[face].width; }
      if (this.images[face].height > max_height) { max_height    = this.images[face].height; }
    } else {
      face          = this.frontFacing ? ViewModel.FACE_FRONT : ViewModel.FACE_REAR;
      this.images[face] = this.getBlanker(Chassis.DEFAULT_WIDTH, RackObject.U_PX_HEIGHT * this.uHeight);
      if (this.images[face].width > max_width) { max_width     = this.images[face].width; }
      if (this.images[face].height > max_height) { max_height    = this.images[face].height; }
    }

    if (def.template.images.rear != null) {
      face          = this.frontFacing ? ViewModel.FACE_REAR : ViewModel.FACE_FRONT;
      this.images[face] = AssetManager.CACHE[RackObject.IMAGE_PATH + def.template.images.rear];
      if (this.images[face].width > max_width) { max_width     = this.images[face].width; }
      if (this.images[face].height > max_height) { max_height    = this.images[face].height; }
    } else {
      face          = this.frontFacing ? ViewModel.FACE_REAR : ViewModel.FACE_FRONT;
      this.images[face] = this.getBlanker(Chassis.DEFAULT_WIDTH, RackObject.U_PX_HEIGHT * this.uHeight);
      if (this.images[face].width > max_width) { max_width     = this.images[face].width; }
      if (this.images[face].height > max_height) { max_height    = this.images[face].height; }
    }

    this.images.both = this.images.front;

    const face_img = this.images[RackObject.MODEL.face()];

    this.x      = 0;
    this.y      = 0;
    this.width  = (face_img != null) ? face_img.width : 0;
    this.height = (face_img != null) ? face_img.height : 0;

    this.complex       = (def.template.rows > 1) || (def.template.columns > 1);
    this.visible       = false;
    this.uStartDef     = def.uStart;
    this.slotsOccupied = [];
    this.assets        = [];
    //Profiler.trace(Profiler.CRITICAL, '%s %s %s', @complex, def.template.rows, def.template.columns) if @id is "1288" or @id is "1285"
    if (this.complex) {
      this.slotWidth  = (this.images.front.width - this.template.padding.left - this.template.padding.right) / this.template.columns;
      this.slotHeight = (this.images.front.height - this.template.padding.top - this.template.padding.bottom) / this.template.rows;
    } else {
      this.slotWidth  = this.images.front.width / def.Slots.length;
      this.slotHeight = this.images.front.height;
    }

    this.slotIds = {};
    for (var slot of Array.from(def.Slots)) {

      if (this.slotIds[slot.column] == null) { this.slotIds[slot.column] = {}; }
      this.slotIds[slot.column][slot.row] = slot.id;

      if (slot.Machine == null) { continue; }
      var machine = new Machine(slot.Machine, this);

      this.children.push(machine);
      if (machine.row != null) {
        if (this.slotsOccupied[machine.row] == null) { this.slotsOccupied[machine.row] = []; }
        this.slotsOccupied[machine.row][machine.column] = true;
      }
    }

    if (RackObject.MODEL.metricLevel !== undefined) {
      this.subscriptions.push(RackObject.MODEL.metricLevel.subscribe(this.setMetricVisibility));

      this.metric = new BarMetric(this.group, this.id, this, 0, 0, max_width, max_height, RackObject.MODEL);
      this.setIncluded();
    } else {
      this.included = true;
    }

    this.comparisonName = __guard__(this.nameToShow(), x => x.toLowerCase());
    this.nameLabel = new ChassisLabel(this.infoGfx, this, RackObject.MODEL);
  }

  destroy() {
    if (this.highlight != null) { this.highlight.destroy(); }
    this.metric.destroy();
    super.destroy();
    this.showNameLabel(false);
  }

  setCoords(x, y) {
    this.x = x;
    this.y = y;
    this.alignMachines();
    if (this.metric != null) { return this.metric.setCoords(this.x, this.y); }
  }

  uStart() {
    return this.uStartDef;
  }

  // Returs the rack where the chassis is placed, if they are placed in one.
  // Sorry about this not very elegant: parent.group is 'racks'
  // Not using the 'intanceof Rack' here, because importing the Rack class in this Chassis class, creates a require.js tiemout issue when loading.
  rack() {
    const parent = this.parent();
    if (parent.group === 'racks') {
      return parent;
    } else {
      return null;
    }
  }

  setCoordsBasedOnUStart() {
    const x = (this.parent().x + (this.parent().width / 2)) - (this.width/2);
    const y = (RackObject.U_PX_HEIGHT * (this.parent().uHeight - this.uStart() - this.uHeight)) + this.parent().chassisOffsetY + this.parent().y;
    return this.setCoords(x, y);
  }

  depth() {
    if ((this.template != null) && (this.template.depth != null)) {
      return this.template.depth;
    }
  }

  showFreeSpacesForBlade() {
    this.availableSpaces = [];
    const free_slots_for_this_chassis = this.getFreeSlots();
    if (free_slots_for_this_chassis.length > 0) {
      this.availableSpaces = this.availableSpaces.concat(free_slots_for_this_chassis);
      return Array.from(free_slots_for_this_chassis).map((oneFreeSlot) =>
        this.createFreeSpaceHighlight(oneFreeSlot.x,oneFreeSlot.y,this.slotWidth,this.slotHeight));
    }
  }

  placedInHoldingArea() {
    if (this.parent().isHoldingArea() === true) {
      return true;
    } else {
      return false;
    }
  }

  draw(show_name_label) {
    if (show_name_label == null) {
      show_name_label = RackObject.MODEL.displayingBuildStatus();
    }
    Profiler.begin(Profiler.DEBUG, this.draw, this.name);
    // clear
    for (var asset of Array.from(this.assets)) { this.gfx.remove(asset); }
    this.assets = [];
    this.showNameLabel(show_name_label);

    // @facing is the real aspect of the device
    // @face is the face that will be currently shown for the current rack

    let face = this.facing === 'b' ? ViewModel.FACE_REAR : ViewModel.FACE_FRONT;

    // If viewing both faces, then swap the view of the current chassis,
    // depending of which face is the current rack.
    if (RackObject.MODEL.face() === ViewModel.FACE_BOTH) {
      if (((this.bothView === ViewModel.FACE_FRONT) && (this.facing === 'b')) || ((this.bothView === ViewModel.FACE_REAR) && (this.facing === 'f'))) {
        face = ViewModel.FACE_REAR;
      } else if (((this.bothView === ViewModel.FACE_REAR) && (this.facing === 'b')) || ((this.bothView === ViewModel.FACE_FRONT) && (this.facing === 'f'))) {
        face = ViewModel.FACE_FRONT;
      }
    }

    if (RackObject.MODEL.face() === ViewModel.FACE_REAR) { 
      if (this.facing === 'b') {
        face = ViewModel.FACE_FRONT;
      } else if (this.facing === 'f') {
        face = ViewModel.FACE_REAR;
      }
    }
        
    if (this.placedInHoldingArea()) { face = ViewModel.FACE_FRONT; }
    this.face = face;

    if (this.metric != null) { this.setMetricVisibility(); }
    this.img = this.images[this.face];
    if (this.img) {
      this.visible = true;
      // centre align
      this.x = (this.x + (this.width / 2)) - (this.img.width / 2);
      // chassis front/rear images may have different sizes
      this.width  = this.img.width;
      this.height = this.img.height;

      let img_alpha = this.included ? 1 : RackObject.EXCLUDED_ALPHA;

      // apply a fade for non full depth chassis in rear view
      if ((this.template.depth === 1) && (((face === ViewModel.FACE_REAR) && this.frontFacing) || ((face === ViewModel.FACE_FRONT) && !this.frontFacing))) {
        img_alpha = this.included ? (Chassis.DEPTH_SHADE_MAX_ALPHA * .5) : RackObject.EXCLUDED_ALPHA;
      }

      this.assets.push(this.gfx.addImg({ img: this.img, x: this.x, y: this.y, alpha: img_alpha }));

      // add a fade if in metric view mode
      if (RackObject.MODEL.displayingMetrics() && !RackObject.MODEL.displayingImages()) {
        this.assets.push(this.gfx.addRect({ fx: 'source-atop', x: this.x, y: this.y, width: this.width, height: this.height, fill: RackObject.METRIC_FADE_FILL, alpha: RackObject.METRIC_FADE_ALPHA }));
      }
    } else {
      this.visible = false;
    }

    this.alignMachines();
    super.draw();
    return Profiler.end(Profiler.DEBUG, this.draw);
  }

  select() {
    if (this.highlight == null) {
      const highlight_border = RackObject.MODEL.showingFullIrv() && RackObject.MODEL.overLBC();
      this.highlight = new Highlight(Highlight.MODE_SELECT, this.x, this.y, this.width, this.height, this.alertGfx, 'rect', {}, highlight_border);
      if (this.fullDepth() || this.noDeviceBlocking()) {
        return this.selectOtherInstances();
      }
    }
  }


  deselect() {
    if (this.highlight != null) {
      this.highlight.destroy();
      this.highlight = null;
      return this.deselectOtherInstances();
    }
  }

  updatePosition() {
    const data = {rack_id:this.parent().id, start_u:(this.uStart()+1), facing: (this.face === 'front' ? 'f' : 'b'), type:"RackChassis"};
    this.conf = {action:'update_position', data};
    return this.create_request();
  }

  moveToOrFromHoldingArea(new_type, rack_id, start_u, new_face) {
    const data = {rack_id, start_u:start_u, type:new_type, show_in_dcrv: false, facing:new_face};
    this.conf = {action:'update_position', data};
    return this.create_request();
  }

  nameToShow() {
    if (this.complex) {
      return this.name;
    } else if (this.children[0] != null) {
      return this.children[0].buildStatus;
    }
  }

  buildStatus() {
    if (this.complex) {
      throw "not supported for complex chassis";
    } else if (this.children[0] != null) {
      return this.children[0].buildStatus;
    }
  }

  showDrag() {
    if (this.highlightDragging != null) {
      this.highlightDragging.destroy();
      delete this.highlightDragging;
    }

    return this.highlightDragging = new Highlight(Highlight.MODE_DRAG, this.x, this.y, this.width, this.height, this.infoGfx);
  }


  hideDrag() {
    if (this.highlightDragging != null) {
      this.highlightDragging.destroy();
      return delete this.highlightDragging;
    }
  }


  isOfSameType(unit_image_name) {
    return (this.template != null) && (this.template.images != null) && (this.template.images.unit != null) && (this.template.images.unit === unit_image_name);
  }

  alignMachines() {
    if (this.images[RackObject.MODEL.face()] != null) {
      if (this.template != null) {
        return (() => {
          const result = [];
          for (var child of Array.from(this.children)) {
            var x_extra = (child.column * this.slotWidth) + this.template.padding.left;
            if (this.face === ViewModel.FACE_REAR) {
              x_extra = this.width - x_extra - this.slotWidth;
            }
            result.push(child.setCoords(this.x + x_extra, this.y + this.template.padding.top + ((this.template.rows - child.row) * this.slotHeight)));
          }
          return result;
        })();
      } else {
        return (() => {
          const result1 = [];
          for (var child of Array.from(this.children)) {                 result1.push(child.setCoords(this.x, this.y));
          }
          return result1;
        })();
      }
    }
  }


  selectWithinOld(box, inclusive) {
    let child, group, test_contained_h, test_contained_v;
    const groups = RackObject.MODEL.groups();
    const selected = {};
    for (group of Array.from(groups)) { selected[group] = {}; }

    if (inclusive) {
      for (child of Array.from(this.children)) {
        var test_left = (box.left >= child.x) && (box.left <= (child.x + child.width));
        var test_right = (box.right >= child.x) && (box.right <= (child.x + child.width));
        test_contained_h = (box.left < child.x) && (box.right > (child.x + child.width));
        var test_top = (box.top >= child.y) && (box.top <= (child.y + child.height));
        var test_bottom = (box.bottom >= child.y) && (box.bottom <= (child.y + child.height));
        test_contained_v = (box.top < child.y) && (box.bottom > (child.y + child.height));

        if ((test_left || test_right || test_contained_h) && (test_top || test_bottom || test_contained_v)) {
          selected[child.group][child.id] = true;
        }
      }
    } else {
     for (child of Array.from(this.children)) {
        test_contained_h = (box.left <= child.x) && (box.right >= (child.x + child.width));
        test_contained_v = (box.top <= child.y) && (box.bottom >= (child.y + child.height));
      
        if (test_contained_h && test_contained_v) {
          selected[child.group][child.id] = true;
       }
     }
   }

    return selected;
  }


  // Return whether the metric should be shown or not.
  showMetric() {
    const selected         = RackObject.MODEL.selectedDevices();
    const metric_level     = RackObject.MODEL.metricLevel();
    const active_selection = RackObject.MODEL.activeSelection();
    const active_filter    = RackObject.MODEL.activeFilter();
    const filtered         = RackObject.MODEL.filteredDevices();

    if (!this.viewableDevice()) {
      return false;
    }

    if (!RackObject.MODEL.displayingMetrics()) {
      return false;
    }

    const applicableMetricLevel = ((metric_level === this.group) || ((metric_level === ViewModel.METRIC_LEVEL_ALL) && (this.children.length === 0)));
    if (!applicableMetricLevel) {
      return false;
    }

    // Not included in active selection.
    const inCurrentSelection = selected[this.group] != null ? selected[this.group][this.id] : undefined;
    if (active_selection && !inCurrentSelection) {
      return false;
    }

    // Not included in active filter.
    if (active_filter && !filtered[this.group][this.id]) {
      return false;
    }

    if ((this.placedInHoldingArea() === true) && (RackObject.MODEL.showHoldingArea() === false)) {
      return false;
    }

    return true;
  }


  setMetricVisibility() {
    return this.metric.setActive(this.showMetric());
  }


  getSlot(x, y) {
    x -= this.x + this.template.padding.left;
    y -= this.y + this.template.padding.top;
  
    const col = Math.floor(x / this.slotWidth);
    const row = this.template.rows - Math.floor(y / this.slotHeight) - 1;
    //Profiler.trace(Profiler.DEBUG, 'row: %s, col: %s, template row: %s, template col: %s, slot width: %s, slot height: %s', row, col, @template.rows, @template.columns, @slotWidth, @slotHeight)
    if ((row >= 0) && (row < this.template.rows) && (col >= 0) && (col < this.template.columns)) {

      let device = null;
      for (var child of Array.from(this.children)) {
        if ((child.row === row) && (child.column === col)) {
          device = child;
          break;
        }
      }

      return { id: this.slotIds[col][row], row, column: col, device };
    }

    return null;
  }

  updateOccupiedSlots() {
    this.slotsOccupied = [];
    return (() => {
      const result = [];
      for (var oneMachine of Array.from(this.children)) {
        if ((oneMachine.row != null) && (oneMachine.column != null)) {
          if (this.slotsOccupied[oneMachine.row] == null) { this.slotsOccupied[oneMachine.row] = []; }
          result.push(this.slotsOccupied[oneMachine.row][oneMachine.column] = true);
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }
  

  getFreeSlots() {
    this.freeSlots = [];
    for (let one_row = 0, end = this.template.rows-1, asc = 0 <= end; asc ? one_row <= end : one_row >= end; asc ? one_row++ : one_row--) {
      for (var one_col = 0, end1 = this.template.columns-1, asc1 = 0 <= end1; asc1 ? one_col <= end1 : one_col >= end1; asc1 ? one_col++ : one_col--) {
        if ((this.slotsOccupied[one_row] == null) || (this.slotsOccupied[one_row][one_col] == null)) {
          var this_x = (this.x + this.template.padding.left + (one_col * this.slotWidth));
          var this_y = (this.y + this.template.padding.top + ((this.template.rows - one_row - 1) * this.slotHeight));
          this.freeSlots.push({
                            rack_id:parseInt(this.parent().id),
                            chassis_id:parseInt(this.id),
                            slot_id:parseInt(this.slotIds[one_col][one_row]),
                            row:one_row,
                            col:one_col,
                            x:this_x,
                            y:this_y,
                            left: this_x,
                            right: this_x + this.slotWidth,
                            top: this_y,
                            bottom: this_y + this.slotHeight
                          });
        }
      }
    }

    return this.freeSlots;
  }

  removeBlade(blade_id) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.children.length; index++) {
        var oneBlade = this.children[index];
        if (parseInt(oneBlade.id) === blade_id) {
          delete RackObject.MODEL.deviceLookup().devices[blade_id];
          oneBlade.metric.destroy();
          this.children.splice(index,1);
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  addBlade(blade) {
    return this.children.push(blade);
  }
};
Chassis.initClass();
export default Chassis;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
