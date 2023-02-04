/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import CanvasViewModel from 'canvas/common/CanvasViewModel';
import CanvasParser from 'canvas/common/CanvasParser';
import CanvasSpace from 'canvas/common/CanvasSpace';
import Util from 'canvas/common/util/Util';
import Configurator from 'canvas/irv/util/Configurator';
import AssetManager from 'canvas/irv/util/AssetManager';
import Profiler from 'Profiler';

class CanvasController {
  static initClass() {
    this.NUM_RESOURCES                 = 0;
    this.PRIMARY_IMAGE_PATH            = '';
    this.SECONDARY_IMAGE_PATH          = '';
    this.RESOURCE_LOAD_CAPTION         = 'Loading Resources<br>[[progress]]';

    this.LIVE                          = false;
    this.LIVE_RESOURCES                = {};
    this.OFFLINE_RESOURCES             = {};
  }

  constructor(options) {
    this.getConfig = this.getConfig.bind(this);
    this.configReceived = this.configReceived.bind(this);
    this.evLoadRackAssets = this.evLoadRackAssets.bind(this);
    this.rackIdsAsParams = this.rackIdsAsParams.bind(this);
    this.getRackDefs = this.getRackDefs.bind(this);
    this.receivedRackDefs = this.receivedRackDefs.bind(this);
    this.evAssetLoaded = this.evAssetLoaded.bind(this);
    this.evAssetFailed = this.evAssetFailed.bind(this);
    this.evAssetDoubleFailed = this.evAssetDoubleFailed.bind(this);
    if (options == null) { options = {}; }
    this.options = options;
    this.showStartedTime();
    this.options_show = this.options.show.split(',');
    Profiler.makeCompatible();
    Profiler.LOG_LEVEL  = Profiler.INFO;
    Profiler.TRACE_ONLY = true;
    document._P         = Profiler;
    document._U         = Util;
    this.initialised        = false;
    this.rackParent      = $(this.options.parent_div_id);
  }

  // loads configuration file during start up
  getConfig() {
    document.getElementById('dialogue').innerHTML = 'Loading config';
    return new Request.JSON({url: this.config_file + '?' + (new Date()).getTime(), onSuccess: this.configReceived, onFail: this.loadFail, onError: this.loadError}).get();
  }

  configReceived(config) {
    Configurator.setup(CanvasController, null, config);
    AssetManager.setup(); 
    CanvasController.NUM_RESOURCES = 1; //Rack structure
    this.model = new CanvasViewModel();
    this.parser   = new CanvasParser(this.model);
    this.setResources();
    this.evLoadRackAssets();
    return this.getRackData();
  }

  // assetList model value subscriber, commences loading of rack images
  evLoadRackAssets() {
    this.assetCount = 0;
    const assets      = this.model.assetList();

    for (var asset of Array.from(assets)) {
      AssetManager.get(CanvasController.PRIMARY_IMAGE_PATH + asset, this.evAssetLoaded, this.evAssetFailed);
    }

    return this.model.assetList(assets);
  }

  getRackData() {
    let rack__ids;
    if ((this.options != null ? this.options.rackIds : undefined) != null) {
      rack__ids = this.rackIdsAsParams(this.options.rackIds);
    } else if ((this.crossAppSettings != null) && (this.crossAppSettings.selectedRacks != null)) {
      this.model.displayingAllRacks(false);
      if (Object.keys(this.crossAppSettings.selectedRacks).length === 0) {
        rack__ids = 'none';
      } else if (((this.options != null) && (this.options.applyfilter === "true")) || ($(options.parent_div_id).get('data-filter') != null) || ($(this.options.parent_div_id).get('data-focus') != null)) {
        rack__ids = this.rackIdsAsParams(Object.keys(this.crossAppSettings.selectedRacks));
      } else {
        rack__ids = null;
      }
    } else { 
      rack__ids = null;
    }

    // If no racks to search, then skip the getRackDefs function, 
    // and send an empty hash to the receivedRackDefs function
    if (rack__ids === 'none') {
      return this.receivedRackDefs({});
    } else {
      return this.getRackDefs(rack__ids);
    }
  }

  // turns an array of rack ids into a querystring
  // @param  rack_ids  an array of rack ids
  // @return querystring as a string
  rackIdsAsParams(rack_ids) {
    let params = "";
    for (var rack_id of Array.from(rack_ids)) {
      params += "&rack_ids[]=" + rack_id;
    }

    return params;
  }

  // load rack definitions, grabs everything unless an array of rack ids is supplied
  // @param  rack_ids  option array of rack ids to fetch
  getRackDefs(rack_ids) {
    const query_str = (rack_ids != null) ? rack_ids : '';

    return new Request.JSON({url: this.resources.path + this.resources.rackDefinitions + '?' + (new Date()).getTime() + query_str, onComplete: this.receivedRackDefs, onTimeout: this.retryRackDefs}).get();
  }


  // triggered when the server responds with rack definitions. This can be during the initialise process or as a result of changes to
  // the data centre. Actions the data accordingly
  // @param  rack_defs the rack definitions as returned by the server
  receivedRackDefs(rack_defs) {
    const defs = this.parser.parseRackDefs(rack_defs);

    return this.initialiseRackDefs(defs);
  }

  initialiseRackDefs(defs) {
    let rackAsset;
    ++this.resourceCount;

    const allAssets = [];
    for (rackAsset of Array.from(defs.assetList)) { allAssets.push(rackAsset); }
    if (this.model.assetList() != null) {
      for (rackAsset of Array.from(this.model.assetList())) { allAssets.push(rackAsset); }
    }
    this.model.assetList(allAssets);
    this.synchroniseChanges(defs.assetList);

    this.model.racks(defs.racks);
    this.model.deviceLookup(defs.deviceLookup);

    return this.testLoadProgress();
  }


  // generates rack image load queue to grab any new images required as a result of recent changes to the data centre
  synchroniseChanges(newAssets) {
    let assets;
    if (newAssets != null) {
      assets = newAssets;
    } else {
      assets = this.model.assetList();
      this.assetCount = 0;
    }
    return Array.from(assets).map((asset) => // deal with loading the images
      AssetManager.get(CanvasController.PRIMARY_IMAGE_PATH + asset, this.evAssetLoaded, this.evAssetFailed));
  }

  // asset manager callback invoked when an image finishes loading. Tests if all assets have been loaded successfully
  evAssetLoaded() {
    //XXX we now perform a test to see if all the assets we request are loaded, and that we are initialized (this is not page load)
    //    then we kick of the final part of the synchronisation process

    ++this.assetCount;
    return this.testLoadProgress();
  }

  setResources() {
    this.resourceCount = 0;
    return this.resources     = CanvasController.LIVE ? CanvasController.LIVE_RESOURCES : CanvasController.OFFLINE_RESOURCES;
  }


  // called whenever a resource finishes loading during initialisation process or when new racks definitions are received following
  // modifications to the data centre. Updates loading dialogue and triggers synchronisation or next step of initialisation as necessary
  testLoadProgress() {
    let progress;
    const assets = this.model.assetList();

    if ((assets != null) && (assets.length >= 0)) {
      const num_assets = assets.length;
      progress   = this.calculateProgress(num_assets);
      //console.log "testLoadProgress::::",@resourceCount,CanvasController.NUM_RESOURCES,"---",@assetCount,num_assets,"=========",progress
      if ((this.resourceCount === CanvasController.NUM_RESOURCES) && (this.assetCount === num_assets)) {
        this.assetCount = 0;
        this.init();
      }
    } else {
      progress = 0;
    }

    return $('dialogue').innerHTML = CanvasController.RESOURCE_LOAD_CAPTION.replace(/\[\[progress\]\]/g, progress + '%');
  }

  calculateProgress(num_assets) {
    let assets_factor;
    const rest_factor   = this.resourceCount / CanvasController.NUM_RESOURCES;
    if (num_assets > 0) {
      assets_factor = this.assetCount / num_assets;
    } else {
      assets_factor = 1;
    }

    const assets_represents = 1 / (CanvasController.NUM_RESOURCES + 1);
    const rest_represents = 1 - assets_represents;

    return ( ( (rest_factor * rest_represents) + ( assets_factor * assets_represents ) ) * 100).toFixed(1);
  }


  // asset manager callback invoked when an image fails to load from the primary image location. Attempts to load the same image
  // from the secondary image location
  // @param  path  the attempted path to the image which failed
  evAssetFailed(path) {
    const image = path.substr(CanvasController.PRIMARY_IMAGE_PATH.length);
    Profiler.trace(Profiler.INFO, 'Failed to load ' + image + ', trying secondary location');
    return AssetManager.get(CanvasController.SECONDARY_IMAGE_PATH + path.substr(CanvasController.PRIMARY_IMAGE_PATH.length), this.evAssetLoaded, this.evAssetDoubleFailed);
  }


  // asset manager callback, image has failed to load from both the primary and secondary locations, it doesn't exist so scrap it
  // out of the queue
  // @param  path  the attempted path to the image which failed
  evAssetDoubleFailed(path) {
    const image  = path.substr(CanvasController.SECONDARY_IMAGE_PATH.length);
    const assets = this.model.assetList();
    const idx    = assets.indexOf(image);
    if (idx !== -1) { assets.splice(idx, 1); }
    return Profiler.trace(Profiler.CRITICAL, '** Failed to load ' + image + ' from primary and secondary locations **');
  }

  init() {
    // Hide loader
    Util.setStyle($('loader'), 'visibility', 'hidden');

    // Store global reference to controller CC = CanvasController
    document.CC = this;

    this.rackEl          = $('rack_container');
    // Rack Space
    this.rackSpace = new CanvasSpace(this.rackEl, null, this.model, this.rackParent);
    return this.showFinishedTime();
  }

  showStartedTime() {
    this.time_started = new Date();
    return console.log("===== STARTING CANVAS ===",this.time_started);
  }

  showFinishedTime() {
    const time_finised = new Date();
    return console.log("======== END CANVAS =====",time_finised,"(", time_finised - this.time_started, ") miliseconds");
  }
};

CanvasController.initClass();
export default CanvasController;
