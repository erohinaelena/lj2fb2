fs    = require 'fs'
async = require 'async'
_     = require 'lodash'

someFunctions = require './someFunctions.coffee'
httpGet = someFunctions.httpGet
extractAllMatches = someFunctions.extractAllMatches

user = process.argv[process.argv.length-1]


getDays = (year, callback) ->
  async.waterfall [
    (callback) ->
      httpGet user + ".livejournal.com", "/"+year+"/", callback
    (data, callback) ->
      exprDay = new RegExp user + "\\.livejournal\\.com(\\/"+year+"\\/[\\d]{2}\\/[\\d]{2}\\/)","g"
      days = extractAllMatches data, exprDay
      days = _.uniq days
      callback null, days
    (days) ->
      async.map days, getPostID, callback
  ], (err, results) ->
    callback null, results

getPostID= (day, callback) ->
  async.waterfall [
    (callback) ->
      httpGet user + ".livejournal.com", day, callback
    (data, callback) ->
      exprID = /itemid=([\d]+)[\s"']/g
      postID = extractAllMatches data, exprID
      if postID <= []
        exprID = new RegExp user +  "\\.livejournal\\.com\\/([\\d]+)\\.html","g"
        postID = extractAllMatches data, exprID
      postID = _.uniq postID
      i=0
      while i < postID.length
        postID[i] = [postID[i],day]
        i++
      callback null, postID
  ], (err, results) ->
    callback null, results

getText = (id, callback) ->
  httpGet user + ".livejournal.com", "/data/rss?itemid=" + id[0], (err, data) ->
    text = extractAllMatches data, /<description>([^<>]+)<\/description>/g
    text = text[1] if text
    console.log text
    callback null, text

getTitleTagsDate = (id, text, callback) ->
  httpGet user+".livejournal.com","/"+id[0]+".html",(err, data)->
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
    callback null, title: title, tags: tags, date: date, id: id, text:text

getAll = (id, callback) ->
  async.waterfall [
    (callback) -> getText id, callback
    (text, callback)-> getTitleTagsDate id, text, callback
  ],(err, data)->
    #console.log data
    callback null, data

async.waterfall [
  (callback) ->
    httpGet user + ".livejournal.com", "/calendar", callback
  (data, callback) ->
    exprYear = />([\d]{4})</g
    years = extractAllMatches data, exprYear
    years = _.uniq years
    async.map years, getDays, callback
  (numbers, callback)->
    numbers = _.flatten numbers,true
    numbers = _.flatten numbers,true
    console.log numbers
    callback null, numbers
  (postID, callback) ->
    async.map postID, getAll, callback
], (err, posts) ->
  console.log posts.length
  fsort = (a, b)->
    return 1 if a.id[1]>b.id[1]
    return -1 if a.id[1]<b.id[1]
    return 1 if a.id[0]>b.id[0]
    return -1 if a.id[0]<b.id[0]
    return 0
  posts.sort fsort
  toFB2 = require './toFB2.coffee'
  toFB2 posts, user