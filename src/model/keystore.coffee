mongoose = require "mongoose"
server = require "../server"
connectionDefault = server.connectionDefault
Schema = mongoose.Schema

certificate =
  country:          { type: String }
  state:            { type: String }
  locality:         { type: String }
  organization:     { type: String }
  organizationUnit: { type: String }
  commonName:       { type: String }
  emailAddress:     { type: String }
  validity:
    start:          { type: Date }
    end:            { type: Date }
  data:             { type: String }

CertificateSchema = new Schema certificate

KeystoreSchema = new Schema
  key:    { type: String }
  cert:   certificate
  ca:     [ CertificateSchema ]

# Model for storing the server key and cert as well as trusted certificates
exports.Keystore = connectionDefault.model 'Keystore', KeystoreSchema
exports.Certificate = connectionDefault.model 'Certificate', CertificateSchema
