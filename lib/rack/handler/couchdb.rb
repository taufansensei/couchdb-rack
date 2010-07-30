require 'json'
require 'rack/utils'
require 'stringio'

module Rack
  module Handler
    class Couchdb
      
      def self.run(app, options = nil)
        new(app).run
      end
      
      def initialize(app)
        @app = app
      end
      
      def run
        while line = $stdin.readline
          req = JSON.parse line
          env = build_env(req)
          status, headers, body = @app.call(env)
          begin
            outbody = ''
            body.each {|s| outbody << s}
            resp = {:code => status, :headers => headers, :body => outbody}
            $stdout.puts resp.to_json
            $stdout.flush
          ensure
            body.close  if body.respond_to? :close
          end
        end
      end

      private
            
        def build_env(req)
          path = req['path'] || []
          headers = req['headers'] || {}
          host, port = (headers['host'] || '').split(':')
          env = {
            'REQUEST_METHOD' => req['method'] || 'GET',
            'SERVER_NAME' => host || 'localhost',
            'SERVER_PORT' => port || '5984',
            'QUERY_STRING' => Rack::Utils.build_query(req['query'] || {}),
            'PATH_INFO' => path_info(path),
            'rack.url_scheme' => 'http',
            'HTTPS' => 'off',
            'SCRIPT_NAME' => script_name(path),
            'rack.errors' => $stderr,
            'rack.input' => StringIO.new(req['body'] || ''),
            'rack.version' => Rack::VERSION,
            'rack.multithread' => false,
            'rack.multiprocess' => false,
            'rack.run_once' => false,
            'couchdb.request' => req
          }
          headers.each do |key, val|
            # header processing taken from Kidgloves:
            key = key.upcase.gsub('-', '_')
            key = "HTTP_#{key}" if !%w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
            env[key] = val
          end
          env
        end
      
        def path_info(parts)
          if parts.length > 2
            "/#{parts[2,parts.length].join('/')}"
          else
            '/'
          end
        end
      
        def script_name(parts)
          if parts.empty?
            ''
          else
            "/#{parts[0,2].join('/')}"
          end
        end
      
    end
  end
end
