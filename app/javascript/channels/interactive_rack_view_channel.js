import consumer from "./consumer"

consumer.subscriptions.create({ channel: "InteractiveRackViewChannel", user_id: 2}, {
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
