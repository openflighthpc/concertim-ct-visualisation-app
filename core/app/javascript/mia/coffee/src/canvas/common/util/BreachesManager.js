// Managaes whether breaches are highlighed on the IRV or not.
//
// Currently, either all breaching devices and tagged devices are shown or none.
class BreachesManager {

  // @viewModel  The knockoutjs view model.
  // @url        The URL from which to load the breaches.
  // @pollRate   The interval at which the breaches are to be updated.
  constructor(viewModel, url, pollRate) {
    this.model = viewModel;
    this.url = url;
    this.pollRate = pollRate;
    this.model.showBreaches.subscribe(this.toggleShowing.bind(this));
  }

  // Call after construction to complete setup.
  setup() {
    this.toggleShowing(this.model.showBreaches());
  }

  // toggleShowing toggles whether breaches should be highlighted.
  toggleShowing(showBreaches) {
    console.debug('BreachesManager:toggleShowing:', showBreaches);
    if (showBreaches) {
      this.loadBreaches();

      // By default, the metrics and breaches poll at the same rate, we delay
      // setting the interval to have them poll out of phase with each other.
      setTimeout(
        () => {
          this.breachTmr = setInterval(this.loadBreaches.bind(this), this.pollRate);
        },
        this.pollRate / 2
      );
    } else {
      if (this.breachTmr) {
        clearInterval(this.breachTmr);
      }
      this.evReceivedBreaches({});
    }
  }

  // loadBreaches requests a map of breaching device ids from the server.
  loadBreaches() {
    // We check the model state here too to prevent an already in-progress
    // request from updating the breaches.
    if (this.model.showBreaches()) {
      console.debug('BreachesManager:loadBreaches:');
      new Request.JSON({
        url: this.url + '?' + (new Date()).getTime(),
        onSuccess: this.evReceivedBreaches.bind(this),
      }).get();
    }
  }

  // evReceivedBreaches called when the server returns the list of breaching
  // device ids. Stores breaches in the model.
  //
  // @param  breaches breaching device ids returned from server
  evReceivedBreaches(breaches) {
    console.debug('BreachesManager:evReceivedBreaches:', breaches);

    let group;
    const device_lookup    = this.model.deviceLookup();
    const groups           = this.model.groups();
    const breaching        = {};
    for (group of Array.from(groups)) { breaching[group] = {}; }

    for (group in breaches) {
      if (breaching[group] == null) { continue; }
      for (var id of Array.from(breaches[group])) { breaching[group][id] = true; }
    }

    return this.model.breaches(breaching);
  }
}

export default BreachesManager;
