import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';

// RBAC = Rule Based Access Control
//
// RBAC queries the api action /-/api/v1/users/permissions on construction time.
// Then, via the function can_i, the results obtained from the api call are queried.
class RBAC {
  static PATH = '/api/v1/users/permissions';

  constructor({onSuccess}) {
    this.onSuccessCallback = onSuccess;
    this.permisionsReceived = this.permisionsReceived.bind(this);
    this.debug("loading permissions");
    new Request.JSON({
      headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url       : RBAC.PATH,
      method    : 'get',
      onSuccess : this.permisionsReceived
    }).send();
  }


  isLoaded() {
    return this.permissions != null;
  }

  permisionsReceived(permissions) {
    this.debug("received permissions");
    this.permissions = permissions;
    if (this.onSuccessCallback) {
      this.onSuccessCallback()
    }
  }

  can_i(action, resource, teamRole) {
    return this.permissions[action][resource].includes(teamRole);
  }

  can_i_move_device(device) {
    return this.can_i("move", "devices", device.teamRole) || this.can_i("move", "chassis", device.teamRole);
  }

  can_i_manage_device(device) {
    return this.can_i("manage", "devices", device.teamRole) || this.can_i("manage", "chassis", device.teamRole);
  }

  debug(...msg) {
    console.debug('RBAC:', ...msg);
  }
};

export default RBAC;
