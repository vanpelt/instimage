# run very flat apps with merb -I <app file>.
require 'open-uri'
dependency "hpricot"

Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'instimage', :action =>'index')
  r.default_routes
end

class Instimage < Merb::Controller
  self._template_root = Merb.root
  def index
    render
  end
  
  def scrape
    provides :json
    root = params[:src][/^(https?:\/\/.+?\/).+/, 1]
    if root =~ /images\.google\.com/
      images = open(params[:src]).read.scan(/dyn\.Img\(".*?",".*?",".*?","(.+?)"/).flatten
    else
      begin
        parsed = Hpricot(open(params[:src]))
        #Pull images
        images = (parsed/"img").map do |i| 
          rel(i['src'])
        end.flatten.uniq
        #Pull images linked to
        images += (parsed/"a").map do |a|
          src = a['href']
          next unless src =~ /\.(jpg|jpeg|gif|png)$/
          rel(src)
        end.flatten.uniq
      rescue
        puts $!.inspect
        images = []
      end
    end
    display images
  end
  
  def create
    render <<-HTML
      <h2>I just did something awesome with this image</h2>
      <img src="#{params[:src]}"/><br/>
      <a href="/">Back to Instimage</a>
    HTML
  end
  
  private
  
  def rel(src)
    case src
    when /^http/: src
    when /^\//: File.join(root, src)
    else
      File.join(params[:src], src)
    end
  end
end

Merb::Config.use { |c|
  c[:framework]           = {},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}
