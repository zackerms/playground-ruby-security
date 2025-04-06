require 'webrick'
require 'erb'

# 攻撃者のWEBrickサーバー設定
server = WEBrick::HTTPServer.new(
  Port: ENV['PORT'] || 3000,
  DocumentRoot: "."
)

# CSRF攻撃ページ
server.mount_proc('/attack') do |req, res|
  @target_endpoint = "http://localhost:3000"
  template = ERB.new(File.read('erb/attack.erb'))
  res.body = template.result(binding)
end

server.mount_proc('/attack_secure') do |req, res|
  @target_endpoint = "http://localhost:4000"
  template = ERB.new(File.read('erb/attack.erb'))
  res.body = template.result(binding)
end


trap('INT') { server.shutdown }

server.start