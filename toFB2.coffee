getTags = (dom) ->
  bigText = []
  tagStack = []
  countElemDom = []
  currentElemDom = []
  elemsDom = []

  get = (dom) ->
    elemsDom.push dom
    countElemDom.push dom.length
    currentElemDom.push 0
    while currentElemDom[currentElemDom.length - 1] < countElemDom[countElemDom.length - 1]
      elem = elemsDom[elemsDom.length - 1][currentElemDom[currentElemDom.length - 1]]
      #console.log elem.name if elem.name && elem.name!="p" && elem.name!="ul" && elem.name!="li"&&elem.name!="div" &&elem.name!="span" &&elem.name!="u" &&elem.name!="br" && elem.name!="i" && elem.name!="em" && elem.name!="b"&& elem.name!="strong"&& elem.name!="a"&& elem.name!="img"
      if elem.data && elem.data.indexOf("ljparseerror") == -1

        if elem.type == "text"
          if elem.data.indexOf("&lt;") > -1
            console.log elem.data
          elem.data = elem.data.replace /&(?!#)/g, "&#38;"
          a = JSON.stringify [elem.data, tagStack]
          a = JSON.parse a
          bigText.push a
          tagStack.push "text"
        else
          if elem.type == "tag" && elem.name != "br"
            if elem.name == "a"
              elem.attribs.href = elem.attribs.href.replace /&/g, "&#38;" if elem.attribs.href
              tagStack.push "a l:href=\"" + elem.attribs.href + "\"" if elem.attribs.href && elem.attribs.href.indexOf("http") != -1 && elem.attribs.href.indexOf("http") == elem.attribs.href.lastIndexOf("http")
              tagStack.push "a l:href=\"\"" if elem.attribs.href && elem.attribs.href.indexOf("http") == -1
              tagStack.push "a l:href=\"\"" if !elem.attribs.href
              #console.log elem.attribs.href if elem.attribs.href&&elem.attribs.href.indexOf("http")!=-1
            else
              if elem.name == "img"
                tagStack.push elem.data
                bigText.push ["картинка", [elem.data]]
              else
                if elem.name == "p"
                  bigText.push ["<br/>", []]
                  tagStack.push "p"
                 else
                  tagStack.push elem.name
          else if elem.type == "tag" && elem.name == "br"
            bigText.push ["<br/>", []]
            tagStack.push elem.name

        if elem.children
          tagStack.pop() if tagStack[tagStack.length - 1] == "p"
          get elem.children
        currentElemDom[currentElemDom.length - 1]++
        tagStack.pop()
      else
        currentElemDom[currentElemDom.length - 1] = countElemDom[countElemDom.length - 1]

    elemsDom.pop()
    countElemDom.pop()
    currentElemDom.pop()
    if elemsDom <= []
      return bigText
  get dom

picturePath = []
toXML = (bigText)->
  i = 0
  while i < bigText.length
    j = 0;
    a = "";
    b = ""
    while j < bigText[i][1].length
      a += "<" + bigText[i][1][j] + ">"
      if bigText[i][1][j].indexOf("href") == -1
        b = "</" + bigText[i][1][j] + ">" + b
      else
        b = "</a>" + b
      j++
    bigText[i] = a + bigText[i][0] + b
    if bigText[i].indexOf("img") == 1
      path = /src="http[s]?:\/\/\/?([^"]+)"/g.exec bigText[i]
      bigText[i] = "<image l:href=\"#" + path[1] + "\"/>"
      #console.log path[1]
      picturePath.push path[1]
    i++
  bigText = bigText.join ""
  i = 0
  while i < htmlTag.length
    bigText = bigText.replace new RegExp("<"+htmlTag[i]+">", "g"), "<"+xmlTag[i]+">"
    bigText = bigText.replace new RegExp("</"+htmlTag[i]+">", "g"), "</"+xmlTag[i]+">"
    i++
  bigText = bigText.replace /<h[\d]>/g, "</p><p><subtitle>"
  bigText = bigText.replace /<\/h[\d]>/g, "</subtitle></p><p>"
  bigText = bigText.replace /<\/?span>|<\/?div>/g, ""
  bigText = bigText.replace /<p><\/p>/g, "<empty-line/>"

htmlparser = require "htmlparser"

parseHTML = (post)->
  rawHtml = post.text
  handler = new htmlparser.DefaultHandler (err, dom) ->
    console.log "err" if err
    #if post.id[0] == "56554"
    #  console.log post.id
    #  fs.writeFile "testPost.json", JSON.stringify dom
  parser = new htmlparser.Parser handler
  parser.parseComplete rawHtml
  return handler.dom

http = require 'http'
debug = true

mmm = require('mmmagic')
magic = new mmm.Magic(mmm.MAGIC_MIME_TYPE)

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
        magic.detect(Buffer.concat(buffers),(err,result)->
          throw err if err
          console.log result
          type = result
          callback null, "<binary id=\"" + host + path + "\" content-type=\"" + type + "\">" + data + "</binary>\n"
        )
      else
        #data="/9j/4AAQSkZJRgABAQAAAQABAAD/4QBoRXhpZgAASUkqAAgAAAADABIBAwABAAAAAQAAADEBAgAQAAAAMgAAAGmHBAABAAAAQgAAAAAAAABTaG90d2VsbCAwLjEyLjMAAgACoAkAAQAAANQAAAADoAkAAQAAAHQAAAAAAAAA/+EJ3Wh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8APD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAtRXhpdjIiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSIyMTIiIGV4aWY6UGl4ZWxZRGltZW5zaW9uPSIxMTYiIHRpZmY6SW1hZ2VXaWR0aD0iMSIgdGlmZjpJbWFnZUhlaWdodD0iMTE2Ii8+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPD94cGFja2V0IGVuZD0idyI/Pv/bAEMAAwICAwICAwMDAwQDAwQFCAUFBAQFCgcHBggMCgwMCwoLCw0OEhANDhEO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"
        data = ""
        type = "image/jpg"
        #console.log data
        callback null, "<binary id=\"" + host + path + "\" content-type=\"" + type + "\">" + data + "</binary>\n"
  ).on("error",(e) ->
    console.log "problem with request: " + e.message + " on " + path
    if e.message != "getaddrinfo ENOTFOUND" && e.message != "getaddrinfo EADDRINFO" && e.message != "connect EHOSTUNREACH"
      setTimeout (->
        httpGetPicture host, path, callback), 5000
    else
      callback null, null
  ).end()
httpGetPicture.counter = 0

getCurrentTags = (post)->
  i = 0
  currentTags = []
  while i < post.tags.length
    j = 0
    existTag = false
    while j < allTags.length
      if post.tags[i] == allTags[j].name
        allTags[j].id.push [post.id[0], post.title]
        existTag = true
      j++
    allTags.push name: post.tags[i], id: [
      [post.id[0], post.title]
    ] if !existTag
    currentTags.push "<a l:href=\"#" + post.tags[i] + "\">" + post.tags[i] + "</a>"
    i++
  currentTags = currentTags.join ", "
  currentTags = "Метки: " + currentTags if currentTags
  currentTags

extractAllMatches = (data, expr) ->
  link = expr.exec data
  arr = []
  while link?
    arr.push link[1]
    link = expr.exec data
  return arr

excludeEqual = (arr)->
  i = 0
  newArr = []
  while i < arr.length
    j = 0
    equal = false
    while j < newArr.length
      equal = true if newArr[j] == arr[i]
      j++
    newArr.push arr[i] if !equal
    i++
  newArr

getPicture = (path, callback)->
  path = /(.+)(\.[\w]+)(\/.+)/g.exec path
  host = path[1] + path[2]
  path = path[3]
  httpGetPicture host, path, callback

fs = require 'fs'
async = require 'async'

htmlSign = ["&lt;", "&gt;", "&quot;", "&apos;", "&amp;"]
xmlSign =  ["<",     ">",    "\"",     "\'",     "&"]

signs = fs.readFileSync "signs.json", {encoding: "utf8"}
signs = JSON.parse signs

htmlTag = ["i",  "em",  "b",  "strike",  "br/"]
xmlTag = ["emphasis", "emphasis", "strong","strikethrough", "/p>\n<p"]
monthNames = ["январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь","декабрь"]

postCount = 0
prevYear = 0
prevMonth = 0
book = []
allTags = []
n = 0

module.exports = (posts,user)->
  while postCount < posts.length
    posts[postCount].text = "" if !posts[postCount].text
    i = 0
    while i < htmlSign.length
      posts[postCount].text = posts[postCount].text.replace new RegExp(htmlSign[i], "g"), xmlSign[i]
      i++

    entities = extractAllMatches posts[postCount].text, /&([\w]+;)/g
    i = 0
    while i < entities.length
      posts[postCount].text = posts[postCount].text.replace entities[i], "#" + signs[entities[i]].charCodeAt(0) + ";"
      i++

    dom = parseHTML posts[postCount]

    bigText = getTags dom

    bigText = toXML bigText

    posts[postCount].title = posts[postCount].title.replace /\"/g, "&#34;"

    currentTags = getCurrentTags posts[postCount]

    if posts[postCount].date
      date = posts[postCount].date
    else
      date = posts[postCount].id[1].replace /\//g, " "

    forDate = posts[postCount].id[1].split "/"
    if  prevYear == 0
      sectionYear = "<section><title><p>" + forDate[1] + "</p></title>"
      sectionMonth = "<section><title><p>" + monthNames[forDate[2] - 1] + "</p></title>"
    else
      if forDate[1] != prevYear
        sectionYear = "</section></section>\n<section><title><p>" + forDate[1] + "</p></title>"
        sectionMonth = "<section><title><p>" + monthNames[forDate[2] - 1] + "</p></title>"
      else
        if forDate[2] != prevMonth
          sectionMonth = "</section>\n<section><title><p>" + monthNames[forDate[2] - 1] + "</p></title>"
          sectionYear = ""
        else
          sectionYear = ""
          sectionMonth = ""

    prevYear = forDate[1]
    prevMonth = forDate[2]
    book.push sectionYear + sectionMonth + "<section><title id=\"" + posts[postCount].id[0] + "\"><p>" + posts[postCount].title + "</p></title><subtitle><p>" + date + "</p></subtitle><empty-line/><empty-line/><p>" + bigText + "</p><empty-line/><p>" + currentTags + "</p></section>\n"
    postCount++

  i = 0
  sectionTags = []
  while i < allTags.length
    sectionTags.push "<section><title id=\"" + allTags[i].name + "\"><p>" + allTags[i].name + "</p></title><empty-line/><empty-line/>\n"
    j = 0
    while j < allTags[i].id.length
      sectionTags.push "<p><a l:href=\"#" + allTags[i].id[j][0] + "\">" + allTags[i].id[j][1] + " </a></p>\n"
      j++
    sectionTags.push "</section>\n"
    i++
  sectionTags = sectionTags.join ""

  picturePath = excludeEqual picturePath

  async.waterfall [
    (callback)->async.map picturePath, getPicture, callback
  ],(err,binary)->
    binary = binary.join ""
    console.log "picture end"
    #console.log binary
    book = book.join ""

    fs.writeFile user + ".fb2", "<?xml version='1.0' encoding='utf-8'?>\n<FictionBook xmlns='http://www.gribuser.ru/xml/fictionbook/2.0' xmlns:l='http://www.w3.org/1999/xlink'>\n
    <body>" + book + "</section></section>" + sectionTags + "</body>\n" + binary + "\n</FictionBook>"





