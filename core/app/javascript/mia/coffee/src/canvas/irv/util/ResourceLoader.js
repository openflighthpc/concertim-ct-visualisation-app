// Resource loader utility. Fetches resources, such as rack definitions,
// managing retries on failure.
//
// The various resources have been broken out into their own classes simply to
// namespoce their functions.  Perhaps doing so will expose a common pattern.
class ResourceLoader {
  // Map of resource names to URLs.  Set once the configuration is loaded.
  static RESOURCES;

  // Delay (in ms) before retrying a failed resource.  Set once the configuration is loaded.
  static RETRY_DELAY;

  static setup(resources, retryDelay) {
    this.RESOURCES = resources;
    this.RETRY_DELAY = retryDelay;
  }

  static urlFor(resource) {
    if (this.RESOURCES[resource] == null) {
      console.warn('ResourceLoader: unrecognised resource:', resource);
    }
    return this.RESOURCES.path + this.RESOURCES[resource] + '?' + (new Date()).getTime();
  }

  constructor(irvController) {
    // The IRVController instance.  It would be a good idea to remove the
    // coupling to this class.  Having these methods in a separate class is a
    // good first step towards that.
    this.irvController = irvController;
    this.metricLoader = new MetricLoader(irvController);
  }

  getNonrackDeviceData() {
    const loader = new NonRackDeviceLoader(this.irvController);
    loader.getNonrackDeviceData();
  }

  getRackData() {
    const loader = new RackLoader(this.irvController);
    loader.getRackData();
  }

  getMetricTemplates() {
    this.metricLoader.getMetricTemplates();
  }

  getThresholds() {
    const loader = new ThresholdLoader(this.irvController);
    loader.getThresholds();
  }
}

class BaseLoader {
  constructor(irvController) {
    // The IRVController instance.  It would be a good idea to remove the
    // coupling to this class.  Having these methods in a separate class is a
    // good first step towards that.
    this.irvController = irvController;
  }


  testLoadProgress() {
    this.irvController.testLoadProgress();
  }

  // Return the KnockoutJs view model.
  get model() {
    return this.irvController.model;
  }

  get crossAppSettings() {
    return this.irvController.crossAppSettings;
  }

  debug(...msg) {
    console.debug(`${this.constructor.name}:`, ...msg);
  }
}

class RackLoader extends BaseLoader {
  // makes server requests required for initialisation
  getRackData() {
    this.debug('getting rack data');
    // XXX This uses the implementation in CanvasController which should
    // probably be ported here.
    //
    // XXX
    // * Move getRackData and/or getRackDefs in here.
    // * List of rack ids continues to be provided from outside.
    // * Move initialiseRackDefs here too.
    this.irvController.getRackData();
    this.testLoadProgress();
    this.getSystemDateTime();
  }

  // sends a request to the server for the current time
  getSystemDateTime() {
    return new Request({
      url: ResourceLoader.RESOURCES.systemDateTime + '?' + (new Date()).getTime(),
      onComplete: this.setModifiedRacksTimestamp.bind(this),
      onTimeout: this.retrySystemDateTime.bind(this),
    }).get();
  }

  setModifiedRacksTimestamp(timestamp) {
    this.irvController.setModifiedRacksTimestamp(timestamp);
  }

  // called should the system time response fail, re-submits the request. !! possibly untested, possibly redundant
  retrySystemDateTime() {
    this.debug('Failed to load system date time, retrying in ' + ResourceLoader.RETRY_DELAY + 'ms');
    setTimeout(this.getSystemDateTime.bind(this), ResourceLoader.RETRY_DELAY);
  }
}

class MetricLoader extends BaseLoader {
  // requests metric definitions from the server
  getMetricTemplates() {
    new Request.JSON({
      url: ResourceLoader.urlFor('metricTemplates'),
      onComplete: this.receivedMetricTemplates.bind(this),
      onTimeout: this.retryMetricTemplates.bind(this),
    }).get();
  }

  // invoked when the server returns the metric definitions, parses and stores them in the model
  // @param  metricTemplates  the metric definitions as returned by the server
  receivedMetricTemplates(metricTemplates) {
    this.debug("received metric templates");
    // XXX Do we need this?
    // this.metrics = $('metrics');
    const templates = this.parser.parseMetricTemplates(metricTemplates);
    this.model.metricTemplates(templates);

    let metricsAvailable = false;
    for (var i in templates) {
      metricsAvailable = true;
      break;
    }

    ++this.irvController.resourceCount;
    this.testLoadProgress();
  }

  // called should the metric definition response fail, re-submits the request. !! possibly untested, possibly redundant
  retryMetricTemplates() {
    this.debug('Failed to load metric templates, retrying in ' + ResourceLoader.RETRY_DELAY + 'ms');
    return setTimeout(this.getMetricTemplates.bind(this), ResourceLoader.RETRY_DELAY);
  }

  get parser() {
    return this.irvController.parser;
  }
}

class ThresholdLoader extends BaseLoader {
  // requests thresholds definitions from the server
  getThresholds() {
    if ($('threshold_select') != null) {
      this.debug("getting thresholds");
      new Request.JSON({
        url: ResourceLoader.urlFor('thresholds'),
        onComplete: this.receivedThresholds.bind(this),
        // XXX This isn't right.  I guess it should be retryThresholds.
        // onTimeout: this.retryMetricTemplates.bind(this),
      }).get();
    } else {
      this.debug("skip getting thresholds");
      ++this.irvController.resourceCount; // Otherwise the page will not proceed to load :/
    }
  }

  // called when threshold definitions are returned from the server, parses them and stores in the model. Load progress is also tested
  // here as this forms part of the initialisation data
  // @param  thresholds  object representing the threshold definitions
  receivedThresholds(thresholds) {
    this.debug("received thresholds");
    const parsed = this.parser.parseThresholds(thresholds);
    this.model.thresholdsByMetric(parsed.byMetric);
    this.model.thresholdsById(parsed.byId);
    ++this.irvController.resourceCount;
    this.testLoadProgress();
  }

  get parser() {
    return this.irvController.parser;
  }
}

class NonRackDeviceLoader extends BaseLoader {
  getNonrackDeviceData() {
    // XXX Add this here?  Can we make it more generic?
    // CanvasController.NUM_RESOURCES += 1;
    this.debug('getting non rack device data');
    this.getNonrackDeviceDefs();
  }

  getNonrackDeviceDefs(holdingAreaIds, nonRackIds) {
    let queryHolding = '';
    if (holdingAreaIds != null) { 
      if (holdingAreaIds.length > 0) {
        queryHolding = this.idsAsParams(holdingAreaIds,'rackable_non_rack_ids');
      } else {
        queryHolding = '&rackable_non_rack_ids[]=';
      }
    }
    let queryStr = '';
    if (nonRackIds != null) {
      if (nonRackIds.length > 0) {
        queryStr = this.idsAsParams(nonRackIds,'nonRackIds');
      } else {
        queryStr = '&nonRackIds[]=';
      }
    }

    new Request.JSON({
      url: ResourceLoader.urlFor('nonrackDeviceDefinitions') + queryHolding + queryStr,
      onComplete: this.recievedNonrackDeviceDefs.bind(this),
      onTimeout: this.retryNonrackDeviceDefs.bind(this),
    }).get();
  }

  recievedNonrackDeviceDefs(definitions) {
    this.debug("received non rack device defs");
    if (this.irvController.initialised) {
      // XXX Perhaps this should be in here.
      ++this.irvController.resourceCount;
      this.model.assetList(definitions.assetList);
      this.model.modifiedDcrvShowableNonRackChassis(definitions.dcrvShowableNonRackChassis);
      if (this.model.assetList().length === 0) {
        this.testLoadProgress();
      } else {
        this.irvController.synchroniseChanges();
      }
    } else {
      this.initialiseNonRackDeviceDefs(definitions);
    }
  }

  initialiseNonRackDeviceDefs(defs) {
    // XXX In here?
    ++this.irvController.resourceCount;

    const allAssets = [];
    for (var asset of Array.from(defs.assetList)) { allAssets.push(asset); }
    if (this.model.assetList() != null) {
      for (var previousAsset of Array.from(this.model.assetList())) { allAssets.push(previousAsset); }
    }
    this.model.assetList(allAssets);
    this.irvController.synchroniseChanges(defs.assetList);

    this.model.nonrackDevices(defs.rackableNonRackChassis);

    let nonRackChassisToShow = defs.dcrvShowableNonRackChassis;
    if (this.crossAppSettings.selectedNonRackChassis != null) {
      nonRackChassisToShow = [];
      for (var oneN in this.crossAppSettings.selectedNonRackChassis) {
        for (var oneD of Array.from(defs.dcrvShowableNonRackChassis)) {
          if (oneD.id === parseInt(oneN)) {
            nonRackChassisToShow.push(oneD);
          }
        }
      }
    }

    this.model.dcrvShowableNonRackChassis(nonRackChassisToShow);
    this.testLoadProgress();
    this.irvController.recievedRacksAndChassis('chassis');
  }

  retryNonrackDeviceDefs() {
    this.debug('Failed to load nonrack device definitions, retrying in ' + ResourceLoader.RETRY_DELAY + 'ms');
    return setTimeout(this.getNonrackDeviceDefs.bind(this), ResourceLoader.RETRY_DELAY);
  }

  idsAsParams(ids, paramName) {
    let params = "";
    for (var id of Array.from(ids)) {
      params += "&"+paramName+"[]=" + id;
    }
    return params;
  }
}

export default ResourceLoader;
