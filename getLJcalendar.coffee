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
      exprDay = /livejournal\.com(\/[\d]{4}\/[\d]{2}\/[\d]{2}\/)/g
      days = extractAllMatches data, exprDay
      console.log days
      callback null,days
    (days) ->
      async.map days, getPostNumber, callback
  ], (err,results) ->
      callback null,results

getPostNumber = (day,callback) ->
  async.waterfall [
    (callback) ->
      httpGet user + ".livejournal.com", day, callback
    (data,callback) ->
      exprNumber = /itemid=([\d]+)[\s"']/g
      numbers = extractAllMatches data, exprNumber
      if numbers <= []
        numbers = extractAllMatches data, /livejournal\.com\/([\d]+)\.html/g
        i=0
        arr=[]
        while i<numbers.length
          j=0
          n=0
          while j<arr.length
            n=1 if arr[j]==numbers[i]
            j++
          arr.push numbers[i] if !n
          i++
        numbers=arr
      i=0
      while i<numbers.length
        numbers[i]= [numbers[i],day]
        i++
      callback null,numbers
  ], (err,results) ->
    console.log results
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

getText = (id,callback) ->
  httpGet user+".livejournal.com","/data/rss?itemid="+id[0],(err,data) ->
    text = extractAllMatches data, /<description>([^<>]+)<\/description>/g
    text = text[1]
    callback null, text

getTitleTagsDate = (id,text,callback) ->
  httpGet user+".livejournal.com","/"+id[0]+".html",(err,data)->
    title = /<title>[^<]+ - ([^<]*)<\/title>/g.exec data
    title = title[1]
    tags = extractAllMatches data, new RegExp '<a rel=.tag. href=.http:\\/\\/'+user+'\\.livejournal\\.com\\/tag\\/[\\w%]+.>([а-яА-Я\\w\\s]+)<\\/a>','g'
    date = />([^<>]+)<\/abbr>/g.exec data
    date = date[1] if date
    callback null, title: title,tags: tags,date: date,id: id,text:text

getAll = (id,callback) ->
  async.waterfall [
    (callback) -> getText id,callback
    (text,callback)-> getTitleTagsDate id,text,callback
  ],(err,data)->
    console.log data
    callback null,data

async.waterfall [
  (callback) ->
    httpGet user + ".livejournal.com", "/calendar", callback
  (data, callback) ->
    exprYear = /livejournal\.com(\/[\d]{4})\//g
    years = extractAllMatches data, exprYear
    async.map years, getDays, callback
  (numbers,callback)->
    numbers = to1LevelArray numbers
    console.log numbers
    callback null,numbers
  (postID,callback) ->
    async.map postID, getAll,callback
], (err, results) ->
  console.log results.length
  fsort = (a,b)->
    return 1 if a.id[1]<b.id[1]
    return -1 if a.id[1]>b.id[1]
    return 1 if a.id[0]<b.id[0]
    return -1 if a.id[0 ]>b.id[0]
    return 0
  results.sort fsort
  fs.writeFile user+"All.json", JSON.stringify results
