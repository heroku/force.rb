module Force
  # Middleware that simply injects the OAuth token into the request headers.
  class Middleware::Authorization < Force::Middleware
    AUTH_HEADER = 'Authorization'.freeze

    def call(env)
      env[:request_headers][AUTH_HEADER] = %(OAuth #{token})
      @app.call(env)
    end

    def token
      @options[:oauth_token]
    end
  end
end
