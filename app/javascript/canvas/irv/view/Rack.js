/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import AssetManager from 'canvas/irv/util/AssetManager';
import ViewModel from 'canvas/irv/ViewModel';

import NameLabel from 'canvas/irv/view/NameLabel';
import RackNameLabel from 'canvas/irv/view/RackNameLabel';
import RackOwnerLabel from 'canvas/irv/view/RackOwnerLabel';
import RackObject from 'canvas/irv/view/RackObject';
import Chassis from 'canvas/irv/view/Chassis';
import ImageLink from 'canvas/irv/view/ImageLink';
import Profiler from 'Profiler'

class Rack extends RackObject {
  static initClass() {

    // statics overwritten by config
    this.U_LBL_OFFSET_X  = 70;
    this.U_LBL_OFFSET_Y  = 39;
    this.U_LBL_FONT      = 'Karla';
    this.U_LBL_FONT_SIZE = 11;
    this.U_LBL_COLOUR    = 'white';
    this.U_LBL_ALIGN     = 'right';

    this.U_LBL_SCALED_FONT  = '';
    this.U_LBL_SCALE_RATIO  = 0.6;
    this.MAX_ZOOM  = 1;

    this.SPACE_PADDING        = 70;

    this.FADE_IN_METRIC_MODE  = true;

    // hard coded and run-time assigned statics
    this.IMAGES_BY_TEMPLATE       = {};
    this.IMAGE_CACHE_BY_U_HEIGHT  = {};
  }


  setImages() {
    Rack.IMAGES_BY_TEMPLATE[this.template.id] = {};
    Rack.IMAGES_BY_TEMPLATE[this.template.id].slices = {
      front: {
        top    : AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_front_top],
        btm    : AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_front_bottom],
        repeat : [AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_repeat_1]]
      },
      rear: {
        top    : AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_rear_top],
        btm    : AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_rear_bottom],
        repeat : [AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_repeat_1]]
      }
    };

    if (this.template.images.rack_repeat_2 != null) {
      Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front.repeat.push(AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_repeat_2]);
      Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.rear.repeat.push(AssetManager.CACHE[RackObject.IMAGE_PATH + this.template.images.rack_repeat_2]);
    }

    if (this.template.rack_repeat_ratio != null) {
      Rack.IMAGES_BY_TEMPLATE[this.template.id].imageRepeatPatern = {front:[],rear:[]};
      Rack.IMAGES_BY_TEMPLATE[this.template.id].repeatBlockSize = (this.template.rack_repeat_ratio.split("-").map(oneV => parseInt(oneV))).reduce((x, y) => x+y);
      return Array.from(this.template.rack_repeat_ratio.split("-")).map((oneR, rIndex) =>
        (() => {
          const result = [];
          for (let oneN = 0, end = oneR-1, asc = 0 <= end; asc ? oneN <= end : oneN >= end; asc ? oneN++ : oneN--) {
            Rack.IMAGES_BY_TEMPLATE[this.template.id].imageRepeatPatern.front.push(Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front.repeat[rIndex]);
            result.push(Rack.IMAGES_BY_TEMPLATE[this.template.id].imageRepeatPatern.rear.push(Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.rear.repeat[rIndex]));
          }
          return result;
        })());
    }
  }



  getImage(oneKey) {
    if (this.frontFacing) {
      switch (oneKey) {
        case "front": return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front;
        case "rear":  return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.rear;
        case "both":  return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front;
      }
    } else {
      switch (oneKey) {
        case "front": return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.rear;
        case "rear":  return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front;
        case "both":  return Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.rear;
      }
    }
  }

  constructor(def) {
    super(def, 'racks');
    Profiler.begin(Profiler.DEBUG, this.constructor);
    this.evSpaceHidden = this.evSpaceHidden.bind(this);
    if (Rack.IMAGES_BY_TEMPLATE[this.template.id] == null) { this.setImages(); }
    this.uHeight = def.uHeight;

    // assign measurements based on image dimensions
    this.chassisOffsetY = Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front.top.height;

    const face_slices = this.getImage(RackObject.MODEL.face());

    this.x      = 0;
    this.y      = 0;
    this.width  = face_slices.top.width;
    this.height = face_slices.top.height + face_slices.btm.height + (RackObject.U_PX_HEIGHT * this.uHeight);

    if (!this.imageCacheExist(this.uHeight,this.template.id)) { this.setImageCache(); }

    this.uLbls           = [];
    this.selected        = false;
    this.visible         = true;
    this.assets          = [];
  
    this.addImageLink();
  
    const len      = def.chassis.length;
    this.chassis = [];
    this.derf = def;
    for (var chassis_def of Array.from(def.chassis)) {
      var chassis = new Chassis(chassis_def, this);
      this.children.push(chassis);
    }

    this.updateOccupied();
    this.parentEl = RackObject.RACK_GFX.containerEl;

    // frontFirst and rearFirst are the list of children (chassis) ordered according to
    // wether they are front mounted. By switching between these when re-drawing we effect
    // the draw order of the children, dictating wether rear mounted chassis will be drawn
    // over the top of front mounted chassis, thus facilitating the different rear and front
    // view layering. E.g. rearFirst will first draw rear mounted chassis, then front mounted
    // over the top giving the appropriate front view chassis layering
    this.frontFirst = Util.sortByProperty(this.children, 'frontFacing', false);
    this.rearFirst  = this.frontFirst.slice(0);
    this.rearFirst.reverse();
  
    if (RackObject.MODEL.metricLevel !== undefined) {
      this.setIncluded();

    } else {
      this.included = true;
    }

    this.owner = def.owner;
    this.buildStatus = def.buildStatus;
    this.cost = def.cost;
    this.nameLabel = new RackNameLabel(this.infoGfx, this, RackObject.MODEL);
    this.ownerLabel = new RackOwnerLabel(this.infoGfx, this, RackObject.MODEL);

    Profiler.end(Profiler.DEBUG, this.constructor);
  }

  addImageLink() {
    // This doesn't work.
    //
    // ImageLink isn't given all of the attributes it needs.  In particular gfx
    // and image.  Not sure how this was supposed to work.
    //
    // Also template no longer has a URL attribute.
    //
    // XXX Either decide that this is to be removed and remove it.  Or decide
    // that it is to be fixed and fix it.  I doubt it makes any sense for
    // racks.  Perhaps it does for machines?  A link to the openstack flavour?
    if (this.template.url) {
      return this.imageLink = new ImageLink({
        x       : this.x,
        y       : this.y,
        width   : Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front.top.width,
        height  : Rack.IMAGES_BY_TEMPLATE[this.template.id].slices.front.top.height,
        url     : this.template.url
      }, this);
    }
  }

  //XXX This function should be refactored. There is no performance issue, just the logic to be improved.
  isHoldingArea() {
    return false;
  }

  setCoords(x1, y1) {
    this.x = x1;
    this.y = y1;
    if (this.imageLink) {
      this.imageLink.x = this.x;
      this.imageLink.y = this.y;
    }
  
    const x = this.x + (this.width / 2);
    const total_top = this.chassisOffsetY + this.y;
    return (() => {
      const result = [];
      for (var child of Array.from(this.children)) {
        var y = (RackObject.U_PX_HEIGHT * (this.uHeight - child.uStart() - child.uHeight)) + total_top;
        result.push(child.setCoords(x-(child.width/2), y));
      }
      return result;
    })();
  }

  nameToShow() {
    return this.name;
  }

  //XXX 
  //
  // rack_id=5;
  // rs = document.IRV.rackSpace;
  // rack = rs.racks[rack_id];
  // rack.destroy()
  //
  destroy() {
    super.destroy();
    this.showULabels(false);
    this.showNameLabel(false);
    this.showOwnerLabel(false);
  }
    //model = RackObject.MODEL
    //model_racks = model.racks()

    //for model_rack, index in model_racks
    //  if model_rack.id is @.id
    //    console.log "Deleteing for shizzle this is ID " + @.id
    //    model_racks.splice(index, 1)
    //    break

  //removeChassis: (chassis_id) ->
  //  chassis_to_remove = null
  //  for oneChassis in @chassis
  //    if parseInt(oneChassis.id) is chassis_id
  //      chassis_to_remove = oneChassis
  //  @chassis.splice(chassis_to_remove,1) if chassis_to_remove?

  // This method creates 3 objects to define the occupied slots for 3 scenarios
  // @uOccupied will be used when moving a full depth device
  // @uOccupiedFront will be used when moving a half depth device to the front of a rack
  // @uOccupiedRear will be used when moving a half depth device to the rear of a rack
  updateOccupied() {
    this.uOccupied       = {};
    this.uOccupiedFront  = {};
    this.uOccupiedRear   = {};
    for (var oneChild of Array.from(this.children)) {
      var count = 0;
      while (count < oneChild.uHeight) {
        this.uOccupied[oneChild.uStart() + count] = oneChild;
        if (oneChild.depth() === 2) {
          this.uOccupiedFront[oneChild.uStart() + count] = oneChild;
          this.uOccupiedRear[oneChild.uStart() + count]  = oneChild;
        } else {
          if (oneChild.facingFront()) {
            this.uOccupiedFront[oneChild.uStart() + count] = oneChild;
          } else if (oneChild.facingRear()) {
            this.uOccupiedRear[oneChild.uStart() + count]  = oneChild;
          }
        }
        ++count;
      }
    }
    return this;
  }

  updateChassisPosition(chassis_id, new_start_u, new_face) {
    return (() => {
      const result = [];
      for (var oneChild of Array.from(this.children)) {
        if (parseInt(oneChild.id) === chassis_id) {
          oneChild.uStartDef = new_start_u;
          oneChild.face = new_face === 'f' ? 'front' : 'rear';
          oneChild.setCoordsBasedOnUStart();
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  updateBladeRowAndCol(chassis_id, blade_id, new_row, new_col) {
    return (() => {
      const result = [];
      for (let indexChassis = 0; indexChassis < this.children.length; indexChassis++) {
        var oneChassis = this.children[indexChassis];
        if (parseInt(oneChassis.id) === chassis_id) {
          for (var indexMachine = 0; indexMachine < oneChassis.children.length; indexMachine++) {
            var oneMachine = oneChassis.children[indexMachine];
            if (parseInt(oneMachine.id) === blade_id) {
              this.children[indexChassis].children[indexMachine].row = new_row;
              this.children[indexChassis].children[indexMachine].column = new_col;
              this.children[indexChassis].children[indexMachine].setCoordsBasedOnRowAndCol();
              break;
            }
          }
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  updateOccupiedSlotsInChassis(chassis_id) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.children.length; index++) {
        var oneChild = this.children[index];
        if (parseInt(oneChild.id) === chassis_id) {
          this.children[index].updateOccupiedSlots();
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  draw(show_u_labels, show_name_label, show_owner_label) {
    Profiler.begin(Profiler.DEBUG, this.draw);
    // clear
    for (var asset of Array.from(this.assets)) { RackObject.RACK_GFX.remove(asset); }
    this.assets = [];

    // add labels as necessary
    this.showOwnerLabel(show_owner_label);
    this.showNameLabel(show_name_label);
    this.showULabels(show_u_labels);

    this.face = RackObject.MODEL.face();
    if (this.face === ViewModel.FACE_BOTH) { this.face = this.bothView; }

    // rack image
    this.assets.push(RackObject.RACK_GFX.addImg({
      img   : Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight][this.template.id][this.face],
      x     : this.x,
      y     : this.y,
      alpha : this.included ? 1 : RackObject.EXCLUDED_ALPHA
    }));

    // add a fade if in metric view mode
    if (RackObject.MODEL.displayingMetrics() && !RackObject.MODEL.displayingImages() && Rack.FADE_IN_METRIC_MODE) {
      this.assets.push(RackObject.RACK_GFX.addRect({ fx: 'source-atop', x: this.x, y: this.y, width: this.width, height: this.height, fill: RackObject.METRIC_FADE_FILL, alpha: RackObject.METRIC_FADE_ALPHA })); 
    }

    // determine draw order according to current view
    this.children = this.face === ViewModel.FACE_FRONT ? this.rearFirst : this.frontFirst;
    super.draw();
    return Profiler.end(Profiler.DEBUG, this.draw);
  }

  showOwnerLabel(visible) {
    if (visible) {
      this.ownerLabel.draw()
    } else {
      this.ownerLabel.remove()
    }
  }

  showULabels(visible, target_scale) {
    let lbl;
    if (visible) {
      if (this.uLbls && (this.uLbls.length > 0)) {
        for (lbl of Array.from(this.uLbls)) { RackObject.INFO_GFX.remove(lbl); }
        this.uLbls = [];
      }

      let count  = 0;
      const font_size = RackObject.MODEL.targetScale() === Rack.MAX_ZOOM ? Rack.U_LBL_FONT_SIZE : Rack.U_LBL_FONT_SIZE*Rack.U_LBL_SCALE_RATIO;
      Rack.U_LBL_SCALED_FONT = font_size + 'px ' + Rack.U_LBL_FONT;
      const top_total = (this.y + this.chassisOffsetY) - (RackObject.U_PX_HEIGHT/3);
      return (() => {
        const result = [];
        while (count < this.uHeight) {
          var lbl_y = (RackObject.U_PX_HEIGHT * (this.uHeight - count)) + top_total;
          this.uLbls.push(RackObject.INFO_GFX.addText({
            x       : this.x + Rack.U_LBL_OFFSET_X,
            y       : lbl_y,
            caption : count + 1,
            font    : Rack.U_LBL_SCALED_FONT,
            borderColour: '#666666',
            borderWidth: '2',
            align   : Rack.U_LBL_ALIGN,
            alpha   : this.included ? 1 : RackObject.EXCLUDED_ALPHA,
            fill    : Rack.U_LBL_COLOUR})
          );
          result.push(++count);
        }
        return result;
      })();

    } else if (!visible) {
      for (lbl of Array.from(this.uLbls)) { RackObject.INFO_GFX.remove(lbl); }
      return this.uLbls = [];
    }
  }



  showFreeSpacesForChassis(min_height,chassis_id,chassis_depth) {
    for (var child of Array.from(this.children)) { child.fadeOutMetrics(); }
    const fixed_device_width = 463;

    this.availableSpaces = [];
    const u_height         = this.uHeight;
    const u_px_height      = RackObject.U_PX_HEIGHT;
    const centre_x         = this.x + (this.width / 2);
    const space_left       = this.x + Rack.SPACE_PADDING;
    const space_right      = (this.x + this.width) - Rack.SPACE_PADDING;
    const y                = this.y + this.chassisOffsetY;
    let count            = 0;
    let occupiedHash = this.uOccupied;
    if (chassis_depth === 1) {
      if (this.face === 'front') {
        occupiedHash = this.uOccupiedFront;
      } else if (this.face === 'rear') {
        occupiedHash = this.uOccupiedRear;
      }
    }


    return (() => {
      const result = [];
      while (count < u_height) {

        var delta;
        var space_u_height = 0;
        // scan unoccupied region
        var inicial_count = count;
        while (((occupiedHash[count] == null) || (parseInt(occupiedHash[count].id) === chassis_id)) && (count < u_height)) {
          ++space_u_height;
          ++count;
        }

        if (min_height > 1) {
          delta = space_u_height - min_height;
        } else {
          delta = space_u_height - 1;
        }
        if (delta >= 0) {

          // calculate available spaces for the given height
          var count2 = 0;
          while (count2 <= delta) {
            this.availableSpaces.push({
              u         : inicial_count + count2,
              face      : this.face === 'front' ? 'f' : 'b',
              left      : space_left,
              right     : space_right,
              top       : (y + ((u_height - (inicial_count + count2)) * u_px_height)) - (u_px_height * min_height),
              bottom    : y + ((u_height - (inicial_count + count2)) * u_px_height),
              rack_name : this.name,
              rack_id   : parseInt(this.id)
            });
            ++count2;
          }

          // add highlight
          this.createFreeSpaceHighlight( this.x + Rack.SPACE_PADDING + ((this.width - fixed_device_width)/2),y + ((u_height - count) * u_px_height),fixed_device_width - (Rack.SPACE_PADDING * 2),u_px_height * space_u_height);
        }

        result.push(++count);
      }
      return result;
    })();
  }

  showFreeSpacesForBlade(blade_image,chassis_id) {
    this.availableSpaces = [];
    return (() => {
      const result = [];
      for (var oneChild of Array.from(this.children)) {
        if (oneChild.isOfSameType(blade_image)) {
          var free_slots_for_this_chassis = oneChild.getFreeSlots();
          if (free_slots_for_this_chassis.length > 0) {
            this.availableSpaces = this.availableSpaces.concat(free_slots_for_this_chassis);
            result.push(Array.from(free_slots_for_this_chassis).map((oneFreeSlot) =>
              this.createFreeSpaceHighlight(oneFreeSlot.x,oneFreeSlot.y,oneChild.slotWidth,oneChild.slotHeight)));
          } else {
            result.push(undefined);
          }
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  deselect() {
    if (this.selected) {
      this.selected = false;
      if (child.selected) { return (() => {
        const result = [];
        for (var child of Array.from(this.children)) {               result.push(child.deselect());
        }
        return result;
      })(); }
    }
  }


  fadeOutMetrics() {
    return Array.from(this.children).map((child) => child.fadeOutMetrics());
  }


  fadeInMetrics() {
    return Array.from(this.children).map((child) => child.fadeInMetrics());
  }


  evSpaceHidden(id) {
    return RackObject.INFO_GFX.remove(id);
  }

  selectChildren() {
    const select_hash = {};
    if (this.children.length === 0) { return select_hash; }
    select_hash[this.children[0].group] = {};
    for (var child of Array.from(this.children)) {
      select_hash[child.group][child.id] = true;
      for (var gchild of Array.from(child.children)) {
        if (!select_hash[gchild.group]) { select_hash[gchild.group] = {}; }
        select_hash[gchild.group][gchild.id] = true;
      }
    }
    return select_hash;
  }

  removeBladeFromChassis(chassis_id, blade_id) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.children.length; index++) {
        var oneChassis = this.children[index];
        if (parseInt(oneChassis.id) === chassis_id) {
          this.children[index].removeBlade(blade_id);
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  addBladeToChassis(chassis_id, blade) {
    return (() => {
      const result = [];
      for (let index = 0; index < this.children.length; index++) {
        var oneChassis = this.children[index];
        if (parseInt(oneChassis.id) === chassis_id) {
          this.children[index].addBlade(blade);
          break;
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  getSlot(x, y) {
    x -= this.x;
    y -= this.y + this.chassisOffsetY;

    const row = this.uHeight - Math.floor(y / RackObject.U_PX_HEIGHT) - 1;

    if ((row >= 0) && (row < this.uHeight)) {
      const device = this.uOccupied[row];
      return { row, column: 0, device };
    }

    return null;
  }

  imageCacheExist(uHeight, template_id) {
    return (Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight] != null) && (Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight][this.template.id] != null);
  }

  getImageOfU(count,face) {
    if (this.template.rack_repeat_ratio != null) {
      return Rack.IMAGES_BY_TEMPLATE[this.template.id].imageRepeatPatern[face][count%Rack.IMAGES_BY_TEMPLATE[this.template.id].repeatBlockSize];
    } else {
      return this.getImage("front").repeat[0];
    }
  }

  setImageCache() {
    const cache = {};

    let cvs        = document.createElement('canvas');
    cvs.width  = this.width;
    cvs.height = this.height;
  
    let ctx = cvs.getContext('2d');
    ctx.drawImage(this.getImage("front").top, 0, 0);
    let count = 0;
    while (count < this.uHeight) {
      ctx.drawImage(this.getImageOfU(count,'front'), 0, (RackObject.U_PX_HEIGHT * (this.uHeight - (count+1))) + this.chassisOffsetY);
      ++count;
    }
    ctx.drawImage(this.getImage("front").btm, 0, (RackObject.U_PX_HEIGHT * count) + this.chassisOffsetY);

    cache.front = cvs;

    cvs        = document.createElement('canvas');
    cvs.width  = this.width;
    cvs.height = this.height;
  
    ctx = cvs.getContext('2d');
    ctx.drawImage(this.getImage("rear").top, 0, 0);
    count = 0;
    while (count < this.uHeight) {
      ctx.drawImage(this.getImageOfU(count,'rear'), 0, (RackObject.U_PX_HEIGHT * (this.uHeight - (count+1))) + this.chassisOffsetY);
      ++count;
    }
    ctx.drawImage(this.getImage("rear").btm, 0, (RackObject.U_PX_HEIGHT * count) + this.chassisOffsetY);

    cache.rear = cvs;

    if (Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight] == null) { Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight] = {}; }
    return Rack.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight][this.template.id] = cache;
  }


  coordinates() {
    return {left: this.x, right: this.x+this.width, top: this.y+this.height, bottom: this.y};
  }


  refreshRackFocus(model) {
    const selection = this.selectWithin(this.coordinates(), true);
    return model.selectedDevices(selection);
  }

};
Rack.initClass();
export default Rack;
