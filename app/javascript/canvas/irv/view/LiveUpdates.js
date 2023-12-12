import consumer from "channels/consumer";
import * as ActionCable from '@rails/actioncable';

class LiveUpdates {

    constructor(controller) {
        this.controller = controller;
    }

    setupWebsocket() {
        const self = this;
        let statusDot = document.getElementById("websocket-status-dot");
        let statusText = document.getElementById("websocket-connection-text");
        statusDot.style.backgroundColor = "orange";
        statusText.innerText = "connecting";

        ActionCable.Connection.prototype.events.error = function() {
            statusDot.style.backgroundColor = "red";
            statusText.innerText = "error connecting to server";
        };

        consumer.subscriptions.create("InteractiveRackViewChannel", {

            connected() {
                statusDot.style.backgroundColor = "green";
                statusText.innerText = "connected";
                this.perform("all_racks_sync");
            },

            // Either received a disconnect message or the websocket is closed.
            // Frustratingly action cable doesn't make available the disconnect reason here, for either scenario.
            disconnected(data) {
                // e.g. server restart
                if(data.willAttemptReconnect) {
                    statusDot.style.backgroundColor = "orange";
                    statusText.innerText = "attempting to reconnect";
                    if(!self.controller.initialised) {
                        $('dialogue').innerHTML = "Error connecting to live updates server. Retrying.";
                    }
                } else {
                    // e.g. logged out in another tab
                    statusDot.style.backgroundColor = "red";
                    if(!self.controller.initialised) {
                        $('dialogue').innerHTML = "Unable to connect to live updates server";
                        statusText.innerText = "Unable to connect";
                    } else {
                        statusText.innerText = "disconnected";
                    }
                }
            },

            rejected(data) {
                // With our backend logic setup, and because the front end library doesn't try to create a websocket connection
                // until a subscription is specified, action cable doesn't send a rejected message but closes the websocket (handled
                // by the disconnected function). So I'm not sure when/if this would be reached.
                console.log(`Connection rejected: ${data}`);
                statusDot.style.backgroundColor = "red";
                statusText.innerText = "connection request rejected";
                if(!self.controller.initialised) {
                    $('dialogue').innerHTML = "Error connecting to live updates server";
                }
            },

            received(data) {
                let action = data.action;
                if(action === "latest_full_data") {
                    self.controller.fullRackDataReceived(data);
                } else {
                    self.controller.modifiedRackDataReceived(data);
                }
            }
        });
    }

}

export default LiveUpdates;
