mongoose = require "mongoose"
server = require "../server"
connectionDefault = server.connectionDefault
Schema = mongoose.Schema

TaskSchema = new Schema
  "status": { type: String, required: true, enum: ["Queued", "Processing", "Paused", "Cancelled", "Completed"], default: "Queued", index: true }
  "transactions": [ { tid: { type: String, required: true }, tstatus: { type: String, required: true, enum: ["Queued", "Processing", "Completed", "Failed"], default: "Queued" }, error: { type: String, required: false }, rerunID: { type: String, required: false }, rerunStatus: { type: String, required: false } } ]
  "created": { type: Date, required: true, default: Date.now, index: true }
  "completedDate": { type: Date, required: false }
  "user": { type: String, required: true }
  "remainingTransactions": { type: Number, required: true }
  "batchSize": { type: Number, default: 1 }

###
# The task object that describes a specific task within the OpenHIM.
# It provides some metadata describing a task and contains a number of transaction IDs.
###
exports.Task = connectionDefault.model 'Task', TaskSchema
