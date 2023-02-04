/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import MessageHint from 'canvas/irv/view/MessageHint';

class PowerSupply {
  constructor(id, name, power_strip_id, socket_id, parent) {
    this.create_request = this.create_request.bind(this);
    this.sendConfirmation = this.sendConfirmation.bind(this);
    this.parent = parent;
    this.id = parseInt( id, 10 ); 
    this.name = name;
    this.power_strip_id = typeof power_strip_id !== "undefined" ? parseInt( power_strip_id, 10 ) : null;
    this.socket_id = typeof socket_id !== "undefined" ? parseInt( socket_id, 10 ) : null;
  }

  busy() {
    return (this.power_strip_id !== null) && (this.socket_id !== null);
  }

  getUpdateLink(conf) {
    this.conf = conf;
    if (this.parent.hasAPowerSupplyConectedToPowerStrip(this.conf.socket.parent.id)) {
      this.conf.another_socket_connected = true;
    }
    const link = new Element('a');
    Events.addEventListener(link, 'mouseup', this.create_request);
    link.innerHTML = this.name;
    return link;
  }

  update(conf) {
    this.conf = conf;
    if ((this.conf.action === "disconnect") && (this.conf.socket == null)) {
      this.conf.socket = this.getPowerStripConnectedTo().instances[0].getSocket(this.socket_id);
    }
    return this.create_request();
  }

  create_request(ev) {
    return new Request.JSON({
      headers    : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url: '/-/api/v1/irv/power_supplies/'+this.conf.socket.parent.id+'/'+this.conf.action+'/',
      onSuccess: this.sendConfirmation,
      onFail: this.sendErrorMessage,
      onError: this.sendFatalErrorMessage,
      data: {psu_id: this.id, socket_id: this.conf.socket.id}
    }).send();
  }

  sendConfirmation(config) {
    this.messageHint = new MessageHint();
    this.messageHint.closePopUp();
    if (config.success === true) {
      let connected;
      if (this.conf.action === "connect") {
        connected= "connected to"; 
        this.updateAllInstancesOfParent(this.conf.socket.parent.id, this.conf.socket.id);
        this.conf.socket.device_id = this.parent.id; 
      } else { 
        connected = "disconnected from";
        if (!this.conf.device_not_inside_rack) { this.updateAllInstancesOfParent(null,null); }
        this.conf.socket.device_id = 0;
      }
      if (this.conf.socket.parent.show === true) { this.conf.socket.updateImage(); }
      const messages = [["Device: " + this.parent.name + ", in Power Supply: "+this.name+", >>> "+connected+" >>> PowerStrip: "+this.conf.socket.parent.name+", Socket: " + this.conf.socket.id, 0]];
      if (this.conf.another_socket_connected === true) {
        messages.push(["Device has a power supply already connected to same PDU!",2]);
      }
      return this.messageHint.show(messages);
    } else {
      return this.messageHint.show([["Power supply update error!", 0]]);
    }
  }

  updateAllInstancesOfParent(power_strip_id, socket_id) {
    return (() => {
      const result = [];
      for (var oneInstance of Array.from(this.parent.getInstances())) {
        var powerSupplyToUpdate = oneInstance.getPowerSupply(this.id);
        powerSupplyToUpdate.power_strip_id = power_strip_id;
        result.push(powerSupplyToUpdate.socket_id = socket_id);
      }
      return result;
    })();
  }

  // generic request failure handler
  loadFail(failee) {
    //Profiler.trace(Profiler.CRITICAL, "loadFail #{failee}")
    return console.log("PowerSupply LOADFAIL::: ", failee);
  }
  
  // generic request error handler
  loadError(err_str, err) {
    //Profiler.trace(Profiler.CRITICAL, "loadError #{err_str}")
    return console.log("PowerSupply FATAL ERROR::: ", err_str);
  }

  powerStripConnectedToIsInCurrentRack() {
    return (this.getPowerStripConnectedTo() != null) && (this.parent.deviceLookup().racks[this.getPowerStripConnectedTo().rack_id] != null);
  }


  getPowerStripConnectedTo() {
    return this.parent.deviceLookup().powerStrips[this.power_strip_id];
  }
};

export default PowerSupply;
