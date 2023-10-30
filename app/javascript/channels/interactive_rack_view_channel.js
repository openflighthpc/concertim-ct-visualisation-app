import consumer from "./consumer"

consumer.subscriptions.create("InteractiveRackViewChannel", {
  connected() {
    console.log("It begins");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    console.log("we got one!");
    console.log(data);
  }
});
