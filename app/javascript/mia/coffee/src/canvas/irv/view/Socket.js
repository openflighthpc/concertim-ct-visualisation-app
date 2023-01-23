/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from '../../../canvas/common/util/Util';
import Highlight from '../../../canvas/irv/view/Highlight';
import Events from '../../../canvas/common/util/Events';
import Rack from '../../../canvas/irv/view/Rack';
import RackObject from '../../../canvas/irv/view/RackObject';
import AssetManager from '../../../canvas/irv/util/AssetManager';
import MessageHint from '../../../canvas/irv/view/MessageHint';
import PowerSupply from '../../../canvas/irv/view/PowerSupply';

class Socket {
  static initClass() {
    this.IMG_SOCKET_FRONT_GREY        = '';
    this.IMG_SOCKET_FRONT_GREY_BUSY   = '';
    this.IMG_SOCKET_FRONT_RED         = '';
    this.IMG_SOCKET_FRONT_RED_BUSY    = '';
    this.IMG_SOCKET_FRONT_GREEN       = '';
    this.IMG_SOCKET_FRONT_GREEN_BUSY  = '';

    this.LABEL_LEFT_PADDING         = 15;
    this.LABEL_TOP_PADDING          = 20;
    this.IMG_TOP_PADDING            = 2;
  }

  constructor(position, def, x,y, parent) {
    this.parent = parent;
    this.id = def.id;
    this.type = "Socket";
    this.on = def.on;
    this.device_id = (def.device_id !== null) ? parseInt(def.device_id) : 0;
    this.device_name = def.device_name;
    this.power_supply_id = (def.power_supply_id !== null) ? parseInt(def.power_supply_id) : 0;
    this.power_supply_name = def.power_supply_name;
    this.x = x;
    this.y = y;
    this.position = position;
    this.model = RackObject.MODEL;
    this.oneAsset = null;
    this.oneLabel = null;
  }

  draw() {
    this.img = this.getImage(); 
    this.width  = this.img.width;
    this.height = this.img.height;
    this.showLabel();
    if (this.oneAsset) { RackObject.POWER_STRIP_GFX.remove(this.oneAsset); }
    this.oneAsset = null;
    return this.oneAsset = 
      RackObject.POWER_STRIP_GFX.addImg({
        img   : this.img,
        x     : this.x,
        y     : this.y + Socket.IMG_TOP_PADDING,
        alpha : 1
      });
  }
  
  destroy() {
    this.deselect();
    if (this.oneLabel) { RackObject.POWER_STRIP_GFX.remove(this.oneLabel); }
    if (this.oneAsset) { return RackObject.POWER_STRIP_GFX.remove(this.oneAsset); }
  }
  
  updateImage() {
    this.img = this.getImage(); 
    return this.parent.draw();
  }

  showLabel() {
    if (this.oneLabel) { RackObject.POWER_STRIP_GFX.remove(this.oneLabel); }
    this.oneLabel = null;
    return this.oneLabel = 
      RackObject.POWER_STRIP_GFX.addText({
        x       : this.x - Socket.LABEL_LEFT_PADDING,
        y       : this.y + Socket.LABEL_TOP_PADDING,
        caption : this.position,
        font    : Rack.U_LBL_SCALED_FONT,
        align   : Rack.U_LBL_ALIGN,
        fill    : Rack.U_LBL_COLOUR
      });
  }

  select() {
    if (this.highlight == null) {
      return this.highlight = new Highlight(Highlight.MODE_SELECT, this.x, this.y + Socket.IMG_TOP_PADDING, this.width, this.height, RackObject.ALERT_GFX);
    }
  }

  showDrag() {
    if (this.highlightDragging == null) {
      return this.highlightDragging = new Highlight(Highlight.MODE_DRAG, this.x, this.y + Socket.IMG_TOP_PADDING, this.width, this.height, RackObject.ALERT_GFX);
    }
  }

  deselect() {
    if (this.highlight != null) {
      this.highlight.destroy();
      return delete this.highlight;
    }
  }

  hideDrag() {
    if (this.highlightDragging != null) {
      this.highlightDragging.destroy();
      return delete this.highlightDragging;
    }
  }

  setCoords(x, y) {
    this.x = x;
    this.y = y;
    if (this.oneAsset) { RackObject.POWER_STRIP_GFX.setAttributes(this.oneAsset, { x: this.x, y: this.y + Socket.IMG_TOP_PADDING}); }
    if (this.oneLabel) { RackObject.POWER_STRIP_GFX.setAttributes(this.oneLabel, { x: this.x - Socket.LABEL_LEFT_PADDING, y: this.y + Socket.LABEL_TOP_PADDING}); }
    return this.deselect();
  }

  isHighlighted() {
    return (this.highlight != null);
  }

  busy() {
    return this.device_id > 0;
  }

  getDeviceConnectedTo() {
    if (this.busy()) {
      if (this.model.deviceLookup().devices != null) {
        const device = this.model.deviceLookup().devices[this.device_id];
        if (device != null) {
          return device;
        } else {
          const chassis = this.model.deviceLookup().chassis[this.device_id];
          if (chassis != null) {
            return chassis;
          } else {
            return null;
          }
        }
      }
    }
  }

  getConnection() {
    return this.parent.connectionData[this.id];
  }

  getNameOfDeviceConnectedTo() {
    if (this.busy()) {
      if (this.getDeviceConnectedTo() != null) {
        return this.getDeviceConnectedTo().name;
      } else if (this.getConnection() != null) {
        return this.getConnection().device_name;
      } else { return null; }
    }
  }

  getPowerSupplyOfDeviceConnectedTo() {
    if (this.busy()) {
      if (this.getPowerSupplyConnectedTo() != null) {
        return this.getPowerSupplyConnectedTo().name;
      } else if (this.getConnection() != null) {
        return this.getConnection().psu;
      } else { return null; }
    }
  }

  getPowerSupplyConnectedTo() {
    if (this.busy()) {
      const device = this.getDeviceConnectedTo();
      if (device != null) {
        return device.instances[0].getPowerSupplyConnectedToSocket(this.id);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  getImage() {
    if (this.on === true) {
      if (this.busy()) {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_GREEN_BUSY];
      } else {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_GREEN];
      }
    } else if (this.on === false) {
      if (this.busy()) {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_RED_BUSY];
      } else {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_RED];
      }
    } else if (this.on === null) {
      if (this.busy()) {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_GREY_BUSY];
      } else {
        return AssetManager.CACHE[RackObject.IMAGE_PATH + Socket.IMG_SOCKET_FRONT_GREY];
      }
    }
  }
  

  getContextMenuOption() {
    this.extraOptions = [];
    let oneHash = null;
    if (this.model.showingRacks()) {
      if (this.busy()) {
        oneHash = {};
        oneHash.caption = "Disconnect";
        oneHash.url     = "internal::disconnectPowerSupplyAndSocket";
        oneHash.RBAC    = {"action": "manage", "resource": "Ivy::Device"};
      } else {
        oneHash = {};
        oneHash.caption = "Connect";
        oneHash.url     = "internal::startDraggingDevice";
        oneHash.RBAC    = {"action": "manage", "resource": "Ivy::Device"};
      }
      if (oneHash != null) { this.extraOptions.push(oneHash); }
    }

    if ((this.parent.managed === true) && (this.parent.monitorable_live === false)) {
      if ((this.on === true) || (this.on === null)) {
        const powerDown = {};
        powerDown.caption  = "Power down";
        powerDown.url      = "internal::powerSocketOnAndOff,powerdown,"+this.parent.id+","+this.id;
        powerDown.RBAC     = {"action": "manage", "resource": "Ivy::Device"};
        this.extraOptions.push(powerDown);
        const powerCycle = {};
        powerCycle.caption = "Power cycle";
        powerCycle.url     = "internal::powerSocketOnAndOff,powercycle,"+this.parent.id+","+this.id;
        powerCycle.RBAC     = {"action": "manage", "resource": "Ivy::Device"};
        this.extraOptions.push(powerCycle);
      }
      if ((this.on === false) || (this.on === null)) {
        const powerHash = {};
        powerHash.caption  = "Power on";
        powerHash.url      = "internal::powerSocketOnAndOff,powerup,"+this.parent.id+","+this.id;
        powerHash.RBAC     = {"action": "manage", "resource": "Ivy::Device"};
        this.extraOptions.push(powerHash);
      }
    }
    
    return this.extraOptions;
  }

  disconnect() {
    const device = this.getDeviceConnectedTo();
    if (device != null) {
      const powerSupply = device.instances[0].getPowerSupplyConnectedToSocket(this.id);
      return powerSupply.update({action:'disconnect'});
    } else { 
      const foreing_parent = {name:this.device_name};
      const foreing_power_supply = new PowerSupply(this.power_supply_id, this.power_supply_name, this.parent.id, this.id, foreing_parent);
      return foreing_power_supply.update({action:'disconnect', socket:this, device_not_inside_rack: true});
    }
  }
};
Socket.initClass();
export default Socket;
