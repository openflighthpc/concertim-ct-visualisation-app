// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"
import * as ActionCable from '@rails/actioncable'

ActionCable.logger.enabled = true;

// ActionCable.Connection.prototype.events.message = function(event) {
//     if (!this.isProtocolSupported()) { return }
//     const {identifier, message, reason, reconnect, type} = JSON.parse(event.data)
//     switch (type) {
//         case message_types.welcome:
//             this.monitor.recordConnect()
//             return this.subscriptions.reload()
//         case message_types.disconnect:
//             return this.close({allowReconnect: reconnect, reason: reason})
//         case message_types.ping:
//             return this.monitor.recordPing()
//         case message_types.confirmation:
//             this.subscriptions.confirmSubscription(identifier)
//             return this.subscriptions.notify(identifier, "connected")
//         case message_types.rejection:
//             return this.subscriptions.reject(identifier)
//         default:
//             return this.subscriptions.notify(identifier, "received", message)
//     }
// };

// ActionCable.Connection.prototype.close = function({allowReconnect} = {allowReconnect: true}) {
//     return
// }
//
// ActionCable.Connection.prototype.events.close = function(event) {
//     console.log(event);
//     console.log(event.reason)
//     console.log(this.webSocket);
//     if (this.disconnected) { return; }
//     this.disconnected = true;
//     this.monitor.recordDisconnect();
//     return this.subscriptions.notifyAll("disconnected", {willAttemptReconnect: this.monitor.isRunning()});
// };


export default createConsumer()
