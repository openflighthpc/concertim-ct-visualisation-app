/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from './Util';
import Events from './Events';

class StaticGroupManager {
  static initClass() {

    // statics overwritten by config
    this.GET     = 'get_req';
    this.LIST    = 'list_all_url';
    this.NEW     = 'set_req';
    this.UPDATE  = 'update_req';
  
    this.MODEL_DEPENDENCIES  = { selectedGroup: "selectedGroup", groupsById: "groupsById", deviceLookup: "deviceLookup" };
    this.DOM_DEPENDENCIES    = { saveDialogue: "group_save_dialogue", nameInput: 'group_save_input', createNewBtn: "create_group", updateBtn: "update_group", confirmGroupSave: "confirm_group_save", cancelGroupSave: "cancel_group_save" };

    this.ERR_INVALID_NAME       = 'Choose another name';
    this.ERR_DUPLICATE_NAME     = 'Choose another';
    this.ERR_CAPTION            = 'Failed: [[error_message]]';
    this.ERR_WHITE_NAME         = 'Failed: [[error_message]]';
    this.ERR_READ_ONLY          = 'The selected group is of type [[group_type]] and cannot be modified';
    this.ERR_EMPTY_GROUP        = 'Current selection is empty.';
    this.ERR_GROUP_DATA_CENTRE  = 'The current selection is your entire data centre. A group of this already exists';
    this.MSG_CONFIRM_UPDATE     = 'Aaaaw, really?';

    this.METRIC_LEVEL_ALL       = "all";
    this.METRIC_LEVEL_VHOSTS    = "vhosts";

    // constants and run-time assigned statics
    this.GROUP_ID_MAP = { chassis: 'chassisIds', devices: 'deviceIds', sensors: 'sensorIds', racks: 'rackIds' };
  }


  constructor(model, startUpGroup) {
    // store references to relevant model attributes for convenience
    this.updateGroup = this.updateGroup.bind(this);
    this.showSaveDialogue = this.showSaveDialogue.bind(this);
    this.confirmSave = this.confirmSave.bind(this);
    this.cancelSave = this.cancelSave.bind(this);
    this.evReceivedGroupList = this.evReceivedGroupList.bind(this);
    this.evSwitchGroup = this.evSwitchGroup.bind(this);
    this.evReceivedGroup = this.evReceivedGroup.bind(this);
    this.evShowGroupSaveDialogue = this.evShowGroupSaveDialogue.bind(this);
    this.evUpdateGroup = this.evUpdateGroup.bind(this);
    this.evConfirmGroupSave = this.evConfirmGroupSave.bind(this);
    this.evCancelGroupSave = this.evCancelGroupSave.bind(this);
    this.evGroupSent = this.evGroupSent.bind(this);
    this.evSelectionChange = this.evSelectionChange.bind(this);
    this.model = model;
    this.startUpGroup = startUpGroup;
    this.modelRefs      = {};
    for (var key in StaticGroupManager.MODEL_DEPENDENCIES) { this.modelRefs[key] = this.model[StaticGroupManager.MODEL_DEPENDENCIES[key]]; }

    new Request.JSON({
      headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url       : StaticGroupManager.LIST + (StaticGroupManager.LIST.indexOf('?') === -1 ? '?' : '&') + (new Date()).getTime(),
      onSuccess : this.evReceivedGroupList,
      onFail    : this.loadFail,
      onError   : this.loadError
    }).get();

    this.saveDialogueEl = $(StaticGroupManager.DOM_DEPENDENCIES.saveDialogue);

    this.modelRefs.selectedGroup.subscribe(this.evSwitchGroup);
    this.changeSub = this.modelRefs.activeSelection.subscribe(this.evSelectionChange);

    if (this.saveDialogueEl != null) { Util.setStyle(this.saveDialogueEl, 'display', 'none'); }

    let el = $(StaticGroupManager.DOM_DEPENDENCIES.createNewBtn);
    if (el != null) { Events.addEventListener(el, 'click', this.evShowGroupSaveDialogue); }
    el = $(StaticGroupManager.DOM_DEPENDENCIES.updateBtn);
    if (el != null) { Events.addEventListener(el, 'click', this.evUpdateGroup); }
    el = $(StaticGroupManager.DOM_DEPENDENCIES.confirmGroupSave);
    if (el != null) { Events.addEventListener(el, 'click', this.evConfirmGroupSave); }
    el = $(StaticGroupManager.DOM_DEPENDENCIES.cancelGroupSave);
    if (el != null) { Events.addEventListener(el, 'click', this.evCancelGroupSave); }

    document.GROUPS = this;
  }


  updateGroup() {
    console.log('StaticGroupManager.updateGroup');
    return this.sendGroup();
  }


  showSaveDialogue() {
    if (!this.groupsLoaded) { return; }
    Util.setStyle(this.saveDialogueEl, 'display', 'block');
    const input       = $(StaticGroupManager.DOM_DEPENDENCIES.nameInput);
    input.value = '';
    return input.focus();
  }


  confirmSave(name) {
    const groups = this.modelRefs.groupsById();
    for (var id in groups) {
      if (groups[id].name === name) {
        this.showError(StaticGroupManager.ERR_DUPLICATE_NAME);
        return;
      }
    }

    name = name.trim();

    if (name.length === 0) {
      this.showError(StaticGroupManager.ERR_WHITE_NAME);
      return;
    }

    this.sendGroup(name);
    return Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  cancelSave() {
    return Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  evReceivedGroupList(groups) {
    this.groupsLoaded = true;
    const groups_by_id = {};
    for (var group of Array.from(groups)) { groups_by_id[group.id] = group; }

    this.modelRefs.groupsById(groups_by_id);
    if ((groups.length > 0) && ($('groups') != null) && ($('groups').value === '')) { $('groups').value = 'Select a group'; }
    if (this.startUpGroup != null) { return this.modelRefs.selectedGroup(this.startUpGroup); }
  }


  evSwitchGroup(selected) {
    let i, selection;
    if (this.model.noGroupSelected()) {
      this.selectedGroup = null;
      this.model.resetFilters();
      return;
    }

    const groups = this.modelRefs.groupsById();

    for (i in groups) {
      if (groups[i].name === selected) {
        selection = groups[i];
        break;
      }
    }

    if ((selection != null ? selection.memberIds : undefined) != null) {
      return this.displayGroup(selection);
    } else {
      return new Request.JSON({
        headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
        url       : Util.substitutePhrase(StaticGroupManager.GET, 'group_id', i) + (StaticGroupManager.GET.indexOf('?') === -1 ? '?' : '&') + (new Date()).getTime(),
        onSuccess : this.evReceivedGroup,
        onFail    : this.loadFail,
        onError   : this.loadError
      }).get();
    }
  }


  evReceivedGroup(data) {
    const group = this.modelRefs.groupsById()[data.id];
  
    group.breachGroup = data.breachGroup;
    group.groupType   = data.groupType;
    group.memberIds   = data.memberIds;

    return this.displayGroup(group);
  }


  displayGroup(static_group) {

    let group;
    if (static_group == null) { return; }

    this.selectedGroup = static_group;
    const groups         = this.modelRefs.groups();
    const new_sel        = {};
    for (group of Array.from(groups)) { new_sel[group] = {}; }

    const metric_level = (document.IRV != null) ? document.IRV.model.metricLevel() : null;
    const device_lookup = this.modelRefs.deviceLookup();
  
    for (group in StaticGroupManager.GROUP_ID_MAP) {
      var accessor = StaticGroupManager.GROUP_ID_MAP[group];
      if ((new_sel[group] == null) || (static_group.memberIds[accessor] == null)) { continue; }

      if (metric_level && (metric_level !== StaticGroupManager.METRIC_LEVEL_ALL) && (metric_level !== StaticGroupManager.METRIC_LEVEL_VHOSTS)) {
        if (group !== metric_level) { continue; }
      }

      for (var id of Array.from(static_group.memberIds[accessor])) {
        if (metric_level === StaticGroupManager.METRIC_LEVEL_VHOSTS) {
          var current_device = device_lookup.devices[parseInt(id)];
          if (!current_device || !current_device.instances[0].virtualHost) { continue; }
        }

        new_sel[group][id] = true;
      }
    }

    this.changeSub.dispose();
    this.modelRefs.activeSelection(true);
    this.modelRefs.selectedDevices(new_sel);
    return this.changeSub = this.modelRefs.activeSelection.subscribe(this.evSelectionChange);
  }


  evShowGroupSaveDialogue(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.showSaveDialogue();
  }


  evUpdateGroup(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    const selected_group = this.modelRefs.selectedGroup();

    if (selected_group === undefined) { return; }

    if (this.selectedGroup.groupType !== 'StaticGroup') {
      alert_dialog(Util.substitutePhrase(StaticGroupManager.ERR_READ_ONLY, 'group_type', this.selectedGroup.groupType));
      return;
    }

    return confirm_dialog(Util.substitutePhrase(StaticGroupManager.MSG_CONFIRM_UPDATE, 'selected_group', selected_group), 'document.GROUPS.updateGroup()', 'void(0);', 'Please confirm', true, true);
  }


  evConfirmGroupSave(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.confirmSave($(StaticGroupManager.DOM_DEPENDENCIES.nameInput).value);
  }


  evCancelGroupSave(ev) {
    ev.preventDefault();
    ev.stopPropagation;
    return this.cancelSave();
  }


  showError(msg) {
    return alert_dialog(Util.substitutePhrase(StaticGroupManager.ERR_CAPTION, 'error_message', msg));
  }


  sendGroup(name) {
    // if a name is supplied, assume we're creating a new group
    let filter, group, id, selection;
    this.isNewGroup      = (name != null);
    const active_filter    = this.modelRefs.activeFilter();
    const active_selection = this.modelRefs.activeSelection();
    let device_lookup    = this.modelRefs.deviceLookup();
    const static_group     = {};
    const additions        = {};
    const deletions        = {};
    let empty            = true;

    for (group in StaticGroupManager.GROUP_ID_MAP) {
      static_group[group] = [];
      additions[group]    = [];
      deletions[group]    = [];
    }
  
    // find 
    if (!active_filter && !active_selection && (this.modelRefs.displayingAllRacks != null) && !this.modelRefs.displayingAllRacks()) {
      // grab everything
      for (group in device_lookup) {
        if (group === 'racks') { continue; }

        for (id in device_lookup[group]) {
          // provide only the device id in the case of a simple chassis
          if ((group === 'chassis') && !device_lookup.chassis[id].instances[0].complex) { continue; }
          if ((group === 'chassis') || (group === 'devices') || (group === 'sensors')) { empty = false; }
          static_group[group].push(id);
        }
      }

    } else if (active_filter && active_selection) {
      filter    = this.modelRefs.filteredDevices();
      selection = this.modelRefs.selectedDevices();

      for (group in static_group) {
        for (id in filter[group]) {
          // provide only the device id in the case of a simple chassis
          if ((group === 'chassis') && !device_lookup.chassis[id].instances[0].complex) { continue; }
          if ((group === 'chassis') || (group === 'devices') || (group === 'sensors')) { empty = false; }
          if (filter[group][id] && selection[group][id]) { static_group[group].push(id); }
        }
      }

    } else if (active_filter) {
      filter = this.modelRefs.filteredDevices();

      for (group in static_group) {
        for (id in filter[group]) {
          // provide only the device id in the case of a simple chassis
          if ((group === 'chassis') && !device_lookup.chassis[id].instances[0].complex) { continue; }
          if ((group === 'chassis') || (group === 'devices') || (group === 'sensors')) { empty = false; }
          if (filter[group][id]) { static_group[group].push(id); }
        }
      }

    } else if (active_selection) {
      selection = this.modelRefs.selectedDevices();

      for (group in static_group) {
        for (id in selection[group]) {
          // provide only the device id in the case of a simple chassis
          if ((group === 'chassis') && !device_lookup.chassis[id].instances[0].complex) { continue; }
          if ((group === 'chassis') || (group === 'devices') || (group === 'sensors')) { empty = false; }
          if (selection[group][id]) { static_group[group].push(id); }
        }
      }

    } else {
      // no filter or selection is set, requested group contains entire data centre
      alert_dialog(StaticGroupManager.ERR_GROUP_DATA_CENTRE);
      return;
    }

  
    // reject if group is empty
    if (empty) {
      alert_dialog(StaticGroupManager.ERR_EMPTY_GROUP);
      return;
    }


    // double check group doesnt include everything (equivalent of pre-defined data centre group)
    // this is quite IRV specific (though will only be called by the IRV). May need future
    // revision to make it more agnostic
    if ((this.modelRefs.displayingAllRacks != null) && this.modelRefs.displayingAllRacks()) {
      let includes_all  = true;
      device_lookup = this.modelRefs.deviceLookup();
      for (group in device_lookup) {
        var set = device_lookup[group];
        for (id in set) {
          var member = set[id];
          console.log(group, id, member.instances[0].included);
          if (!member.instances[0].included) {
            includes_all = false;
            break;
          }
        }

        if (!includes_all) { break; }
      }

      if (includes_all) {
        alert_dialog(StaticGroupManager.ERR_GROUP_DATA_CENTRE);
        return;
      }
    }


    this.newGroup = static_group;

    const payload = { group_type: 'static', member_ids_to_add: additions, member_ids_to_remove: deletions };

    if (name != null) {
      payload.name = name;
      payload.member_ids_to_add = static_group;
      this.selectedGroup = { name, breachGroup: false };
    } else {
      payload.name = this.selectedGroup.name;
      for (group in static_group) {
        var found, id2;
        var accessor  = StaticGroupManager.GROUP_ID_MAP[group];
        var old_group = this.selectedGroup.memberIds[accessor];

        if (old_group == null) { continue; }

        // search for additions
        for (id of Array.from(static_group[group])) {
          found = false;
          for (id2 of Array.from(old_group)) {
            if (id === id2) {
              found = true;
              break;
            }
          }

          if (!found) {
            payload.member_ids_to_add[group].push(id);
          }
        }

        // search for deletions
        for (id of Array.from(old_group)) {
          found = false;
          for (id2 of Array.from(static_group[group])) {
            if (id === Number(id2)) {
              found = true;
              break;
            }
          }

          if (!found) {
            payload.member_ids_to_remove[group].push(id);
          }
        }
      }
    }
          
    // serialize arrays for ruby to interpret them correctly
    for (group in payload.member_ids_to_remove) { payload.member_ids_to_remove[group] = JSON.stringify(payload.member_ids_to_remove[group]); }
    for (group in payload.member_ids_to_add) { payload.member_ids_to_add[group]    = JSON.stringify(payload.member_ids_to_add[group]); }

    new Request.JSON({
      headers    : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url        : Util.substitutePhrase(((name != null) ? StaticGroupManager.NEW : StaticGroupManager.UPDATE), 'group_id', ((name != null) ? null : this.selectedGroup.id)) + '?' + (new Date()).getTime(),
      method     : 'post',
      onComplete : this.evGroupSent,
      data       : payload
    }).send();

    // deserialize arrays, they'll be used again on successful response
    for (group in payload.member_ids_to_remove) { payload.member_ids_to_remove[group] = JSON.parse(payload.member_ids_to_remove[group]); }
    return (() => {
      const result = [];
      for (group in payload.member_ids_to_add) {
        result.push(payload.member_ids_to_add[group]    = JSON.parse(payload.member_ids_to_add[group]));
      }
      return result;
    })();
  }


  evGroupSent(response) {
    if (response.success) {
      const groups = this.modelRefs.groupsById();

      for (var group in this.newGroup) {
        if (StaticGroupManager.GROUP_ID_MAP[group] != null) {
          this.newGroup[StaticGroupManager.GROUP_ID_MAP[group]] = this.newGroup[group];
          delete this.newGroup[group];
        }
      }

      if (this.isNewGroup) { this.selectedGroup.id         = response.id; }
      if (this.isNewGroup) { this.selectedGroup.groupType  = 'StaticGroup'; }
      this.selectedGroup.memberIds  = this.newGroup;
      groups[this.selectedGroup.id] = this.selectedGroup;
      this.modelRefs.groupsById(groups);
      if (this.isNewGroup) { return this.modelRefs.selectedGroup(this.selectedGroup.name); }
    }
  }


  evSelectionChange(active_selection) {}
};
StaticGroupManager.initClass();
export default StaticGroupManager;

  //NOTE: "selectedGroup" is wired up in knockout to reset all the groups. It has been commented
  //out here because if you reset the group dropdown as a result of doing a rubber-band select,
  //it triggers teh "reset group" event which deselects the thing you rubber banded. Needs a 
  //fix but fine for now.
  //@modelRefs.selectedGroup(null)
