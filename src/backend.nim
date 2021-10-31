import prologue
import prologue/middlewares/signedcookiesession
import norm/[model, sqlite]
import std/[json, strutils, strformat, os, httpclient]

type Item = ref object of Model
  name: string

func newItem(name = ""): Item =
  Item(name: name)

if not existsEnv("DATABASE_URL"):
  echo("DATABASE_URL must be set")
  quit(QuitFailure)

let databaseUrl = getEnv("DATABASE_URL")
let databaseExists = fileExists(databaseUrl)
let connection = open(getEnv("DATABASE_URL"), "", "", "")
if not databaseExists:
  echo(fmt"creating {databaseUrl}")
  connection.createTables(newItem())

proc getRequestsCount(ctx: Context): int =
  var counter = ctx.session.getOrDefault("counter", "0").parseInt
  counter += 1
  ctx.session["counter"] = $counter
  counter

proc sampleRetrieveAll(ctx: Context) {.async, gcsafe.} =
  var items = @[newItem()]
  connection.selectAll(items)
  resp $(%*{
    "items": items,
    "requests_count": getRequestsCount(ctx)
  })

proc sampleCreate(ctx: Context) {.async, gcsafe.} =
  let obj = parseJson(ctx.request.body())
  let name = obj["name"].getStr()
  var item = newItem(name)
  try:
    connection.insert(item)
    resp $({
      "requests_count": getRequestsCount(ctx),
      "inserted_id": item.id.int
    })
  except:
    echo(getCurrentExceptionMsg())
    resp $(%*{
      "requests_count": getRequestsCount(ctx)
    })

proc sampleRetrieve(ctx: Context) {.async, gcsafe.} =
  var item = newItem()
  let itemId = ctx.getPathParams("item_id")
  try:
    connection.select(item, "Item.id = ?", itemId)
    resp $(%*{
      "name": item.name,
      "requests_count": getRequestsCount(ctx)
    })
  except:
    echo(getCurrentExceptionMsg())
    resp $(%*{
      "requests_count": getRequestsCount(ctx)
    })

proc sampleUpdate(ctx: Context) {.async, gcsafe.} =
  var item = newItem()
  let itemId = ctx.getPathParams("item_id")
  try:
    connection.select(item, "Item.id = ?", itemId)
    let obj = parseJson(ctx.request.body())
    let name = obj["name"].getStr()
    item.name = name
    connection.update(item)
  except:
    echo(getCurrentExceptionMsg())
  resp $(%*{
    "requests_count": getRequestsCount(ctx)
  })

proc sampleDelete(ctx: Context) {.async, gcsafe.} =
  var item = newItem()
  let itemId = ctx.getPathParams("item_id")
  try:
    connection.select(item, "Item.id = ?", itemId)
    connection.delete(item)
  except:
    echo(getCurrentExceptionMsg())
  resp $(%*{
    "requests_count": getRequestsCount(ctx)
  })

proc sampleHttpClient(ctx: Context) {.async, gcsafe.} =
  try:
    var client = newHttpClient()
    let obj = parseJson(client.getContent("http://httpbin.org/ip"))
    resp $(%*{
        "myIP": obj["origin"].getStr(),
        "requests_count": getRequestsCount(ctx)
    })
  except:
    echo(getCurrentExceptionMsg())
    resp $(%*{
      "requests_count": getRequestsCount(ctx)
    })

proc publicFileMiddleware(staticDir: string): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    var fileName = ctx.request.path
    if ctx.request.path == "/":
      fileName = "/index.html"
    if fileExists(fmt"{staticDir}{fileName}"):
      await staticFileResponse(ctx, fileName, staticDir, bufSize = ctx.gScope.settings.bufSize)
    else:
      await switch(ctx)

var port = Port(8080)
if existsEnv("PORT"):
  port = Port(parseInt(getEnv("PORT")))

let settings = newSettings(secretKey = "ee28a64e-a874-4756-88fb-5e0d325d4a07", port = port)
var app = newApp(settings = settings)
app.use(publicFileMiddleware("./public"))
app.use(sessionMiddleware(settings))
app.addRoute("/items"          , sampleRetrieveAll, HttpGet)
app.addRoute("/items"          , sampleCreate, HttpPost)
app.addRoute("/items/{item_id}", sampleRetrieve, HttpGet)
app.addRoute("/items/{item_id}", sampleUpdate, HttpPut)
app.addRoute("/items/{item_id}", sampleDelete, HttpDelete)
app.addRoute("/myip", sampleHttpClient, HttpGet)
app.run()
