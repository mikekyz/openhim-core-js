Keystore = require('../model/keystore').Keystore
Certificate = require('../model/keystore').Certificate
Q = require 'q'
logger = require 'winston'
authorisation = require './authorisation'
pem = require 'pem'

utils = require "../utils"

exports.getServerCert = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to getServerCert denied.", 'info'
    return

  try
    keystoreDoc = yield Keystore.findOne().select('cert').exec()
    this.body = keystoreDoc.cert
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not fetch the server cert via the API: #{err}", 'error'

exports.getCACerts = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to getCACerts denied.", 'info'
    return

  try
    keystoreDoc = yield Keystore.findOne().select('ca').exec()
    this.body = keystoreDoc.ca
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not fetch the ca certs trusted by this server via the API: #{err}", 'error'

exports.getCACert = (certId) ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to getCACert by id denied.", 'info'
    return

  try
    keystoreDoc = yield Keystore.findOne().select('ca').exec()
    cert = keystoreDoc.ca.id(certId)

    this.body = cert
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not fetch ca cert by id via the API: #{err}", 'error'


exports.setServerCert = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to setServerCert by id denied.", 'info'
    return

  try
    cert = this.request.body.cert
    readCertificateInfo = Q.denodeify pem.readCertificateInfo
    try
      certInfo = yield readCertificateInfo cert
    catch err
      return utils.logAndSetResponse this, 'bad request', "Could not add server cert via the API: #{err}", 'error'
    certInfo.data = cert

    keystoreDoc = yield Keystore.findOne().exec()
    keystoreDoc.cert = certInfo
    yield Q.ninvoke keystoreDoc, 'save'
    this.status = 'created'
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not add server cert via the API: #{err}", 'error'

exports.setServerKey = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to getServerKey by id denied.", 'info'
    return

  try
    key = this.request.body.key
    keystoreDoc = yield Keystore.findOne().exec()
    keystoreDoc.key = key
    yield Q.ninvoke keystoreDoc, 'save'
    this.status = 'created'
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not add server key via the API: #{err}", 'error'


exports.addTrustedCert = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to addTrustedCert by id denied.", 'info'
    return

  try
    invalidCert = false
    chain = this.request.body.cert

    # Parse into an array in case this is a cert chain
    # (code derived from: http://www.benjiegillam.com/2012/06/node-dot-js-ssl-certificate-chain/)
    certs = []
    chain = chain.split "\n"
    cert = []
    for line in chain when line.length isnt 0
      cert.push line
      if line.match /-END CERTIFICATE-/
        certs.push ((cert.join "\n") + "\n")
        cert = []

    keystoreDoc = yield Keystore.findOne().exec()
    readCertificateInfo = Q.denodeify pem.readCertificateInfo

    if certs.length < 1
      invalidCert = true

    for cert in certs
      try
        certInfo = yield readCertificateInfo cert
      catch err
        invalidCert = true
        continue
      certInfo.data = cert
      keystoreDoc.ca.push certInfo

    yield Q.ninvoke keystoreDoc, 'save'

    if invalidCert
      utils.logAndSetResponse this, 'bad request', "Failed to add one more cert, are they valid? #{err}", 'error'
    else
      this.status = 'created'
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not add trusted cert via the API: #{err}", 'error'

exports.removeCACert = (certId) ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to removeCACert by id denied.", 'info'
    return

  try
    keystoreDoc = yield Keystore.findOne().exec()
    keystoreDoc.ca.id(certId).remove()
    yield Q.ninvoke keystoreDoc, 'save'
    this.status = 'ok'
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not remove ca cert by id via the API: #{err}", 'error'

exports.verifyServerKeys = ->
  # Must be admin
  if authorisation.inGroup('admin', this.authenticated) is false
    utils.logAndSetResponse this, 'forbidden', "User #{this.authenticated.email} is not an admin, API access to verifyServerKeys.", 'info'
    return

  try
    try
      result = yield Q.nfcall getCertKeyStatus
    catch err
      return utils.logAndSetResponse this, 'bad request', "Could not verify certificate and key, are they valid? #{err}", 'error'

    this.body =
      valid: result
    this.status = 'ok'
    
  catch err
    utils.logAndSetResponse this, 'internal server error', "Could not determine validity via the API: #{err}", 'error'



exports.getCertKeyStatus = getCertKeyStatus = (callback) ->

  Keystore.findOne (err, keystoreDoc) ->
    return callback err, null if err

    pem.getModulus keystoreDoc.key, (err, keyModulus) ->
      return callback err, null if err
      pem.getModulus keystoreDoc.cert.data, (err, certModulus) ->
        return callback err, null if err

        # if cert/key match and are valid
        if keyModulus.modulus is certModulus.modulus
          return callback null, true
        else
          return callback null, false
