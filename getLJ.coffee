extractAllMatches = (data, expr) ->
  link = expr.exec data
  arr = []
  while link?
    arr.push link[1]
    link = expr.exec data
  return arr

textFromData = (isFirst,data,host) ->
  exprLink = /dbogdanov\.livejournal\.com(\/[\d]+\.html)">Previous Entry/g
  exprText = /<div class="asset-body"><div class="user-icon"><img src=.*<\/div>(.*)<\/div>/g
  exprTag = /<a rel="tag" href="http:\/\/dbogdanov\.livejournal\.com\/tag\/[\w%]+">([а-яА-Я\w\s]+)<\/a>/g
  exprTitle = /class="subj-link" >(.*)<\/a><\/h2>/g
  exprDate = /class="datetime">([\d]+ [а-я]+, [\d]{4} at [\d]+:[\d]+ [AP]M)<\/abbr>/g
  if isFirst
    exprLink = /<h2 class="asset-name page-header2"><a href="http:\/\/dbogdanov\.livejournal\.com(\/[\d]+\.html)"/g
  path = exprLink.exec data
  console.log path[1] if path
  if !isFirst
    text = exprText.exec data
    tags = extractAllMatches data, exprTag
    title = exprTitle.exec data
    date = exprDate.exec data
    #console.log date[1] if date
    #console.log tags
    console.log JSON.stringify title: title[1],tags: tags,date: date[1],text: text[1]
    fs.appendFile "dbogdanov.txt", JSON.stringify title: title[1],tags: tags,date: date[1],text: text[1]
    fs.appendFile "dbogdanov.txt", "\n%%%\n"
  if path
    httpGet host, path[1],0
    n++
  else
    console.log "всё"
    console.log n

n=0
httpGet = (host,path, isFirst) ->
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
      textFromData isFirst, data, host

  ).on("error", (e) ->
    console.log "problem with request: " + e.message + " on "+path
  ).end()

http = require 'http'
fs = require 'fs'

debug = true
httpGet.counter = 0

httpGet "dbogdanov.livejournal.com", "",1

