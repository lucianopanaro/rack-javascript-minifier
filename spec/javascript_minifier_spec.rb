require 'fileutils'
require 'rubygems'
require 'rack/mock'
require 'spec'
require 'javascript_minifier'

DIR_PATH = File.expand_path('public', File.dirname(__FILE__))
JS_FILE_PATH = File.expand_path('test.js', DIR_PATH)
JS_PARENT_PATH = File.expand_path('test.js', File.dirname(__FILE__))

describe "Rack::JavascriptMinifier" do  
  
  before(:each) do
    FileUtils.mkdir DIR_PATH
    File.open(JS_FILE_PATH, "w") {|f| f.puts "//this is some comment\nalert('hello'); //another comment" }
    File.open(JS_PARENT_PATH, "w") {|f| f.puts "//this is some comment\nalert('hello'); //another comment" }    
    
    @sample_app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello"]] }
  end
  
  after(:each) do
    FileUtils.rm_r [JS_FILE_PATH, JS_PARENT_PATH, DIR_PATH]
  end  
 
  it "should pass requests if file is not javascript" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))
    res = req.get("/cgi/something/") 
    res.should =~ /Hello/
  end  
  
  it "should pass requests if javascript file does not exist" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))
    res = req.get("/cgi/test.js")
    res.should =~ /Hello/    
  end
  
  it "should not allow directory traversal" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))
    res = req.get("/../test.js")
    res.should be_forbidden
  end
  
  it "should minify javascript files when requested" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))
    res = req.get("/test.js")
    res.should =~ /alert/
    res.should_not =~ /comment/
  end
  
  it "should re-minify if javascript file was updated" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))    
    updated_time = update_javascript_file(JS_FILE_PATH).httpdate
    res = req.get("/test.js")
    res["Last-Modified"].should eql(updated_time)
    res.should =~ /goodbye/    
  end
  
  it "should return already minified javascript file it wasn't updated" do
    req = Rack::MockRequest.new(Rack::Lint.new(Rack::JavascriptMinifier.new(@sample_app, DIR_PATH)))    
    res = req.get("/test.js")
    Dir.glob(File.join(DIR_PATH,"*_test.js")).size.should == 1
    res = req.get("/test.js")
    Dir.glob(File.join(DIR_PATH,"*_test.js")).size.should == 1
  end
  
  def update_javascript_file(path)
    sleep(1)
    File.open(path, "w") { |file| file.puts "// I am updated now :)\nalert('goodbye!');" }    
    File.mtime(path)
  end
  
end