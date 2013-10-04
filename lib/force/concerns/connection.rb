module Force
  module Concerns
    module Connection
      # Public: The Faraday::Builder instance used for the middleware stack. This
      # can be used to insert an custom middleware.
      #
      # Examples
      #
      #   # Add the instrumentation middleware for Rails.
      #   client.middleware.use FaradayMiddleware::Instrumentation
      #
      # Returns the Faraday::Builder for the Faraday connection.
      def middleware
        connection.builder
      end

      alias_method :builder, :middleware

      private

      # Internal: Internal faraday connection where all requests go through
      def connection
        @connection ||= Faraday.new(options[:instance_url], connection_options) do |builder|
          # Parses JSON into Hashie::Mash structures.
          builder.use      Force::Middleware::Mashify, self, options
          # Handles multipart file uploads for blobs.
          builder.use      Force::Middleware::Multipart
          # Converts the request into JSON.
          builder.request  :json
          # Handles reauthentication for 403 responses.
          builder.use      authentication_middleware, self, options if authentication_middleware
          # Sets the oauth token in the headers.
          builder.use      Force::Middleware::Authorization, self, options
          # Ensures the instance url is set.
          builder.use      Force::Middleware::InstanceURL, self, options
          # Parses returned JSON response into a hash.
          builder.response :json, :content_type => /\bjson$/
          # Caches GET requests.
          builder.use      Force::Middleware::Caching, cache, options if cache
          # Follows 30x redirects.
          builder.use      FaradayMiddleware::FollowRedirects
          # Raises errors for 40x responses.
          builder.use      Force::Middleware::RaiseError
          # Log request/responses
          builder.use      Force::Middleware::Logger, Force.configuration.logger, options if Force.log?
          # Compress/Decompress the request/response
          builder.use      Force::Middleware::Gzip, self, options

          builder.adapter  adapter
        end
      end

      def adapter
        options[:adapter]
      end

      # Internal: Faraday Connection options
      def connection_options
        { :request => {
            :timeout => options[:timeout],
            :open_timeout => options[:timeout] },
          :proxy => options[:proxy_uri]
        }
      end

      # Internal: Returns true if the middlware stack includes the
      # Force::Middleware::Mashify middleware.
      def mashify?
        middleware.handlers.index(Force::Middleware::Mashify)
      end
    end
  end
end
