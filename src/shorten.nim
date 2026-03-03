{.define: ssl.}
import std/[httpclient, random, os, strutils]

proc genKey(): string =
  randomize()
  for _ in 0..<6:
    result.add chr(ord('a') + rand(25))

proc main() =
  let key = getEnv("SHORTEN_KEY")
  let baseUrl = getEnv("SHORTEN_URL").strip(chars = {'/'})
  if key == "" or baseUrl == "":
    stderr.writeLine "SHORTEN_KEY and SHORTEN_URL environment variables are required"
    quit(1)

  let args = commandLineParams()

  if args.len == 2 and args[0] == "get":
    let client = newHttpClient(maxRedirects = 0)
    let path = args[1].strip(chars = {'/'})
    let resp = client.request(baseUrl & "/" & path, httpMethod = HttpGet)
    if resp.code == Http301:
      echo resp.headers["Location"]
    else:
      stderr.writeLine "Not found"
      quit(1)

  elif args.len == 2 and args[0] == "delete":
    let client = newHttpClient()
    client.headers = newHttpHeaders({"Auth": "Bearer " & key})
    let path = args[1].strip(chars = {'/'})
    let resp = client.request(baseUrl & "/" & path, httpMethod = HttpDelete)
    if resp.code == Http201:
      echo resp.body
    else:
      stderr.writeLine resp.body
      quit(1)

  else:
    var url: string
    if args.len == 1:
      url = args[0]
    elif args.len == 0:
      url = stdin.readLine().strip()
    else:
      stderr.writeLine "Usage: shorten <url> | shorten get <key> | shorten delete <key>"
      quit(1)
    let client = newHttpClient()
    client.headers = newHttpHeaders({"Auth": "Bearer " & key})
    let token = genKey()
    let resp = client.request(baseUrl & "/" & token, httpMethod = HttpPut, body = url)
    if resp.code == Http201:
      echo baseUrl & "/" & token
    else:
      stderr.writeLine resp.body
      quit(1)

main()
