module Force
  # Faraday middleware that allows for on the fly authentication of requests.
  # When a request fails (a status of 401 is returned), the middleware
  # will attempt to either reauthenticate (username and password) or refresh
  # the oauth access token (if a refresh token is present).
  class Middleware::Authentication < Force::Middleware
    autoload :Password, 'force/middleware/authentication/password'
    autoload :Token,    'force/middleware/authentication/token'

    # Rescue from 401's, authenticate then raise the error again so the client
    # can reissue the request.
    def call(env)
      @app.call(env)
    rescue Force::UnauthorizedError
      authenticate!
      raise
    end

    # Internal: Performs the authentication and returns the response body.
    def authenticate!
      response = connection.post '/services/oauth2/token' do |req|
        req.body = encode_www_form(params)
      end
      raise Force::AuthenticationError, error_message(response) if response.status != 200
      @options[:instance_url] = response.body['instance_url']
      @options[:oauth_token]  = response.body['access_token']
      @options[:authentication_callback].call(response.body) if @options[:authentication_callback]
      response.body
    end

    # Internal: The params to post to the OAuth service.
    def params
      raise NotImplementedError
    end

    # Internal: Faraday connection to use when sending an authentication request.
    def connection
      @connection ||= Faraday.new(faraday_options) do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use Force::Middleware::Mashify, nil, @options
        builder.response :json
        builder.use Force::Middleware::Logger, Force.configuration.logger, @options if Force.log?
        builder.adapter Faraday.default_adapter
      end
    end

    # Internal: The parsed error response.
    def error_message(response)
      "#{response.body['error']}: #{response.body['error_description']}"
    end

    # Featured detect form encoding.
    # URI in 1.8 does not include encode_www_form
    def encode_www_form(params)
      if URI.respond_to?(:encode_www_form)
        URI.encode_www_form(params)
      else
        params.map do |k, v|
          k, v = CGI.escape(k.to_s), CGI.escape(v.to_s)
          "#{k}=#{v}"
        end.join('&')
      end
    end

    private

    def faraday_options
      { :url   => "https://#{@options[:host]}",
        :proxy => @options[:proxy_uri] 
      }.reject { |k, v| v.nil? }
    end
  end
end
