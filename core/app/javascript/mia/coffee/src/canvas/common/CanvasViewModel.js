/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Util from 'canvas/common/util/Util';

class CanvasViewModel {
  static initClass() {

    this.INIT_FACE           = 'front';

    this.FACE_FRONT  = 'front';
    this.FACE_REAR   = 'rear';
    this.FACE_BOTH   = 'both';
    this.FACES  = [this.FACE_FRONT, this.FACE_REAR, this.FACE_BOTH];
  }

  constructor() {
    this.showingFullIrv = ko.observable(false);
    this.showingRacks = ko.observable(false);
    this.showingRackThumbnail = ko.observable(false);

    // object, stores each device JSON object with an additional property 'instances', an array of references to the class instances
    // uses group as top level key; id as second level key
    this.deviceLookup = ko.observable({});

    // array, stores the parsed rack definition JSON
    this.racks = ko.observable([]);

    // id groups, both group and id are required to identify an individual device
    this.groups = ko.observable(['racks', 'chassis', 'devices']);
  
    // do the racks face forward, backwards or show both
    this.face = ko.observable(CanvasViewModel.INIT_FACE);
    this.faces = ko.observable(CanvasViewModel.FACES);

    // list of images to preload
    this.assetList = ko.observable([]);
  }

  faceBoth() {
    return this.face() === CanvasViewModel.FACE_BOTH;
  }
};
CanvasViewModel.initClass();
export default CanvasViewModel;
