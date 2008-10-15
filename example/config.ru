require 'rack/request'
require 'rack/response'
require '../lib/javascript_minifier.rb'

app = proc do |env|
  [200,  { 'Content-Type' => 'text/html' }, ['Hi there!'] ]
end

use Rack::ShowExceptions
use Rack::JavascriptMinifier, "./"
run app