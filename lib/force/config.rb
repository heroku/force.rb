require 'logger'

module Force
  class << self
    attr_writer :log

    # Returns the current Configuration
    #
    # Example
    #
    #    Force.configuration.username = "username"
    #    Force.configuration.password = "password"
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the Configuration
    #
    # Example
    #
    #    Force.configure do |config|
    #      config.username = "username"
    #      config.password = "password"
    #    end
    def configure
      yield configuration
    end

    def log?
      @log ||= false
    end

    def log(message)
      return unless Force.log?
      Force.configuration.logger.send :debug, message
    end
  end

  class Configuration
    class Option
      attr_reader :configuration, :name, :options

      def self.define(*args)
        new(*args).define
      end

      def initialize(configuration, name, options = {})
        @configuration, @name, @options = configuration, name, options
        @default = options.fetch(:default, nil)
      end

      def define
        write_attribute
        define_method if default_provided?
        self
      end

    private
    
      attr_reader :default
      alias_method :default_provided?, :default

      def write_attribute
        configuration.send :attr_accessor, name
      end

      def define_method
        our_default = default
        our_name    = name
        configuration.send :define_method, our_name do
          instance_variable_get(:"@#{our_name}") ||
            instance_variable_set(:"@#{our_name}", our_default.respond_to?(:call) ? our_default.call : our_default)
        end
      end
    end

    class << self
      attr_accessor :options

      def option(*args)
        option = Option.define(self, *args)
        (self.options ||= []) << option.name
      end
    end

    option :api_version, :default => '26.0'

    # The username to use during login.
    option :username, :default => lambda { ENV['SALESFORCE_USERNAME'] }

    # The password to use during login.
    option :password, :default => lambda { ENV['SALESFORCE_PASSWORD'] }

    # The security token to use during login.
    option :security_token, :default => lambda { ENV['SALESFORCE_SECURITY_TOKEN'] }

    # The OAuth client id
    option :client_id, :default => lambda { ENV['SALESFORCE_CLIENT_ID'] }

    # The OAuth client secret
    option :client_secret, :default => lambda { ENV['SALESFORCE_CLIENT_SECRET'] }

    # Set this to true if you're authenticating with a Sandbox instance.
    # Defaults to false.
    option :host, :default => lambda { ENV['SALESFORCE_HOST'] || 'login.salesforce.com' }

    option :oauth_token
    option :refresh_token
    option :instance_url

    # Set this to an object that responds to read, write and fetch and all GET
    # requests will be cached.
    option :cache
    
    # Flag to determine whether to use Mashify Middleware or not
    option :mashify

    # The number of times reauthentication should be tried before failing.
    option :authentication_retries, :default => 3

    # Set to true if you want responses from Salesforce to be gzip compressed.
    option :compress

    # Faraday request read/open timeout.
    option :timeout

    # Faraday adapter to use. Defaults to Faraday.default_adapter.
    option :adapter, :default => lambda { Faraday.default_adapter }

    option :proxy_uri, :default => lambda { ENV['PROXY_URI'] }

    # A Proc that is called with the response body after a successful authentication.
    option :authentication_callback

    def logger
      @logger ||= ::Logger.new STDOUT
    end

    def options
      self.class.options
    end
  end
end
