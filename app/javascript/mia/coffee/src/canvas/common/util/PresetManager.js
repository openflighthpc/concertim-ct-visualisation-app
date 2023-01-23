/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from './Util';
import Events from './Events';
import Profiler from 'Profiler';

class PresetManager {
  static initClass() {

    // statics overwritten by config
    this.PATH    = 'path/to/preset/api';
    this.GET     = 'get_req';
    this.NEW     = 'set_req';
    this.UPDATE  = 'update_req';
    this.VALUES  = [{ type: 'simple', name: 'viewMode' }, { type: 'simple', name: 'scaleMetrics' }, { type: 'simple', name: 'face' }];
  
    this.MODEL_DEPENDENCIES  = { selectedPreset: "selectedPreset", presetsById: "presetsById" };
    this.DOM_DEPENDENCIES    = { saveDialogue: "save_dialogue", nameInput: 'save_input', defaultAccessor: { element: 'rack_view', property: 'data-preset' } };

    this.MSG_CONFIRM_UPDATE     = 'Are you sure you wish to overwrite the preset [[selected_preset]] with the current display settings?';
    this.ERR_INVALID_NAME       = 'Choose another name';
    this.ERR_DUPLICATE_NAME     = 'Choose another';
    this.ERR_CAPTION            = 'Failed: [[error_message]]';
    this.ERR_WHITE_NAME         = 'Failed: [[error_message]]';
    this.WARN_THRESHOLD         = 'No threshold has been associated with your chosen preset.';
    this.MESSAGE_HOLD_DURATION  = 1;
    this.METRIC_NOT_VALID       = 'Metric not valid';

    this.EMPTY_PRESET           = {values: {selectedMetric: '"No metric selected"', gradientLBCMetric: 'false', face: '"front"', viewMode: '"Images and bars"', graphOrder: '"descending"', scaleMetrics: 'true', showChart: 'true', metricPollRate: 60000} };

    // constants and run-time assigned statics
    this.VALUES_BY_NAME = {};
  }


  constructor(model, ignoreDefault) {
    this.updatePreset = this.updatePreset.bind(this);
    this.showSaveDialogue = this.showSaveDialogue.bind(this);
    this.confirmSave = this.confirmSave.bind(this);
    this.cancelSave = this.cancelSave.bind(this);
    this.presetsReceived = this.presetsReceived.bind(this);
    this.switchPreset = this.switchPreset.bind(this);
    this.response = this.response.bind(this);
    this.evShowPresetSaveDialogue = this.evShowPresetSaveDialogue.bind(this);
    this.evUpdatePreset = this.evUpdatePreset.bind(this);
    this.evConfirmPresetSave = this.evConfirmPresetSave.bind(this);
    this.evCancelPresetSave = this.evCancelPresetSave.bind(this);
    this.model = model;
    this.ignoreDefault = ignoreDefault;
    new Request.JSON({
      headers   : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url       : PresetManager.PATH + PresetManager.GET + '?' + (new Date()).getTime(),
      onSuccess : this.presetsReceived,
      onFail    : this.loadFail,
      onError   : this.loadError
    }).get();

    for (var val of Array.from(PresetManager.VALUES)) { PresetManager.VALUES_BY_NAME[val.name] = val; }

    // create model reference store
    this.modelRefs      = {};
    for (var key in PresetManager.MODEL_DEPENDENCIES) { var value = PresetManager.MODEL_DEPENDENCIES[key]; this.modelRefs[key] = this.model[value]; }

    this.saveDialogueEl = $(PresetManager.DOM_DEPENDENCIES.saveDialogue);
    this.selSub         = this.modelRefs.selectedPreset.subscribe(this.switchPreset);

    Util.setStyle(this.saveDialogueEl, 'display', 'none');

    Events.addEventListener($(PresetManager.DOM_DEPENDENCIES.createNewBtn), 'click', this.evShowPresetSaveDialogue);
    Events.addEventListener($(PresetManager.DOM_DEPENDENCIES.updateBtn), 'click', this.evUpdatePreset);
    Events.addEventListener($(PresetManager.DOM_DEPENDENCIES.saveBtn), 'click', this.evConfirmPresetSave);
    Events.addEventListener($(PresetManager.DOM_DEPENDENCIES.cancelBtn), 'click', this.evCancelPresetSave);

    document.PRESETS = this;
  }


  updatePreset() {
    return this.sendPreset();
  }


  showSaveDialogue() {
    Util.setStyle(this.saveDialogueEl, 'display', 'block');
    const input       = $(PresetManager.DOM_DEPENDENCIES.nameInput);
    input.value = '';
    return input.focus();
  }


  confirmSave(name) {
    const presets = this.modelRefs.presetsById();
    for (var id in presets) {
      if (presets[id].name === name) {
        this.showError(PresetManager.ERR_DUPLICATE_NAME);
        return;
      }
    }

    name = name.trim();

    if (name.length === 0) {
      this.showError(PresetManager.ERR_WHITE_NAME);
      return;
    }

    this.sendPreset(name);
    return Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  cancelSave() {
    return Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  parseBoolean(val) {
    return val === 'true';
  }


  pagePresetDefault() {
    return __guard__($(PresetManager.DOM_DEPENDENCIES.defaultAccessor.element), x => x.get(PresetManager.DOM_DEPENDENCIES.defaultAccessor.property));
  }


  presetExists(preset_id_to_find, preset_ids) {
    return preset_ids.some((el, idx) => preset_id_to_find === el);
  }


  presetsReceived(presets) {
    let default_preset;
    const presets_by_id = {};
    const page_preset_default = this.ignoreDefault ? null : this.pagePresetDefault();

    for (var preset of Array.from(presets)) {
      presets_by_id[preset.id] = preset;
      if (!this.ignoreDefault && (preset.default === true)) { default_preset           = preset.name; }
    }

    // set model
    this.modelRefs.presetsById(presets_by_id);

    // check to see if the page default preset exists, if it does overwrite the selected default preset
    if (this.presetExists(page_preset_default, Object.keys(presets_by_id))) { default_preset = presets_by_id[page_preset_default].name; }

    // select the default preset, if defined
    if ((default_preset != null) && (this.model.locatingBreachingNodes === false)) {
      return this.modelRefs.selectedPreset(default_preset);
    }
  }

  switchPreset() {
    let selection;
    const presets  = this.modelRefs.presetsById();
    const selected = this.modelRefs.selectedPreset();
    Profiler.trace(Profiler.INFO, "Preset Manager ::::::: switch preset " + selected);
    for (var i in presets) {
      if (presets[i].name === selected) {
        selection = presets[i];
        break;
      }
    }

    if (this.model.crossAppSettings === true) {
      this.model.crossAppSettings = false;
    } else {
      this.model.activeSelection(false);
      this.model.selectedDevices(this.model.getBlankGroupObject());
    }
    return this.displayPreset(selection);
  }


  displayPreset(preset) {
    this.model.loadingAPreset(true);

    if (preset == null) {
      preset = PresetManager.EMPTY_PRESET;
    }

    this.selected = preset;
  
    if (!preset.values.hasOwnProperty('selectedGroup')) { preset.values.selectedGroup = '""'; }
    if (!this.model.validMetric(JSON.parse(preset.values.selectedMetric))) { preset.values.selectedMetric = '"'+PresetManager.METRIC_NOT_VALID+'"'; }

    for (var val_def of Array.from(PresetManager.VALUES)) {
      var val_name = val_def.name;
      if (!preset.values.hasOwnProperty(val_name)) { continue; }
      if ((val_name === 'selectedGroup') && (this.model.activeSelection() === true)) { continue; }
      Profiler.trace(Profiler.INFO, 'PresetManager mapping ' + val_name);
      try {
        // only update the model if current value is different from preset value
        // this is only effective for simple data types
        var new_val;
        var key     = (val_def.key != null) ? JSON.parse(preset.values[val_def.key]) : null;
        var current = (key != null) ? this.model[val_name]()[key] : this.model[val_name]();
        if (preset.values[val_name] != null) { new_val = JSON.parse(preset.values[val_name]); }
        if (new_val === 'true') { new_val = true; }
        if (new_val === 'false') { new_val = false; }
        if (new_val === "") { new_val = null; }

        if ((val_name === 'selectedThresholdId') && ((new_val == null) || (this.model.thresholdsById()[new_val] == null))) {
          MessageSlider.instance.display(PresetManager.WARN_THRESHOLD, PresetManager.WARN_THRESHOLD, PresetManager.MESSAGE_HOLD_DURATION, new Date());
        } else if (current !== new_val) {
          if (key != null) {
            var obj      = this.model[val_name]();
            obj[key] = new_val;
            this.model[val_name](obj);
          } else {
            this.model[val_name](new_val);
          }
        }
      } catch (err) {
        Profiler.trace(Profiler.CRITICAL, 'Failed to map preset value "' + val_name + '" ' + err);
      }
    }

    return this.model.loadingAPreset(false);
  }


  sendPreset(name) {
    const create_new = (name != null);

    if ((this.selected == null) && !create_new) { return; }

    // @change stores the latest change to a preset from an update or new request
    // this is used to maintain synchonisation locally without re-requesting the presets
    // from the server
    this.change = { values: {} };
    const payload = { 'preset[values]': {} };

    if (create_new) {
      this.change.name               = name;
      this.change.default            = false;
      payload['preset[name]']    = name;
      payload['preset[default]'] = false;
    } else {
      this.change.default            = this.selected.default;
      payload['preset[id]']      = this.selected.id;
      payload['preset[name]']    = this.selected.name;
      payload['preset[default]'] = this.selected.default;
    }

    for (var val of Array.from(PresetManager.VALUES)) {
      var str_val;
      if (val.key != null) {
        str_val = JSON.stringify(this.model[val.name]()[this.model[val.key]()]);
      } else {
        str_val = JSON.stringify(this.model[val.name]());
      }

      if (str_val != null) { this.change.values[val.name] = str_val; }
      payload['preset[values]'][val.name] = str_val;
    }
    Profiler.trace(Profiler.INFO, payload);
    return new Request.JSON({
      headers    : {'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content')},
      url        : PresetManager.PATH + Util.substitutePhrase((create_new ? PresetManager.NEW : PresetManager.UPDATE), 'preset_id', (this.selected != null) ? this.selected.id : null) + '?' + (new Date()).getTime(),
      method     : 'post',
      onComplete : this.response,
      data       : payload
    }).send();
  }


  response(response) {
    Profiler.trace(Profiler.INFO, response);
    if (response.success === "true") {
      const switch_to            = (this.change.name != null);
      const presets              = this.modelRefs.presetsById();
      this.change.id           = response.id;
      if (!switch_to) { this.change.name         = presets[response.id].name; }
      presets[response.id] = this.change;

      this.modelRefs.presetsById(presets);
      if (switch_to) {
        this.selSub.dispose();
        this.selected = this.change;
        if (switch_to) { this.modelRefs.selectedPreset(this.change.name); }
        this.selSub = this.modelRefs.selectedPreset.subscribe(this.switchPreset);
      }
      return Profiler.trace(Profiler.INFO, this.change);
    } else {
      return this.showError(response);
    }
  }


  showError(msg) {
    if(msg.hasOwnProperty("errors")) {
      msg = msg.errors;
    }

    return alert_dialog(Util.substitutePhrase(PresetManager.ERR_CAPTION, 'error_message', msg));
  }


  evShowPresetSaveDialogue(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.showSaveDialogue();
  }


  evUpdatePreset(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    const selected_preset = this.modelRefs.selectedPreset();
    if (selected_preset === undefined) { return; }
    return confirm_dialog(Util.substitutePhrase(PresetManager.MSG_CONFIRM_UPDATE, 'selected_preset', selected_preset), 'document.PRESETS.updatePreset()', 'void(0);', 'Please confirm', true, true);
  }


  evConfirmPresetSave(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    return this.confirmSave($(PresetManager.DOM_DEPENDENCIES.nameInput).value);
  }


  evCancelPresetSave(ev) {
    ev.preventDefault();
    ev.stopPropagation;
    return this.cancelSave();
  }
};
PresetManager.initClass();
export default PresetManager;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
