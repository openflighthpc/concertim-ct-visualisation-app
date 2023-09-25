import Profiler from 'Profiler';

// Static asset loader utility.
//
// Fetches images and triggers either an onSuccess or onError callback.  The
// number of concurrent asset requests is limited.
//
// AssetManager uses the Singleton pattern by exporting a single instance of
// this class instead of the class itself.  This ensures that there is a single
// queue and a single cache of assets.
class AssetManager {
  // overwritten by config
  NUM_CONCURRENT_LOADS = 4;

  // hard coded and run-time assigned statics
  ASSET_LOAD_IN_PROGRESS = 'pending';
  ASSET_READY_DELAY = 500;

  constructor() {
    this.CACHE = {};
    this.QUEUE = [];
    this.LOAD_COUNT = 0;
    this.CALLBACKS = {};
  }

  delay(asset, path) {
    Profiler.begin(Profiler.DEBUG);
    setTimeout(
      () => { this.assetReceived(asset, path); },
      this.ASSET_READY_DELAY
    );
    Profiler.end(Profiler.DEBUG);
  }

  assetReceived(asset, path) {
    this.debug('received', path);
    Profiler.begin(Profiler.DEBUG);
    if (asset.width > 0) {
      this.CACHE[path] = asset;
      --this.LOAD_COUNT;

      if (this.CALLBACKS[path] != null) {
        for (var callback of Array.from(this.CALLBACKS[path])) {
          if (callback.onSuccess != null) { callback.onSuccess(asset); }
        }
        this.CALLBACKS[path] = null;
      }

      if (this.QUEUE.length > 0) {
        this.getAsset(this.QUEUE[0]);
      }
    } else {
      this.delay(asset, path);
    }
    Profiler.end(Profiler.DEBUG);
  }

  assetFailed(path) {
    this.debug('fetch failed', path);
    --this.LOAD_COUNT;
    if (this.CALLBACKS[path] != null) {
      for (var callback of Array.from(this.CALLBACKS[path])) {
        if (callback.onError != null) { callback.onError(path); }
      }
      this.CALLBACKS[path] = null;
    }
  }

  get(path, on_success, on_error) {
    Profiler.begin(Profiler.DEBUG, path);

    if (this.CACHE[path] === this.ASSET_LOAD_IN_PROGRESS) {
      // if the required asset is already being loaded append the callback to the existing list
      this.debug('fetch in progress', path);
      if ((on_success != null) || (on_error != null)) {
        if (this.CALLBACKS[path] == null) { this.CALLBACKS[path] = []; }
        this.CALLBACKS[path].push({ onSuccess: on_success, onError: on_error });
      }
    } else if (this.CACHE[path] != null) {
      // if the asset has already been loaded then trigger callback immediately
      this.debug('already fetched', path);
      if (on_success != null) { on_success(this.CACHE[path]); }
      Profiler.end(Profiler.DEBUG);
      this.CACHE[path];
    } else {
      // otherwise queue it up and start load if available
      this.debug('queing', path);
      this.QUEUE.push(path);
      this.CACHE[path] = this.ASSET_LOAD_IN_PROGRESS;
      if ((on_success != null) || (on_error != null)) {
        this.CALLBACKS[path] = [];
        this.CALLBACKS[path].push({ onSuccess: on_success, onError: on_error });
      }

      if (this.LOAD_COUNT < this.NUM_CONCURRENT_LOADS) {
        this.getAsset();
      }
    }
    Profiler.end(Profiler.DEBUG);
  }


  getAsset() {
    Profiler.begin(Profiler.DEBUG);
    ++this.LOAD_COUNT;
    const path = this.QUEUE.shift();

    this.debug('fetching', path);
    const img         = new Image();
    img.onload  = () => this.assetReceived(img, path);
    img.onabort = () => this.assetFailed(path);
    img.onerror = () => this.assetFailed(path);
    img.src     = path;
    Profiler.end(Profiler.DEBUG);
  }

  debug(...msg) {
    console.debug('AssetManager:', ...msg);
  }
};

export default new AssetManager();
