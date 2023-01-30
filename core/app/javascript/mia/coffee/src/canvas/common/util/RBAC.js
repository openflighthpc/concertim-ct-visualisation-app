/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from './Util';
import Events from './Events';

  // RBAC = Rule Based Access Control
  // This model queries the api action /-/api/v1/users/users/can_i with an especific set of permissions (getPermissionsToQuery) on construction time.
  // Then, via the function can_i, the results obtained from the api call are queried.
  // This class is shared between the DCRV and DCPV.

class RBAC {
  static initClass() {

    this.PATH    = '/-/api/v1/users/users/can_i';
  }

  constructor(model, ignoreDefault) {
    this.permisionsReceived = this.permisionsReceived.bind(this);
    this.model = model;
    this.ignoreDefault = ignoreDefault;
    new Request.JSON({
      headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url       : RBAC.PATH,
      method    : 'post',
      data      : this.getPermissionsToQuery(),
      onSuccess : this.permisionsReceived
    }).send();
  }


  permisionsReceived(permissions) {
    return this.permissions = permissions;
  }

  getPermissionsToQuery() {
    return {
      permissions:
        {
          manage: ["Ivy::HwRack", "Ivy::Device", "Ivy::Chassis"],
          move:   ["Ivy::Device", "Ivy::Chassis"]
        }
    };
  }

  can_i(action, resource) {
    return this.permissions[action][resource] === true;
  }

  can_i_move_devices() {
    return this.can_i("move","Ivy::Device") || this.can_i("move","Ivy::Chassis");
  }

  can_i_manage_devices() {
    return this.can_i("manage","Ivy::Device") || this.can_i("manage","Ivy::Chassis");
  }
};
RBAC.initClass();
export default RBAC;
