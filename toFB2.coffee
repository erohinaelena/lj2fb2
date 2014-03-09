getTags = (dom) ->
  bigText = []
  tagStack = []

  get = (dom) ->

    dom.forEach (elem) ->
      if elem.data && elem.data.indexOf("ljparseerror") == -1

        if elem.type == "text"
          if elem.data.indexOf("&lt;") > -1
            console.log elem.data
          elem.data = elem.data.replace /&(?!#)/g, "&#38;"
          bigText.push JSON.parse JSON.stringify [elem.data, tagStack]
          tagStack.push "text"
        else
          if elem.type == "tag" && elem.name != "br"
            if elem.name == "a"
              if elem.attribs
                href = elem.attribs.href
                if href
                  href = href.replace /&/g, "&#38;"
                  if href.indexOf("http") is -1
                    tagStack.push "a l:href=\"\""
                  else
                    tagStack.push "a l:href=\"" + href + "\"" if href.indexOf("http") is href.lastIndexOf("http")
              else
                tagStack.push "a l:href=\"\""
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
        tagStack.pop()
    return bigText

  get dom

picturePath = []

tags = [
  {html: "i", xml: "emphasis"},
  {html: "em", xml: "emphasis"},
  {html: "b", xml: "strong"},
  {html: "strike", xml: "strikethrough"},
  {html: "br/", xml: "/p>\n<p"}
]

toXML = (bigText)->
  bigText = bigText.map (text) ->
    openTags = ""
    closeTags = ""
    tag = text[1]
    tag.forEach (oneTag) ->
      openTags += "<" + oneTag + ">"
      if oneTag.indexOf("href") == -1
        closeTags = "</" + oneTag + ">" + closeTags
      else
        closeTags = "</a>" + closeTags
    text = openTags + text[0] + closeTags
    if text.indexOf("img") == 1
      path = /src="http[s]?:\/\/\/?([^"]+)"/g.exec text
      text = "<image l:href=\"#" + path[1] + "\"/>"
      picturePath.push path[1]
    text
  bigText = bigText.join ""
  tags.forEach (tag) ->
    bigText = bigText.replace new RegExp("<" + tag.html + ">", "g"), "<" + tag.xml + ">"
    bigText = bigText.replace new RegExp("</" + tag.html + ">", "g"), "</" + tag.xml + ">"
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

someFunctions = require './someFunctions.coffee'
httpGetPicture = someFunctions.httpGetPicture
extractAllMatches = someFunctions.extractAllMatches

_     = require 'lodash'

getCurrentTags = (post)->
  currentTags = []
  post.tags.forEach (tag) ->
    j = 0
    existTag = false
    allTags.forEach (addedTag) ->
      if tag == addedTag.name
        addedTag.id.push [post.id[0], post.title]
        existTag = true
    allTags.push name: tag, id: [
      [post.id[0], post.title]
    ] if !existTag
    currentTags.push "<a l:href=\"#" + tag + "\">" + tag + "</a>"
  currentTags = currentTags.join ", "
  currentTags = "Метки: " + currentTags if currentTags
  currentTags

getPicture = (path, callback)->
  path = /(.+)(\.[\w]+)(\/.+)/g.exec path
  host = path[1] + path[2]
  path = path[3]
  httpGetPicture host, path, callback

fs = require 'fs'
async = require 'async'

firstChangeSigns = [
  {html: "&lt;", xml: "<"},
  {html: "&gt;", xml: ">"},
  {html: "&quot;", xml: "\""},
  {html: "&apos;", xml: "\'"},
  {html: "&amp;", xml: "&"}
]

signs = fs.readFileSync "signs.json", {encoding: "utf8"}
signs = JSON.parse signs

monthNames = ["январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь","декабрь"]

postCount = 0
prevYear = 0
prevMonth = 0
book = []
allTags = []

module.exports = (posts, user) ->
  posts.forEach (post) ->
    post.text = "" if !post.text
    firstChangeSigns.forEach (sign)->
      post.text = post.text.replace new RegExp(sign.html, "g"), sign.xml

    entities = extractAllMatches post.text, /&([\w]+;)/g
    entities.forEach (entity) ->
      post.text = post.text.replace entity, "#" + signs[entity].charCodeAt(0) + ";"

    dom = parseHTML post

    bigText = getTags dom

    bigText = toXML bigText

    post.title = post.title.replace /\"/g, "&#34;"

    currentTags = getCurrentTags post

    if post.date
      date = post.date
    else
      date = post.id[1].replace /\//g, " "

    forDate = post.id[1].split "/"
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
    book.push sectionYear + sectionMonth + "<section><title id=\"" + post.id[0] + "\"><p>" + post.title + "</p></title><subtitle><p>" + date + "</p></subtitle><empty-line/><empty-line/><p>" + bigText + "</p><empty-line/><p>" + currentTags + "</p></section>\n"

  sectionTags = []
  allTags.forEach (tag) ->
    sectionTags.push "<section><title id=\"" + tag.name + "\"><p>" + tag.name + "</p></title><empty-line/><empty-line/>\n"
    tag.id.forEach (id) ->
      sectionTags.push "<p><a l:href=\"#" + id[0] + "\">" + id[1] + " </a></p>\n"
    sectionTags.push "</section>\n"
  sectionTags = sectionTags.join ""

  picturePath = _.uniq picturePath

  fileName = user + ".fb2"
  book = book.join ""
  writeNextPictureOrCloseFile = ->
    if picturePath.length > 0
      getPicture picturePath.shift(), (err, binary) ->
        throw err if err
        fs.appendFile fileName, binary, writeNextPictureOrCloseFile
        console.log "picturePath.length is ",picturePath.length
    else
      console.log "its all"
      fs.appendFile fileName, "\n</FictionBook>"

  fs.writeFile fileName, "<?xml version='1.0' encoding='utf-8'?>\n<FictionBook xmlns='http://www.gribuser.ru/xml/fictionbook/2.0' xmlns:l='http://www.w3.org/1999/xlink'>\n<body>", ->
    fs.appendFile fileName, book + "</section></section>" + sectionTags + "</body>\n", writeNextPictureOrCloseFile
