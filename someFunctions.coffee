http  = require 'http'
debug = true
mmm   = require('mmmagic')
magic = new mmm.Magic(mmm.MAGIC_MIME_TYPE)

httpGet = (host, path, callback) ->
  data = ""
  if debug
    console.log "getting", path
    httpGet.counter++
  http.get(
    hostname: host,
    port: 80
    path: path
    method: "GET"
    headers: 'user-agent': 'Mozilla/5.0'
  , (response) ->
    response.setEncoding "utf8"
    response.on "data", (chunk) ->
      data += chunk

    response.on "end", ->
      if debug
        httpGet.counter--
        console.log "got", path, "(" + httpGet.counter + " requests left)"
      callback null, data
  ).on("error", (e) ->
    console.log "problem with request, waiting 5s: " + e.message + " on "+path
    setTimeout (-> httpGet host, path, callback), 5000
  ).end()

httpGet.counter = 0

httpGetPicture = (host, path, callback) ->
  buffers = []
  if debug
    console.log "getting", path
    httpGetPicture.counter++
  http.get(
    hostname: host,
    port: 80
    path: path
    method: "GET"
    headers:
      'user-agent': 'Mozilla/5.0'
  ,(response) ->
    response.on "data", (chunk) ->
      buffers.push chunk
    response.on "end", ->
      if debug
        httpGetPicture.counter--
        console.log "got", host, path, "(" + httpGetPicture.counter + " requests left)"
      if response.statusCode == 200
        data = Buffer.concat(buffers).toString('base64')
        magic.detect(Buffer.concat(buffers),(err, result)->
          throw err if err
          console.log result
          type = result
          callback null, "<binary id=\"" + host + path + "\" content-type=\"" + type + "\">" + data + "</binary>\n"
        )
      else
        data = ""
        type = "image/jpg"
        #console.log data
        callback null, "<binary id=\"" + host + path + "\" content-type=\"" + type + "\">" + data + "</binary>\n"
  ).on("error",(e) ->
    console.log "problem with request: " + e.message + " on " + path
    if e.message != "getaddrinfo ENOTFOUND" && e.message != "getaddrinfo EADDRINFO" && e.message != "connect EHOSTUNREACH" &&  e.message != "connect ETIMEDOUT"
      setTimeout (->
        httpGetPicture host, path, callback), 5000
    else
      callback null, null
  ).end()

httpGetPicture.counter = 0

extractAllMatches = (data, expr) ->
  link = expr.exec data
  arr = []
  while link?
    arr.push link[1]
    link = expr.exec data
  return arr

module.exports =
  httpGet:httpGet,
  httpGetPicture:httpGetPicture,
  extractAllMatches:extractAllMatches
