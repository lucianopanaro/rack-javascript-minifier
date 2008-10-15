require 'time'
require File.join(File.dirname(__FILE__), 'jsmin.rb')

module Rack 
  class JavascriptMinifier
    F = ::File

    def initialize(app, path)
      @app = app
      @root = F.expand_path(path)
      raise "Provided path #{@root} does not exist" unless F.directory?(@root)
    end

    def call(env)
      path = F.join(@root, Utils.unescape(env["PATH_INFO"]))
      
      unless path.match(/.*\/(\w+\.js)$/) and F.file?(path)      
        return @app.call(env)
      end
      
      if env["PATH_INFO"].include?("..") or !F.readable?(path)
        body = "Forbidden\n"
        size = body.respond_to?(:bytesize) ? body.bytesize : body.size
        return [403, {"Content-Type" => "text/plain","Content-Length" => size.to_s}, [body]]
      end
      
      last_modified = F.mtime(path) 
      min_path = F.join(@root, "m_#{last_modified.to_i}_#{F.basename(path)}")
      
      unless F.file?(min_path)      
        F.open(path, "r") { |file|
          F.open(min_path, "w") { |f| f.puts JSMin.minify(file) }
        }
      end
      
      [200, {
             "Last-Modified"  => F.mtime(min_path).httpdate,
             "Content-Type"   => "text/javascript",
             "Content-Length" => F.size(min_path).to_s
            }, F.new(min_path, "r")]
    end
  end
end