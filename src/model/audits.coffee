mongoose = require "mongoose"
server = require "../server"
connectionATNA = server.connectionATNA
Schema = mongoose.Schema

codeTypeSchema =
  "code": { type: String, required: false }
  "displayName": { type: String, required: false }
  "codeSystemName": { type: String, required: false }

syslogSchema =
  "prival": { type: Number, required: false }
  "facilityID": { type: Number, required: false }
  "severityID": { type: Number, required: false }
  "facility": { type: String, required: false }
  "severity": { type: String, required: false }
  "type": { type: String, required: false }
  "time": { type: Date, required: false }
  "host": { type: String, required: false }
  "appName": { type: String, required: false }
  "pid": { type: String, required: false }
  "msgID": { type: String, required: false }

ActiveParticipantSchema = new Schema
  "userID": { type: String, required: false }
  "alternativeUserID": { type: String, required: false }
  "userIsRequestor": { type: String, required: false }
  "networkAccessPointID": { type: String, required: false }
  "networkAccessPointTypeCode": { type: String, required: false }
  "roleIDCode": codeTypeSchema
  

ParticipantObjectIdentificationSchema = new Schema
  "participantObjectID": { type: String, required: false }
  "participantObjectTypeCode": { type: String, required: false }
  "participantObjectTypeCodeRole": { type: String, required: false }
  "participantObjectIDTypeCode": codeTypeSchema
  "participantObjectQuery": { type: String, required: false }
  "participantObjectDetail":
    "type": { type: String, required: false }
    "value": { type: String, required: false }


AuditRecordSchema = new Schema
  "rawMessage":  { type: String, required: false }
  "syslog": syslogSchema
  "eventIdentification":
    "eventDateTime": { type: Date, required: true, default: Date.now }
    "eventOutcomeIndicator": { type: String, required: false }
    "eventActionCode": { type: String, required: false }
    "eventID": codeTypeSchema
    "eventTypeCode": codeTypeSchema
  "activeParticipant": [ ActiveParticipantSchema ]
  "auditSourceIdentification":
    "auditSourceID": { type: String, required: false }
    "auditEnterpriseSiteID": { type: String, required: false }
    "auditSourceTypeCode": codeTypeSchema
  "participantObjectIdentification": [ ParticipantObjectIdentificationSchema ]

exports.Audit = connectionATNA.model 'Audit', AuditRecordSchema
