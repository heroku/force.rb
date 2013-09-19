module Force
  module Concerns
    module Base

      attr_reader :options

      # Public: Creates a new client instance
      #
      # opts - A hash of options to be passed in (default: {}).
      #        :username               - The String username to use (required for password authentication).
      #        :password               - The String password to use (required for password authentication).
      #        :security_token         - The String security token to use (required for password authentication).
      #
      #        :oauth_token            - The String oauth access token to authenticate api
      #                                  calls (required unless password
      #                                  authentication is used).
      #        :refresh_token          - The String refresh token to obtain fresh
      #                                  oauth access tokens (required if oauth
      #                                  authentication is used).
      #        :instance_url           - The String base url for all api requests
      #                                  (required if oauth authentication is used).
      #
      #        :client_id              - The oauth client id to use. Needed for both
      #                                  password and oauth authentication
      #        :client_secret          - The oauth client secret to use.
      #
      #        :host                   - The String hostname to use during
      #                                  authentication requests (default: 'login.salesforce.com').
      #
      #        :api_version            - The String REST api version to use (default: '24.0')
      #
      #        :authentication_retries - The number of times that client
      #                                  should attempt to reauthenticate
      #                                  before raising an exception (default: 3).
      #
      #        :compress               - Set to true to have Salesforce compress the response (default: false).
      #        :timeout                - Faraday connection request read/open timeout. (default: nil).
      #
      #        :proxy_uri              - Proxy URI: 'http://proxy.example.com:port' or 'http://user@pass:proxy.example.com:port'
      #
      #        :authentication_callback
      #                                - A Proc that is called with the response body after a successful authentication.
      def initialize(opts = {})
        raise ArgumentError, 'Please specify a hash of options' unless opts.is_a?(Hash)
        @options = Hash[Force.configuration.options.map { |option| [option, Force.configuration.send(option)] }]
        @options.merge! opts
        yield builder if block_given?
      end

      def instance_url
        authenticate! unless options[:instance_url]
        options[:instance_url]
      end

      def inspect
        "#<#{self.class} @options=#{@options.inspect}>"
      end

    end
  end
end