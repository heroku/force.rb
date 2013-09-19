module Force
  # Base class that all middleware can extend. Provides some convenient helper
  # functions.
  class Middleware < Faraday::Middleware
    autoload :RaiseError,     'force/middleware/raise_error'
    autoload :Authentication, 'force/middleware/authentication'
    autoload :Authorization,  'force/middleware/authorization'
    autoload :InstanceURL,    'force/middleware/instance_url'
    autoload :Multipart,      'force/middleware/multipart'
    autoload :Mashify,        'force/middleware/mashify'
    autoload :Caching,        'force/middleware/caching'
    autoload :Logger,         'force/middleware/logger'
    autoload :Gzip,           'force/middleware/gzip'

    def initialize(app, client, options)
      @app, @client, @options = app, client, options
    end

    # Internal: Proxy to the client.
    def client
      @client
    end

    # Internal: Proxy to the client's faraday connection.
    def connection
      client.send(:connection)
    end
  end
end
