require 'webrick'
require 'mysql2'
require 'erb'
require 'digest'

PORT = ENV['PORT'] || 3000

# Create a WebRick server
server = WEBrick::HTTPServer.new(:Port => PORT)

server.mount_proc '/' do |req, res|
  res.body = File.read('public/rails.png')
  res.content_type = 'image/png'
  res.header['Etag'] = Digest::MD5.hexdigest(res.body)
  res.header['Cache-Control'] = 'max-age=3600, public'
  res.header['Last-Modified'] = File.mtime('public/rails.png').httpdate
end

# terminate server on Ctrl+C
trap('INT') { server.shutdown }

server.start