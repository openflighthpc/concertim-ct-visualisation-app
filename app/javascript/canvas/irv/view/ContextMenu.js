/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import ViewModel from 'canvas/irv/ViewModel';
import  Rack from 'canvas/irv/view/Rack';
import  Chassis from 'canvas/irv/view/Chassis';
import  Machine from 'canvas/irv/view/Machine';
import  Util from 'canvas/common/util/Util';
import  Events from 'canvas/common/util/Events';
import  Profiler from 'Profiler';

class ContextMenu {
  static initClass() {

    // statics overwritten by config
    this.OPTIONS              = {};
    this.URL_INTERNAL_PREFIX  = 'internal::';
    this.VERBOSE              = true;
    this.SPACER               = '<br>';
    this.ASPECT_MAP           = { front: 'f', rear: 'r' };
    this.ACTION_PATHS         = {};
    this.DETAILED_METRICS_PATH = "";
  }


  constructor(containerEl, model, internalCallback) {
    this.evClick = this.evClick.bind(this);
    this.containerEl = containerEl;
    this.model = model;
    this.internalCallback = internalCallback;
    this.visible = false;
    this.menuEl  = $('context_menu');
    Events.addEventListener(this.menuEl, 'click', this.evClick);
  }


  show(device, x, y, available_slot) {
    let aspect, chassis_id, chassis_name, child, device_id, device_name, empty_column, empty_row, empty_u, rack_id, rack_name, slot_id;
    const option_keys = ['common'];

    if (device != null) {
      device_id   = device.id;
      device_name = device.name;
      child       = device;
    } else {
      option_keys.push('global');
    }

    // iterate through device-parent hierarchy of selected item and collate a list of options to include
    while (child != null) {
      switch (child.componentClassName) {
        case 'devices':
          device_id   = child.id;
          device_name = child.name != null ? child.name : child.id;
          break;
        case 'chassis':
          chassis_id   = child.id;
          chassis_name = child.name != null ? child.name : child.id;
          break;
        case 'racks':
          rack_id   = child.id;
          rack_name = child.name != null ? child.name : child.id;
          aspect    = this.model.face();
          if (aspect === ViewModel.FACE_BOTH) { aspect    = child.bothView; }
          aspect    = ContextMenu.ASPECT_MAP[aspect];
          break;
        default:
          Profiler.trace(Profiler.CRITICAL, this.show, '***** UNKNOWN CLASS NAME: %s ******', child.componentClassName);
      }

      option_keys.push(child.componentClassName);
      if (ContextMenu.VERBOSE) {
        child = child.parent;
      } else {
        child = null;
      }
    }
  
    if (available_slot != null) {
      if (available_slot.type === 'chassis') {
        empty_row    = available_slot.row + 1;
        empty_column = available_slot.column + 1;
        slot_id      = available_slot.id;
      } else {
        empty_u = available_slot.row + 1;
      }
    }

    // create array of options based upon option_keys
    const options_html = [];
    let parsed       = [];
    let total_clickable_options_added = 0;
    for (var option_set in ContextMenu.OPTIONS) {
      if (option_keys.indexOf(option_set) !== -1) {
        var view_devices;
        var idx = parsed.length;
        parsed.push([]);

        var total_options = [].concat(ContextMenu.OPTIONS[option_set]);

        if (option_set === "racks") { 
          if (device.children.length > 0) {
            view_devices = "View devices";
          }
        }
        
        for (var option of Array.from(total_options)) {
          // If the option has the attribute RBAC defined, then query the @model.RBAC object 
          // to see if such permission has been granted. Otherwise, continue to the next option.
          if (option.RBAC != null) {
            if (!this.model.RBAC.can_i(option.RBAC.action,option.RBAC.resource)) { continue; }
          }

          if (option.availableToBuildStatuses !== undefined && option.availableToBuildStatuses.indexOf(device.buildStatus) === -1) {
            continue;
          }

          var div_class  = (option.class != null) ? option.class : "";
          var piece      = option.caption != null ? option.caption : option.content;
          var option_url = option.url;
          var disabled   = false;
          var on_click   = disabled ? null : option.onClick;

          piece = Util.substitutePhrase(piece, 'view_devices', view_devices);
          piece = Util.substitutePhrase(piece, 'device_id', device_id);
          piece = Util.substitutePhrase(piece, 'device_name', device_name);
          piece = Util.substitutePhrase(piece, 'chassis_id', chassis_id);
          piece = Util.substitutePhrase(piece, 'chassis_name', chassis_name);
          piece = Util.substitutePhrase(piece, 'rack_id', rack_id);
          piece = Util.substitutePhrase(piece, 'rack_name', rack_name);
          piece = Util.substitutePhrase(piece, 'empty_row', empty_row);
          piece = Util.substitutePhrase(piece, 'empty_col', empty_column);
          piece = Util.substitutePhrase(piece, 'empty_u', empty_u);
          piece = Util.substitutePhrase(piece, 'slot_id', slot_id);
          piece = Util.substitutePhrase(piece, 'aspect', aspect);
          piece = Util.substitutePhrase(piece, 'spacer', ContextMenu.SPACER);

          piece = Util.cleanUpSubstitutions(piece);

          if (!disabled) {
            if (option_url != null) {
              option_url = Util.substitutePhrase(option_url, 'device_id', device_id);
              option_url = Util.substitutePhrase(option_url, 'device_name', device_name);
              option_url = Util.substitutePhrase(option_url, 'chassis_id', chassis_id);
              option_url = Util.substitutePhrase(option_url, 'chassis_name', chassis_name);
              option_url = Util.substitutePhrase(option_url, 'rack_id', rack_id);
              option_url = Util.substitutePhrase(option_url, 'rack_name', rack_name);
              option_url = Util.substitutePhrase(option_url, 'empty_row', empty_row);
              option_url = Util.substitutePhrase(option_url, 'empty_col', empty_column);
              option_url = Util.substitutePhrase(option_url, 'empty_u', empty_u);
              option_url = Util.substitutePhrase(option_url, 'aspect', aspect);
              option_url = Util.substitutePhrase(option_url, 'slot_id', slot_id);

              option_url = Util.cleanUpSubstitutions(option_url);
            }

            if (on_click != null) {
              on_click = Util.substitutePhrase(on_click, 'device_id', device_id);
              on_click = Util.substitutePhrase(on_click, 'device_name', device_name);
              on_click = Util.substitutePhrase(on_click, 'chassis_id', chassis_id);
              on_click = Util.substitutePhrase(on_click, 'chassis_name', chassis_name);
              on_click = Util.substitutePhrase(on_click, 'rack_id', rack_id);
              on_click = Util.substitutePhrase(on_click, 'rack_name', rack_name);
              on_click = Util.substitutePhrase(on_click, 'empty_row', empty_row);
              on_click = Util.substitutePhrase(on_click, 'empty_col', empty_column);
              on_click = Util.substitutePhrase(on_click, 'empty_u', empty_u);
              on_click = Util.substitutePhrase(on_click, 'aspect', aspect);
              on_click = Util.substitutePhrase(on_click, 'slot_id', slot_id);

              on_click = Util.cleanUpSubstitutions(on_click);
            }
          }

          if (piece.length > 0) {
            if (option_url != null) {
              if (disabled) {
                parsed[idx].push(`<a href='javascript: void(0);'><div class='disabled_context_menu_item'>${piece}</div></a>`);
              } else if (on_click != null) {
                total_clickable_options_added += 1;
                parsed[idx].push(`<a href='${option_url}' onclick=\"${on_click}\" ><div class='context_menu_item ${div_class}'>${piece}</div></a>`);
              } else {
                total_clickable_options_added += 1;
                parsed[idx].push(`<a href='${option_url}'><div class='context_menu_item ${div_class}'>${piece}</div></a>`);
              }
            } else {
              parsed[idx].push(piece);
            }
          }
        }

        parsed[idx] = parsed[idx].join('');
        if (parsed[idx].length === 0) { parsed.splice(idx, 1); }
      }
    }

    // if there is something to click, then show the context menu
    if (total_clickable_options_added > 0) {
      this.visible = true;
      parsed = parsed.reverse();
      this.menuEl.innerHTML = parsed.join(ContextMenu.SPACER);

      // adjust when near to edges of the screen
      let div_x = Util.getStyle(this.containerEl, 'left');
      div_x = div_x.substr(0, div_x.length - 2);

      const container_dims = Util.getElementDimensions(this.containerEl);
      const menu_dims      = Util.getElementDimensions(this.menuEl);

      x = (x + menu_dims.width) > container_dims.width ? container_dims.width - menu_dims.width : x;
      y = (y + menu_dims.height) > container_dims.height ? container_dims.height - menu_dims.height : y;
      if (y < 0) { y = 0; }

      Util.setStyle(this.menuEl, 'left', x + 'px');
      Util.setStyle(this.menuEl, 'top', y + 'px');
      return Util.setStyle(this.menuEl, 'visibility', 'visible');
    }
  }


  hide() {
    if (this.visible) {
      this.visible = false;
      return Util.setStyle(this.menuEl, 'visibility', 'hidden');
    }
  }


  evClick(ev) {
    const url = ev.target.parentElement.getAttribute('href');
    this.coords = Util.resolveMouseCoords(this.menuEl, ev);
  
    if (url == null) { return; }

    if (url.substr(0, ContextMenu.URL_INTERNAL_PREFIX.length) === ContextMenu.URL_INTERNAL_PREFIX) {
      ev.preventDefault();
      ev.stopPropagation();

      this.internalCallback(url.substr(ContextMenu.URL_INTERNAL_PREFIX.length));
    }

    return this.hide();
  }
};
ContextMenu.initClass();
export default ContextMenu;
