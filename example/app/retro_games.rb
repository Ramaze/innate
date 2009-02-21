require 'innate'
require 'yaml/store'

STORE = YAML::Store.new('games.yaml')

def STORE.[](key) transaction{|s| super } end
def STORE.[]=(key, value) transaction{|s| super } end
def STORE.each
  YAML.load_file('games.yaml').sort_by{|k,v| -v }.each{|(k,v)| yield(k, v) }
end

STORE['Pacman'] = 1

class Games
  Innate.node('/')

  def index
    TEMPLATE
  end

  def create
    STORE[request[:name]] ||= 0 if request.post?

    redirect_referrer
  end

  def vote(name)
    STORE[url_decode(name)] += 1

    redirect_referrer
  end

  TEMPLATE = <<-'T'.strip
<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>Top Retro Games</title>
  </head>
  <body>
    <h1>Vote on your favorite Retro Game</h1>
    <form action="<%= r :create %>" method="post">
      <input type="text" name="name" />
      <input type="submit" value="Add" />
    </form>
    <ol>
      <% STORE.each do |name, votes| %>
        <li>
          <%= Games.a("Vote", "/vote/#{u name}") %>
          <%= "%5d => %s" % [votes, name] %>
        </li>
      <% end %>
    </ol>
  </body>
</html>
  T

end

Innate.start
