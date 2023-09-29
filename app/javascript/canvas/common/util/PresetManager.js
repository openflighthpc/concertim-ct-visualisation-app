/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';
import Events from 'canvas/common/util/Events';
import Profiler from 'Profiler';

class PresetManager {
  // statics overwritten by config
  static PATH    = 'path/to/preset/api';
  static GET     = 'get_req';
  static NEW     = 'set_req';
  static UPDATE  = 'update_req';
  static VALUES  = [{ type: 'simple', name: 'viewMode' }, { type: 'simple', name: 'scaleMetrics' }, { type: 'simple', name: 'face' }];

  static MODEL_DEPENDENCIES  = { selectedPreset: "selectedPreset", presetsById: "presetsById" };
  static DOM_DEPENDENCIES    = { saveDialogue: "save_dialogue", nameInput: 'save_input', defaultAccessor: { element: 'rack_view', property: 'data-preset' } };

  static MSG_CONFIRM_UPDATE     = 'Are you sure you wish to overwrite the preset [[selected_preset]] with the current display settings?';
  static ERR_INVALID_NAME       = 'Choose another name';
  static ERR_DUPLICATE_NAME     = 'Choose another';
  static ERR_CAPTION            = 'Failed: [[error_message]]';
  static ERR_WHITE_NAME         = 'Failed: [[error_message]]';

  static EMPTY_PRESET           = {values: {selectedMetric: null, gradientLBCMetric: false, face: 'front', viewMode: 'Images and bars', graphOrder: 'descending', scaleMetrics: true, showChart: true, metricPollRate: 60000} };


  constructor(model, ignoreDefault) {
    this.presetsReceived = this.presetsReceived.bind(this);
    this.switchPreset = this.switchPreset.bind(this);
    this.handleSaveResponse = this.handleSaveResponse.bind(this);
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
  }


  updatePreset() {
    this.sendPreset();
  }


  showSaveDialogue() {
    Util.setStyle(this.saveDialogueEl, 'display', 'block');
    const input       = $(PresetManager.DOM_DEPENDENCIES.nameInput);
    input.value = '';
    input.focus();
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
    Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  cancelSave() {
    Util.setStyle(this.saveDialogueEl, 'display', 'none');
  }


  pagePresetDefault() {
    const el = $(PresetManager.DOM_DEPENDENCIES.defaultAccessor.element);
    if (el == null) { return; }
    return el.get(PresetManager.DOM_DEPENDENCIES.defaultAccessor.property);
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
    if (default_preset != null) {
      this.modelRefs.selectedPreset(default_preset);
    }
  }

  switchPreset() {
    const selectedPresetName = this.modelRefs.selectedPreset();

    const preset = Object.values(this.modelRefs.presetsById()).find(p => p.name === selectedPresetName)
      || PresetManager.EMPTY_PRESET;

    if (this.model.crossAppSettings === true) {
      this.model.crossAppSettings = false;
    } else {
      this.model.activeSelection(false);
      this.model.selectedDevices(this.model.getBlankGroupObject());
    }

    this.debug('::: switching to preset', selectedPresetName, preset);
    this.model.loadingAPreset(true);

    this.selected = preset;

    for (var val_def of Array.from(PresetManager.VALUES)) {
      var val_name = val_def.name;
      if (!preset.values.hasOwnProperty(val_name)) {
        this.debug('skipping', val_name, 'not present');
        continue;
      }
      try {
        // only update the model if current value is different from preset value
        // this is only effective for simple data types
        const key = (val_def.key != null) ? preset.values[val_def.key] : null;
        const currentVal = (key != null) ? this.model[val_name]()[key] : this.model[val_name]();
        const newVal = preset.values[val_name];

        if (currentVal !== newVal) {
          if (key != null) {
            var obj      = this.model[val_name]();
            obj[key] = newVal;
            this.debug(`setting ${val_name} (key: ${key}) key set to`, newVal, 'obj =', obj);
            this.model[val_name](obj);
          } else {
            this.debug('setting', val_name, '=', newVal);
            this.model[val_name](newVal);
          }
        } else {
          this.debug('skipping', val_name, 'unchanged');
        }
      } catch (err) {
        this.debug('failed to map', val_name, err);
      }
    }

    if (preset.values.selectedMetric == null) {
      // The new metric doesn't have an associated metric.  An devices filtered
      // based on metric value are therefore outdated.
      this.model.resetFilter();
    }

    this.model.loadingAPreset(false);
  }


  // Send a request to create/update a preset to the API server.
  sendPreset(name) {
    const isCreating = (name != null);
    if ((this.selected == null) && !isCreating) { return; }

    const payload = this.buildPayload(isCreating, name);

    fetch(this.buildUrl(isCreating), {
      method: isCreating ? 'POST' : 'PUT',
      headers    : {
        'X-CSRF-Token': $$('meta[name="csrf-token"]')[0].getAttribute('content'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({preset: payload}),
    })
      .then(response => response.json())
      .then(this.handleSaveResponse)
      .catch(this.handleSaveResponse);
  }

  // Return a payload object of the current selections and keep a record of the
  // changes made from the currently selected preset.
  buildPayload(isCreating, name) {
    // this.change stores the latest change to a preset from an update or new
    // request this is used to maintain synchonisation locally without
    // re-requesting the presets from the server
    this.change = { values: {} };
    const payload = { values: {} };

    if (isCreating) {
      this.change.name = name;
      this.change.default = false;
      payload.name = name;
      payload.default = false;
    } else {
      this.change.default = this.selected.default;
      payload.name = this.selected.name;
      payload.default = this.selected.default;
    }

    for (var val of Array.from(PresetManager.VALUES)) {
      // The value currently assigned to the preset.
      var presetValue;
      if (val.key != null) {
        presetValue = this.model[val.name]()[this.model[val.key]()];
      } else {
        presetValue = this.model[val.name]();
      }

      // XXX Is this the issue.  Why don't we record values set as null?
      // if (presetValue != null) { this.change.values[val.name] = presetValue; }
      this.change.values[val.name] = presetValue;
      payload.values[val.name] = presetValue;
    }
    this.debug(isCreating ? 'creating' : 'updating', 'payload=', payload);
    return payload;
  }

  buildUrl(isCreating) {
    const prefix = PresetManager.PATH;
    const path = isCreating ? PresetManager.NEW : PresetManager.UPDATE;
    const id = this.selected != null ? this.selected.id : null;
    const timeStamp = (new Date()).getTime();
    const url = prefix + Util.substitutePhrase(path, 'preset_id', id) + '?' + timeStamp;
    return url;
  }


  // Handle the response from creating or updating a preset.
  handleSaveResponse(response) {
    this.debug('received response', response);
    if (response.success === "true") {
      const switch_to = (this.change.name != null);
      const presets = this.modelRefs.presetsById();
      this.change.id = response.id;
      if (!switch_to) { this.change.name = presets[response.id].name; }
      presets[response.id] = this.change;

      this.modelRefs.presetsById(presets);
      if (switch_to) {
        this.selSub.dispose();
        this.selected = this.change;
        if (switch_to) { this.modelRefs.selectedPreset(this.change.name); }
        this.selSub = this.modelRefs.selectedPreset.subscribe(this.switchPreset);
      }
      Profiler.trace(Profiler.INFO, this.change);
    } else {
      this.showError(response);
    }
  }


  showError(msg) {
    if(msg.hasOwnProperty("errors")) {
      msg = msg.errors;
    }

    alert_dialog(Util.substitutePhrase(PresetManager.ERR_CAPTION, 'error_message', msg));
  }


  evShowPresetSaveDialogue(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    this.showSaveDialogue();
  }


  evUpdatePreset(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    const selected_preset = this.modelRefs.selectedPreset();
    if (selected_preset === undefined) { return; }
    const message = Util.substitutePhrase(PresetManager.MSG_CONFIRM_UPDATE, 'selected_preset', selected_preset);
    confirm_dialog(message, 'Please confirm', true)
      .then(() => { this.updatePreset(); })
      .catch(() => {});
  }


  evConfirmPresetSave(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    this.confirmSave($(PresetManager.DOM_DEPENDENCIES.nameInput).value);
  }


  evCancelPresetSave(ev) {
    ev.preventDefault();
    ev.stopPropagation;
    this.cancelSave();
  }

  debug(...msg) {
    console.debug(this.constructor.name, ...msg);
  }
};

export default PresetManager;
