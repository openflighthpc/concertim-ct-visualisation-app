/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import RackSpaceObject from '../../../canvas/irv/view/RackSpaceObject';
import Util from '../../../canvas/common/util/Util';
import Highlight from '../../../canvas/irv/view/Highlight';
import Events from '../../../canvas/common/util/Events';
import RackObject from '../../../canvas/irv/view/RackObject';
import Rack from '../../../canvas/irv/view/Rack';
import Socket from '../../../canvas/irv/view/Socket';
import AssetManager from '../../../canvas/irv/util/AssetManager';
import InfoTable from '../../../canvas/irv/view/InfoTable';
import Link from '../../../canvas/irv/view/Link';
import ImageLink from '../../../canvas/irv/view/ImageLink';

class PowerStrip extends RackSpaceObject {
  static initClass() {

    this.POWERSTRIP_H_PADDING  = 60;
    this.POWERSTRIP_H_SPACING  = 30;
    this.INFO_TABLE_WIDTH      = 1050;
    this.LOGO_V_PADDING        = 20;

    // statics overwritten by config
    this.BACK_GROUND_COLOR   = '#557744';
    this.U_PX_HEIGHT         = 50;
    this.LEFT_PADDING        = 30;

    this.IMG_BTM     = '';
    this.IMG_TOP     = '';
    this.IMG_REPEAT  = '';

    this.IMG_WAIT    = 'util/pleasewait.gif';

    this.NAME_LBL_SIZE              = 10;
    this.NAME_LBL_FONT              = 'Verdana';
    this.NAME_LBL_COLOUR            = 'white';
    this.NAME_LBL_ALIGN             = 'center';

    this.MAX_ZOOM    = 0.70;

    // hard coded and run-time assigned statics
    this.CHASSIS_OFFSET_Y         = null; // assigned dynamically from the height of the rack top slice image
    this.SLICES                   = {};
    this.IMAGE_CACHE_BY_U_HEIGHT  = {};
  }

  static initialise() {
    // static function called once to set certain static properties
    PowerStrip.SLICES = {
      top    : AssetManager.CACHE[RackObject.IMAGE_PATH + PowerStrip.IMG_TOP],
      btm    : AssetManager.CACHE[RackObject.IMAGE_PATH + PowerStrip.IMG_BTM],
      repeat : AssetManager.CACHE[RackObject.IMAGE_PATH + PowerStrip.IMG_REPEAT]
    };

    return PowerStrip.CHASSIS_OFFSET_Y = PowerStrip.SLICES.top.height;
  }

  constructor(def) {
    super(...arguments);
    this.connectionData = def.Connections;
    this.showInfoTable = def.showInfoTable;
    this.images = PowerStrip.SLICES;
    this.x = 0;
    this.y = 0;
    this.name = def.name;
    this.manufacturer = def.manufacturer;
    this.model = def.model;
    this.type = "PowerStrip";
    this.id = def.id;
    this.rack_id = def.rack_id;
    this.managed = def.managed;
    this.monitorable_live = def.monitorable_live;
    this.manufacturer_url = def.manufacturer_url;

    this.logo = AssetManager.CACHE[RackObject.IMAGE_PATH+def.logo];
    this.images.wait = AssetManager.CACHE[RackObject.IMAGE_PATH+PowerStrip.IMG_WAIT];

    this.sockets = [];
    for (let i = 0; i < def.Sockets.length; i++) {
      var socket = def.Sockets[i];
      this.sockets.push(new Socket(socket.id, socket, PowerStrip.LEFT_PADDING, (PowerStrip.U_PX_HEIGHT*i) + PowerStrip.CHASSIS_OFFSET_Y, this));
    }

    this.uHeight = this.sockets.length;
    this.width   = this.images.top.width;
    this.height  = this.images.top.height + this.images.btm.height + (PowerStrip.U_PX_HEIGHT * this.uHeight);

    this.powerStripsGFX = RackObject.POWER_STRIP_GFX;
    this.parentEl = RackObject.POWER_STRIP_GFX.containerEl;

    if (PowerStrip.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight] == null) { this.setImageCache(); }

    if (RackObject.MODEL.deviceLookup().powerStrips[this.id] == null) {
      def.instances = [];
      RackObject.MODEL.deviceLookup().powerStrips[this.id] = def;
    }

    if (RackObject.MODEL.deviceLookup().powerStrips[this.id] != null) {
      const this_ps_instances = RackObject.MODEL.deviceLookup().powerStrips[this.id].instances;
      for (var oneInstance of Array.from(this_ps_instances)) {
        oneInstance.destroy();
      }
      RackObject.MODEL.deviceLookup().powerStrips[this.id].instances = [];
    }

    RackObject.MODEL.deviceLookup().powerStrips[this.id].instances.push(this);
    this.assets = [];
    this.powerStatusColected = false;
  }

  fadeInMetrics() {}
    // Function to keep consistency while hiding free spaces/sockets

  select(socket_id_array) {
    this.deselect();
    this.sockets_highlighted = [];
    return (() => {
      const result = [];
      for (var one_id of Array.from(socket_id_array)) {
        var one_socket = this.getSocket(one_id);
        this.sockets_highlighted.push(one_socket);
        result.push(one_socket.select());
      }
      return result;
    })();
  }

  selectSelf() {
    if (this.highlight == null) {
      return this.highlight = new Highlight(Highlight.MODE_SELECT, this.x, this.y, this.width, this.height, RackObject.ALERT_GFX);
    }
  }

  mustBeVisible() {
    return (RackObject.MODEL.deviceLookup().racks[this.rack_id] != null);
  }

  deselect() {
    if (this.sockets_highlighted != null) {
      return Array.from(this.sockets_highlighted).map((oneSocket) =>
        oneSocket.deselect());
    }
  }
  
  deselectSelf() {
    if (this.highlight != null) {
      this.highlight.destroy();
      return delete this.highlight;
    }
  }
  
  isHighlighted() {
    return (this.highlight != null);
  }

  getSocket(socket_id){
    for (var oneSocket of Array.from(this.sockets)) {
      if (oneSocket.id === socket_id) { return oneSocket; }
    }
  }

  destroy() {
    this.deselect();
    this.deselectSelf();
    if (this.infoTable != null) { this.infoTable.remove(); }
    this.waiting(false);
    for (var socket of Array.from(this.sockets)) { socket.destroy(); }
    for (var asset of Array.from(this.assets)) { RackObject.POWER_STRIP_GFX.remove(asset); }
    if (this.imageLink != null) { RackObject.POWER_STRIP_GFX.remove(this.imageLink); }
    if (this.labelLink != null) { RackObject.POWER_STRIP_GFX.remove(this.labelLink); }
    return this.psNameLbl = null;
  }
  
  draw() {
    this.deselect();
    this.deselectSelf();
    if (this.infoTable != null) { this.infoTable.remove(); }
    this.waiting(false);
    for (var asset of Array.from(this.assets)) { RackObject.POWER_STRIP_GFX.remove(asset); }
    this.assets = [];
    this.assets.push(
      RackObject.POWER_STRIP_GFX.addImg({
        img   : PowerStrip.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight],
        x     : this.x,
        y     : this.y,
        alpha : 1
      })
    );

    this.addImageLink();
    if (RackObject.MODEL.showingRacks()) { this.addNameLink(); }

    for (var socket of Array.from(this.sockets)) { socket.draw(); }
    if (!this.powerStatusColected && (this.managed !== false)) { this.waiting(true); }

    if (this.showInfoTable && (this.connectionData != null)) {
      this.infoTable = new InfoTable(this.getInfoTableData(), this);
      return this.infoTable.draw();
    }
  }

  getFormattedName() {
    if (this.name.length > 7) {
      return this.name.substr(0,7) + "..";
    } else {
      return this.name;
    }
  }

  showNameLink(true_or_false, new_scale) {
    if (true_or_false === false) {
      if (this.labelLink != null) { RackObject.POWER_STRIP_GFX.remove(this.labelLink); }
      this.labelLink = null;
      return this.nameLink = null;
    } else if (true_or_false === true) {
      return this.addNameLink(new_scale);
    }
  }

  showSocketLabels() {
    return Array.from(this.sockets).map((socket) => socket.showLabel());
  }

  addImageLink() {
    if (this.imageLink != null) { RackObject.POWER_STRIP_GFX.remove(this.imageLink); }
    if (this.logo) {
      const actual_scale = (typeof new_scale !== 'undefined' && new_scale !== null) ? new_scale : RackObject.POWER_STRIP_GFX.scale;
      const oneImageLink = new ImageLink({
        gfx     : RackObject.POWER_STRIP_GFX,
        x       : this.logoCoords().x,
        y       : this.logoCoords().y,
        image   : this.logo,
        url     : this.manufacturer_url
      }, this);
      this.logoLink = oneImageLink;
      return this.imageLink = oneImageLink.asset_id;
    }
  }

  addNameLink(new_scale) {
    if (this.labelLink != null) { RackObject.POWER_STRIP_GFX.remove(this.labelLink); }
    const actual_scale = (new_scale != null) ? new_scale : RackObject.POWER_STRIP_GFX.scale;
    const size = PowerStrip.NAME_LBL_SIZE * actual_scale;
    const oneLink = new Link({
      gfx     : RackObject.POWER_STRIP_GFX,
      x       : this.labelCoords().x,
      y       : this.labelCoords().y,
      text    : this.getFormattedName(),
      font    : {decoration:'bolder',size,fontFamily:PowerStrip.NAME_LBL_FONT},
      align   : PowerStrip.NAME_LBL_ALIGN,
      fill    : PowerStrip.NAME_LBL_COLOUR,
      url     : '/-/devices/'+this.id
    }, this);
    this.nameLink = oneLink;
    return this.labelLink = oneLink.asset_text;
  }


  height() {
    return this.height;
  }

  labelCoords() {
    return {x:this.x + (this.width/2), y:this.y + 65};
  }

  logoCoords() {
    return {x:this.x + ((this.width - this.logo.width) / 2), y: (this.y + PowerStrip.LOGO_V_PADDING)};
  }

  setImageCache() {
    const cvs        = document.createElement('canvas');
    cvs.width  = this.width;
    cvs.height = this.height;
  
    const ctx = cvs.getContext('2d');
    ctx.drawImage(this.images.top, 0, 0);

    let count = 0;
    while (count < this.uHeight) {
      ctx.drawImage(this.images.repeat, 0, (PowerStrip.U_PX_HEIGHT * count) + PowerStrip.CHASSIS_OFFSET_Y);
      ++count;
    }
    ctx.drawImage(this.images.btm, 0, (PowerStrip.U_PX_HEIGHT * count) + PowerStrip.CHASSIS_OFFSET_Y);

    return PowerStrip.IMAGE_CACHE_BY_U_HEIGHT[this.uHeight] = cvs;
  }

  getSocketAt(x, y) {
    // search children in reverse order, this give presidence to children drawn last (topmost)
    let count = this.sockets.length;
    while (count > 0) {
      --count;
      var socket = this.sockets[count];
      if ((y > socket.y) && (y < (socket.y + socket.height)) && (x > socket.x) && (x < (socket.x + socket.width))) {
        return socket;
      }
    }

    const oneLink = this.getLinkAt(x, y);
    if (oneLink != null) {
      return oneLink;
    }

    return null;
  }

  getLinkAt(x,y) {
    if ((this.nameLink != null) && (y > (this.nameLink.y-(this.nameLink.height/2))) && (y < (this.nameLink.y+(this.nameLink.height/2))) && (x > (this.nameLink.x - (this.nameLink.width/2))) && (x < (this.nameLink.x + (this.nameLink.width/2)))) {
      return this.nameLink;
    }
    if ((this.logoLink != null) && (y > this.logoLink.y) && (y < (this.logoLink.y+this.logoLink.height)) && (x > this.logoLink.x) && (x < (this.logoLink.x + this.logoLink.width))) {
      return this.logoLink;
    }
    return null;
  }

  setCoords(x, y) {
    this.x = x;
    this.y = y;

    for (var oneAsset of Array.from(this.assets)) {
      RackObject.POWER_STRIP_GFX.setAttributes(oneAsset, { x, y});
    }

    if (this.labelLink != null) {
      const newLabelCoords = this.labelCoords();
      RackObject.POWER_STRIP_GFX.setAttributes(this.labelLink, { x: newLabelCoords.x, y: newLabelCoords.y});
      this.nameLink.x = newLabelCoords.x;
      this.nameLink.y = newLabelCoords.y;
    }

    if (this.imageLink != null) {
      const newLogoCoords = this.logoCoords();
      RackObject.POWER_STRIP_GFX.setAttributes(this.imageLink, { x: newLogoCoords.x, y: newLogoCoords.y});
      this.logoLink.x = newLogoCoords.x;
      this.logoLink.y = newLogoCoords.y;
    }

    for (let i = 0; i < this.sockets.length; i++) {
      var socket = this.sockets[i];
      var socket_y = this.y + (PowerStrip.U_PX_HEIGHT * i) + PowerStrip.CHASSIS_OFFSET_Y; 
      var socket_x = this.x + PowerStrip.LEFT_PADDING;
      socket.setCoords(socket_x, socket_y);
    }

    if (this.wait_id) {
      const waiting_coords = this.getWaitingCoordinates();
      return RackObject.INFO_GFX.setAttributes(this.wait_id, { x: waiting_coords.x, y: waiting_coords.y}); 
    }
  }

  infoLayer() {
    return RackObject.RACK_INFO_GFX;
  }

  getSocketsStatus() {
    let results;
    if (this.managed === true) {
      results = {on_busy:0,    on_free:0,    off_busy:0,    off_free:0,    busy:null, free:null};
    } else {
      results = {on_busy:null, on_free:null, off_busy:null, off_free:null, busy:0,    free:0}; 
    }

    for (var socket of Array.from(this.sockets)) {
      if (this.managed === true) {
        if (socket.on) {
          if (socket.busy()) {
            results.on_busy = results.on_busy + 1;
          } else {
            results.on_free = results.on_free + 1;
          }
        } else {
          if (socket.busy()) {
            results.off_busy = results.off_busy + 1;
          } else {
            results.off_free = results.off_free + 1;
          }
        }
      } else {
        if (socket.busy()) {
          results.busy = results.busy + 1;
        } else {
          results.free = results.free + 1;
        }
      }
    }

    return results;
  }

  showFreeSockets() {
    return (() => {
      const result = [];
      for (var socket of Array.from(this.sockets)) {
        if (!socket.busy()) {
          result.push(this.createFreeSpaceHighlight(socket.x,socket.y,socket.width,socket.height));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  getCurrentPowerData() {
    const currentPowerData = {};
    for (var socket of Array.from(this.sockets)) {
      currentPowerData[socket.id] = socket.on === true ? "on" : (socket.on === false ? "off" : null);
    }
    return currentPowerData;
  }

  processPowerData(powerData) {
    for (var oneKey in powerData) {
      var oneValue = powerData[oneKey];
      if (oneValue === "on") {
        __guard__(this.getSocket(parseInt(oneKey,10)), x => x.on = true);
      } else if (oneValue === "off") {
        __guard__(this.getSocket(parseInt(oneKey,10)), x1 => x1.on = false);
      } else {
        __guard__(this.getSocket(parseInt(oneKey,10)), x2 => x2.on = null);
      }
    }
    return this.draw(); 
  }

  blankPowerData() {
    for (var socket of Array.from(this.sockets)) {
      socket.on = null;
    }
    return this.draw();
  }

  waiting(start) {
    if (start === true) {
      this.wait_canvas = document.createElement('canvas');
      const ctx = this.wait_canvas.getContext("2d");
      const img = this.images.wait;
      let ang = 0; //angle
      const fps = 1000 / 25; //number of frames per sec
      this.wait_canvas.width = img.width << 1; //double the canvas width
      this.wait_canvas.height = img.height << 1; //double the canvas height
      let cache = img; //cache the local copy of image element for future reference

      if (this.wait_id) { RackObject.INFO_GFX.remove(this.wait_id); }
      if (this.interval_id) { clearInterval(this.interval_id); }
      const waiting_coords = this.getWaitingCoordinates();
      this.wait_id = RackObject.INFO_GFX.addImg({
          img   : this.wait_canvas,
          x     : waiting_coords.x,
          y     : waiting_coords.y,
          alpha : 0.4
        });
      return this.interval_id = setInterval(() => {
        ctx.save(); //saves the state of canvas
        ctx.clearRect(0, 0, this.wait_canvas.width, this.wait_canvas.height); //clear the canvas
        ctx.translate(cache.width, cache.height); //let's translate
        ctx.rotate((Math.PI / 180) * (ang += 5)); //increment the angle and rotate the image
        ctx.drawImage(img, -cache.width / 2, -cache.height / 2, cache.width, cache.height); //draw the image ;)
        ctx.restore(); //restore the state of canvas
        cache = img;
        return RackObject.INFO_GFX.setAttributes(this.wait_id, { img: this.wait_canvas});
      }
      , fps);
    } else if (start === false) {
      if (this.wait_id != null) {
        clearInterval(this.interval_id);
        this.interval_id = null;
        RackObject.INFO_GFX.remove(this.wait_id);
        return this.wait_id = null;
      }
    }
  }

  getWaitingCoordinates() {
    return {
      x: this.x - ((this.width / 2) - (this.images.wait.width / 4)),
      y: this.y - (this.images.wait.height*1.5)
    };
  }

  getInfoTableData() {
    const tableData = [];
    for (var cont of Array.from((this.sockets.map(oneSocket => oneSocket.id)))) {
      var oneData = this.connectionData[cont];
      var device_link  = oneData.device_id ? [oneData.device_name,'/-/devices/' + oneData.device_id] : "Not Connected";
      var metric_value = (oneData.power != null) ? oneData.power.value + ' ' + oneData.power.units : "N/A";
      var rack_data    = (oneData.rack != null) ? [oneData.rack.name,'/-/racks/'+oneData.rack.id,oneData.link_colour] : (oneData.device_id ? "Non Rack" : "Not Connected");
      var psu_value    = oneData.psu ? oneData.psu : "Not Connected";
      tableData.push( [cont, metric_value, psu_value, device_link, rack_data] );
    }

    const info_table_conf = {
      gfx:RackObject.POWER_STRIP_GFX,
      x:this.x+this.width+PowerStrip.POWERSTRIP_H_PADDING,
      y:this.y+PowerStrip.CHASSIS_OFFSET_Y,
      n:this.uHeight,
      alfa: 0.7,
      colors:{line:'#999999',header:'#888',bg1:'#FFFFFF',bg2:'#e8e8e8'},
      font:{font:'Verdana,Tahoma,Arial,sans-serif',size:'10',color:'black',align:'center'},
      row_width:PowerStrip.INFO_TABLE_WIDTH,
      row_height:PowerStrip.U_PX_HEIGHT,
      headers:['Socket','Power','Psu','Device','Rack'],
      data:tableData
    };
    return info_table_conf;
  }
};
PowerStrip.initClass();
export default PowerStrip;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
