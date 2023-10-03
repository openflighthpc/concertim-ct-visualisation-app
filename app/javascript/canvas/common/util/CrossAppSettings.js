// When transitioning from the IRV to the DCPV we may wish to maintain some
// settings such as the current metric selected.
// This class provides a wrapper around localStorage to facilitate that.
//
// XXX Currently the settings are returned as a JSON blob making it hard to
// know what settings can be set for each app.  An improvement would be to have
// some kind of `IRVSettings` class holding details of what settings are
// permissible.  This class is what would be serialized/deserialized. class
class CrossAppSettings {

  // Set the settings for the next app. E.g.,
  //
  //   CrossAppSettings.set('dcpv', {selectedRacks: {1: true, 3: true}});
  static set(namespace, settings_obj) {
    const settings = JSON.stringify(settings_obj);
    window.localStorage.setItem(namespace, settings);
  }

  // Return a JSON blob of the settings for the given app.
  //
  //   CrossAppSettings.get('dcpv'); #=> {selectedRacks: {1: true, 3: true}})
  static get(namespace) {
    const val = JSON.parse(window.localStorage.getItem(namespace));
    if (val != null) {
      return val;
    } else {
      return {};
    }
  }

  // Clear any settings for the given app.
  //
  //   CrossAppSettings.clear('dcpv');
  static clear(namespace) {
    window.localStorage.clear(namespace);
  }
};

export default CrossAppSettings;
