fs = require 'fs'

posts = fs.readFileSync "dbogdanov.txt",{encoding: "utf8"}
posts = posts.split "\n%%%\n"

postNum = 0
bigText = ""

changeTag = (text,tag1,tag2) ->
  text = text.split tag1
  text = text.join tag2
  return text

extractAllMatches = (data, expr) ->
  link = expr.exec data
  arr = []
  while link?
    arr.push link[1]
    link = expr.exec data
  return arr

appendTags = (text)->
  i=0
  while i< text.length
    text[i] = changeTag text[i],"<br>",""
    text[i] = changeTag text[i],"<hr>",""
    text[i] = changeTag text[i],"<p>",""
    text[i] = changeTag text[i],"</p>",""
    text[i] = changeTag text[i],"<br />",""

    a = extractAllMatches text[i], /<([\w]+)>/g
    b = extractAllMatches text[i], /<\/([\w]+)>/g
    #console.log a+" !" if a
    #console.log b+" !" if a
    while a.length> b.length
      j=a.length
      k=0
      while j> 0
        if a[j-1]!=b[k]
          text[i]+="</"+a[j-1]+">"
          text[i+1]="<"+a[j-1]+">"+text[i+1]
          b.push a[j-1]
          #console.log a+"____!"
          #console.log b+"____!"
        j--
        k++
    i++
    #console.log a+" !!" if a
    #console.log b+" !!" if a

while postNum< posts.length-1
  post  = JSON.parse posts[postNum]
  text = post.text

  text = text.split "<br /><br />"
  appendTags text
  text = text.join "</p><empty-line/><p>"


  text = "<p>"+text+"</p>"
  post.title = post.title.split "\""
  post.title = post.title.join "&#34;"
  text = "<title><p>"+post.title+"</p></title>"+text

  text = changeTag text,"<i>","\n<emphasis>"
  text = changeTag text,"</i>","\n</emphasis>"

  text = changeTag text,"<em>","\n<emphasis>"
  text = changeTag text,"</em>","\n</emphasis>"

  text = changeTag text,"<b>","\n<strong>"
  text = changeTag text,"</b>","\n</strong>"

  text = changeTag text,"&nbsp;","&#160;"
  text = changeTag text,"&quot;","&#34;"

  text = changeTag text,"a href","a l:href"

  text = "<section>\n"+text+"\n</section>\n"

  bigText+=text
  console.log postNum+" "+post.title
  postNum++

fs.writeFile "dbogdanov.fb2", "<?xml version='1.0' encoding='utf-8'?>\n<FictionBook xmlns='http://www.gribuser.ru/xml/fictionbook/2.0' xmlns:l='http://www.w3.org/1999/xlink'>\n<body>"
fs.appendFile "dbogdanov.fb2", bigText+"\n"
fs.appendFile "dbogdanov.fb2", "</body>\n</FictionBook>"


###
htmlparser = require "htmlparser"
rawHtml = post.text
handler = new htmlparser.DefaultHandler (error, dom) ->
  if (error)
    console.log "err"
  #else
    #fs.writeFile "abc.json", JSON.stringify dom
parser = new htmlparser.Parser handler
parser.parseComplete rawHtml
console.log handler.dom.length
console.log handler.dom[0]

i = 0
text = ""
while i < handler.dom.length
  switch handler.dom[i].type
    when "text"
      text+=handler.dom[i].data
    when "tag"
      if handler.dom[i].name is "a"
        text+=  "<" + handler.dom[i].data + ">" + handler.dom[i].children[0].data + "</a>"
      else
        if handler.dom[i].name isnt "br"
          if handler.dom[i].children
            j=0
            while j<handler.dom[i].children.length
              if handler.dom[i].children[j].type is "text"
                text+= "<" + handler.dom[i].name + ">" + handler.dom[i].children[j].data + "</"+handler.dom[i].name+">"
              else
                k=0
                while k<handler.dom[i].children[j].children.length
                  if handler.dom[i].children[j].children[k].type is "text"
                    text+= "<" + handler.dom[i].name + ">" + "<"+handler.dom[i].children[j].name+">" + handler.dom[i].children[j].children[k].data  + "</"+handler.dom[i].children[j].name+">"+"</"+handler.dom[i].name+">"
                console.log handler.dom[i].name
                k++
              j++
        else text+="<br />"
    else
      console.log handler.dom[i].type
  i++
###
