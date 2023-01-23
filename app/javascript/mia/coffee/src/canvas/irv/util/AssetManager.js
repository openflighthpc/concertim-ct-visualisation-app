/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

// import Profiler from '../Profiler';

// static asset loader utility, grabs images and triggers a callback
class AssetManager {
  static initClass() {

    // overwritten by config
    this.NUM_CONCURRENT_LOADS = 4;

    // hard coded and run-time assigned statics
    this.ASSET_LOAD_IN_PROGRESS = 'pending';
    this.CACHE = {};
    this.QUEUE = [];
    this.LOAD_COUNT = 0;
    this.CALLBACKS = {};
    this.ASSET_READY_DELAY = 500;


    this.delay = (asset, path) => {
      Profiler.begin(Profiler.DEBUG);
      setTimeout(() => {
        return this.assetReceived(asset, path);
      }
      , AssetManager.ASSET_READY_DELAY);
      return Profiler.end(Profiler.DEBUG);
    };


    this.assetReceived = (asset, path) => {
      Profiler.begin(Profiler.DEBUG);
      if (asset.width > 0) {
        AssetManager.CACHE[path] = asset;
        --AssetManager.LOAD_COUNT;

        if (AssetManager.CALLBACKS[path] != null) {
          for (var callback of Array.from(AssetManager.CALLBACKS[path])) {
            if (callback.onSuccess != null) { callback.onSuccess(asset); }
          }
          AssetManager.CALLBACKS[path] = null;
        }

        if (AssetManager.QUEUE.length > 0) {
          AssetManager.getAsset(AssetManager.QUEUE[0]);
        }
      } else {
        this.delay(asset, path);
      }
      return Profiler.end(Profiler.DEBUG);
    };


    this.assetFailed = path => {
      --AssetManager.LOAD_COUNT;
      if (AssetManager.CALLBACKS[path] != null) {
        for (var callback of Array.from(AssetManager.CALLBACKS[path])) {
          if (callback.onError != null) { callback.onError(path); }
        }
        return AssetManager.CALLBACKS[path] = null;
      }
    };
  }

  static setup() {
    this.CACHE = {};
    this.QUEUE = [];
    this.LOAD_COUNT = 0;
    return this.CALLBACKS = {};
  }
  

  static get(path, on_success, on_error) {
    Profiler.begin(Profiler.DEBUG, path);

    if (AssetManager.CACHE[path] === AssetManager.ASSET_LOAD_IN_PROGRESS) {
      // if the required asset is already being loaded append the callback to the existing list
      if ((on_success != null) || (on_error != null)) {
        if (AssetManager.CALLBACKS[path] == null) { AssetManager.CALLBACKS[path] = []; }
        AssetManager.CALLBACKS[path].push({ onSuccess: on_success, onError: on_error });
      }
    } else if (AssetManager.CACHE[path] != null) {
      // if the asset has already been loaded then trigger callback immediately
      if (on_success != null) { on_success(AssetManager.CACHE[path]); }
      Profiler.end(Profiler.DEBUG);
      return AssetManager.CACHE[path];
    } else {
      // otherwise queue it up and start load if available
      AssetManager.QUEUE.push(path);
      AssetManager.CACHE[path] = AssetManager.ASSET_LOAD_IN_PROGRESS;
      if ((on_success != null) || (on_error != null)) {
        AssetManager.CALLBACKS[path] = [];
        AssetManager.CALLBACKS[path].push({ onSuccess: on_success, onError: on_error });
      }

      if (AssetManager.LOAD_COUNT < AssetManager.NUM_CONCURRENT_LOADS) {
        AssetManager.getAsset();
      }
    }
    return Profiler.end(Profiler.DEBUG);
  }


  static getAsset() {
    Profiler.begin(Profiler.DEBUG);
    ++AssetManager.LOAD_COUNT;
    const path = AssetManager.QUEUE.shift();

    const img         = new Image();
    img.onload  = () => AssetManager.assetReceived(img, path);
    img.onabort = () => AssetManager.assetFailed(path);
    img.onerror = () => AssetManager.assetFailed(path);
    img.src     = path;
    return Profiler.end(Profiler.DEBUG);
  }
};
AssetManager.initClass();
export default AssetManager;
