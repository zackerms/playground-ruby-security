require 'webrick'
require 'mysql2'
require 'erb'
require 'digest'

# Create a WebRick server
server = WEBrick::HTTPServer.new(:Port => 3000)

server.mount_proc '/' do |req, res|
  res.body = File.read('public/rails.png')
  res.content_type = 'image/png'
  res.header['Etag'] = Digest::MD5.hexdigest(res.body)
  res.header['Cache-Control'] = 'max-age=3600, public'
  res.header['Last-Modified'] = Time.now.httpdate
end

# terminate server on Ctrl+C
trap('INT') { server.shutdown }

server.start