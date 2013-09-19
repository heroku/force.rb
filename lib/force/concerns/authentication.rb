module Force
  module Concerns
    module Authentication

      # Public: Force an authentication
      def authenticate!
        raise AuthenticationError, 'No authentication middleware present' unless authentication_middleware
        middleware = authentication_middleware.new nil, self, options
        middleware.authenticate!
      end

      # Internal: Determines what middleware will be used based on the options provided
      def authentication_middleware
        if username_password?
          Force::Middleware::Authentication::Password
        elsif oauth_refresh?
          Force::Middleware::Authentication::Token
        end
      end

      # Internal: Returns true if username/password (autonomous) flow should be used for
      # authentication.
      def username_password?
        options[:username] &&
          options[:password] &&
          options[:client_id] &&
          options[:client_secret]
      end

      # Internal: Returns true if oauth token refresh flow should be used for
      # authentication.
      def oauth_refresh?
        options[:refresh_token] &&
          options[:client_id] &&
          options[:client_secret]
      end

    end
  end
end
