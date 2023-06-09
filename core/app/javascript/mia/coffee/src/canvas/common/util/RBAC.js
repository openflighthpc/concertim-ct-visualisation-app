import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';

// RBAC = Rule Based Access Control
//
// RBAC queries the api action /-/api/v1/users/can_i with a
// specific set of permissions (getPermissionsToQuery) on construction time.
// Then, via the function can_i, the results obtained from the api call are queried.
// This class is shared between the DCRV and DCPV.
class RBAC {
  static PATH = '/api/v1/users/can_i';

  constructor(model, ignoreDefault) {
    this.permisionsReceived = this.permisionsReceived.bind(this);
    this.model = model;
    this.ignoreDefault = ignoreDefault;
    new Request.JSON({
      headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url       : RBAC.PATH,
      method    : 'get',
      data      : this.getPermissionsToQuery(),
      onSuccess : this.permisionsReceived
    }).send();
  }


  permisionsReceived(permissions) {
    this.permissions = permissions;
  }

  getPermissionsToQuery() {
    return {
      permissions:
        {
          manage: ["Ivy::HwRack", "Ivy::Device", "Ivy::Chassis"],
          move:   ["Ivy::Device", "Ivy::Chassis"],
          view:   ["all"]
        }
    };
  }

  can_i(action, resource) {
    return this.permissions[action][resource] === true;
  }

  can_i_move_devices() {
    return this.can_i("move", "Ivy::Device") || this.can_i("move", "Ivy::Chassis");
  }

  can_i_manage_devices() {
    return this.can_i("manage", "Ivy::Device") || this.can_i("manage", "Ivy::Chassis");
  }
};

export default RBAC;
