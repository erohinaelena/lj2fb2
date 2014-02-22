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


extractAllMatches = (data, expr) ->
  link = expr.exec data
  arr = []
  while link?
    arr.push link[1]
    link = expr.exec data
  return arr

http = require 'http'
fs = require 'fs'

debug = true
httpGet.counter = 0

async = require 'async'

user = process.argv[process.argv.length-1]


getDays = (year,callback) ->
  async.waterfall [
    (callback) ->
      httpGet user + ".livejournal.com", "/"+year+"/", callback
    (data,callback) ->
      exprDay = new RegExp user + "\\.livejournal\\.com(\\/"+year+"\\/[\\d]{2}\\/[\\d]{2}\\/)","g"
      days = extractAllMatches data, exprDay
      days = excludeEqual days
      callback null,days
    (days) ->
      async.map days, getPostID, callback
  ], (err,results) ->
      callback null,results

getPostID= (day,callback) ->
  async.waterfall [
    (callback) ->
      httpGet user + ".livejournal.com", day, callback
    (data,callback) ->
      exprID = /itemid=([\d]+)[\s"']/g
      postID = extractAllMatches data, exprID
      if postID <= []
        exprID = new RegExp user +  "\\.livejournal\\.com\\/([\\d]+)\\.html","g"
        postID = extractAllMatches data, exprID
      postID= excludeEqual postID
      i=0
      while i<postID.length
        postID[i]= [postID[i],day]
        i++
      callback null,postID
  ], (err,results) ->
    callback null,results

to1LevelArray = (arr) ->
  newArr = []
  i=0;
  j=0;
  k=0;
  while i<arr.length
    while j<arr[i].length
      while k<arr[i][j].length
        newArr.push arr[i][j][k]
        k++
      k=0
      j++
    j=0
    i++
  return newArr

excludeEqual = (arr)->
  i=0
  newArr=[]
  while i<arr.length
    j=0
    equal=false
    while j<newArr.length
      equal=true if newArr[j]==arr[i]
      j++
    newArr.push arr[i] if !equal
    i++
  newArr

getText = (id,callback) ->
  httpGet user+".livejournal.com","/data/rss?itemid="+id[0],(err,data) ->
    text = extractAllMatches data, /<description>([^<>]+)<\/description>/g
    text = text[1] if text
    console.log text
    callback null, text

getTitleTagsDate = (id,text,callback) ->
  httpGet user+".livejournal.com","/"+id[0]+".html",(err,data)->
    titleExpr = new RegExp "<title>"+user+": ([^<]*)<\\/title>", "g"
    title = titleExpr.exec data
    if !title
      title = /<title>[^<-]+ - ([^<]*)<\/title>/g.exec data
    if !title
      title = /<title>[^<-]+: ([^<]*)<\/title>/g.exec data
    if !title
      console.log id
    title = title[1]
    console.log title
    tags = extractAllMatches data, new RegExp '<a rel=[\"\']tag[\"\'] href=[\"\']http:\\/\\/'+user+'\\.livejournal\\.com\\/tag\\/[\\w%]+[\"\']>([^<]+)<\\/a>','g'
    #if !tags.length
    #  tags = extractAllMatches data, new RegExp '<a href=[\'\"]http:\\/\\/'+user+'\\.livejournal\\.com\\/tag\\/[\\w%]+[\"\']>([^<>]+)<\\/a>','g'
    if !tags.length
      tags = extractAllMatches data, /\.livejournal\.com\/tag\/[\w%]+[\"\']>([^<>]+)<\/a>/g
      console.log tags
    date = />([^<>]+)<\/abbr>/g.exec data
    date = date[1] if date
    callback null, title: title,tags: tags,date: date,id: id,text:text

getAll = (id,callback) ->
  async.waterfall [
    (callback) -> getText id,callback
    (text,callback)-> getTitleTagsDate id,text,callback
  ],(err,data)->
    #console.log data
    callback null,data

async.waterfall [
  (callback) ->
    httpGet user + ".livejournal.com", "/calendar", callback
  (data, callback) ->
    exprYear = />([\d]{4})</g
    years = extractAllMatches data, exprYear
    years = excludeEqual years
    async.map years, getDays, callback
  (numbers,callback)->
    numbers = to1LevelArray numbers
    console.log numbers
    callback null,numbers
  (postID,callback) ->
    async.map postID, getAll,callback
], (err, posts) ->
  console.log posts.length
  fsort = (a,b)->
    return 1 if a.id[1]>b.id[1]
    return -1 if a.id[1]<b.id[1]
    return 1 if a.id[0]>b.id[0]
    return -1 if a.id[0]<b.id[0]
    return 0
  posts.sort fsort
  toFB2 = require './toFB2.coffee'
  toFB2 posts,user

