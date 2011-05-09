# Require Various Modules
sys = require 'sys'
http = require 'http'
fs = require 'fs'
io = require 'socket.io'
TwitterNode = require('twitter-node').TwitterNode

# Read in your twitter credentials
twitterCredentials = require './twitter-auth'

# Synchronously, read in the index.html file so we can
# serve it to clients
indexFile = fs.readFileSync 'index.html', 'utf8'

# Setup the HTTP server to serve the inital page.
server = http.createServer (request, response) ->

  # Set the correct headers for the http response,
  # then send the response with the contents of the
  # index file we read in on application start.
  response.writeHead 200, 'Content-Type': 'text/html'
  response.end indexFile

# Bind the HTTP server to port 8008
server.listen 8008

# Create the stream from Twitter
stream = new TwitterNode  user: twitterCredentials.username, password: twitterCredentials.password

# Track Keywords
stream.track 'art'

# Hook into the http server for websocket connections
socket = io.listen server

# Handle Websocket connection
socket.on 'connection', (client) ->

  # Define callback.
  # When we receive a tweet, we want to send it to 
  # the client.
  # This is defined before hand so we can remove the
  # listener when the client disconnects.
  callback = (tweet) ->
    client.send tweet: tweet.text

  # Listen for tweets to be streamed to us, 
  # then broadcast them to all clients (each
  # client will have a listener on the stream).
  stream.addListener 'tweet', callback

  # Output the STDOUT if there was an error.
  stream.addListener 'error', (error) ->
    sys.puts "Error: #{error}"
  
  # Handle the websocket disconnection.
  # We will remove the listener from the
  # tweet stream when the client disconnects.
  client.on 'disconnect', (client) -> 
    stream.removeListener 'tweet', callback

# Start Streaming from Twitter
stream.stream()
