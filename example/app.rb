require 'sinatra/base'
require 'yaml'

class App < Sinatra::Base
  set :app_file, __FILE__
  set :static, true
  
  get '/' do
    @env = YAML.dump request.env
    erb :index
  end
  
  get '/user' do
    content_type :json
    request.env['couchdb.request']['userCtx'].to_json
  end
  
  # CouchDB doesn't give us an easy way to reload an external, so we'll expose an admin-only url to kill the process,
  # which will cause CouchDB to reload it. Saves us from having to restart the CouchDB server just to reload the external.
  # Could easily be triggered by a deploy script to reload the app on deploy.
  get '/reload' do
    if request.env['couchdb.request']['userCtx']['roles'].include? '_admin'
      Process.kill 'SIGTERM', 0
    else
      pass
    end
  end
  
  # Only one Rack process per external, so calls to this action will block the process for 10 seconds!
  # This limitation is inherent in CouchDB's external line protocol; there's nothing we can do here in Ruby to work around this.
  #
  # To run a quick test:
  #
  #   ab -c 2 -n 2 http://127.0.0.1:5984/mydb/_myapp/sleep
  #
  # ...should take 20 seconds to fulfill both requests.
  get '/sleep' do
    sleep 10
    'ZZZZZ'
  end
  
end