require 'faraday'
require 'faraday_middleware'
require 'json'

require 'force/version'
require 'force/config'

module Force
  autoload :AbstractClient, 'force/abstract_client'
  autoload :SignedRequest,  'force/signed_request'
  autoload :Collection,     'force/collection'
  autoload :Middleware,     'force/middleware'
  autoload :Attachment,     'force/attachment'
  autoload :UploadIO,       'force/upload_io'
  autoload :SObject,        'force/sobject'
  autoload :Client,         'force/client'
  autoload :Mash,           'force/mash'

  module Concerns
    autoload :Authentication, 'force/concerns/authentication'
    autoload :Connection,     'force/concerns/connection'
    autoload :Picklists,      'force/concerns/picklists'
    autoload :Streaming,      'force/concerns/streaming'
    autoload :Caching,        'force/concerns/caching'
    autoload :Canvas,         'force/concerns/canvas'
    autoload :Verbs,          'force/concerns/verbs'
    autoload :Base,           'force/concerns/base'
    autoload :API,            'force/concerns/api'
  end

  module Data
    autoload :Client, 'force/data/client'
  end

  module Tooling
    autoload :Client, 'force/tooling/client'
  end

  Error               = Class.new(StandardError)
  AuthenticationError = Class.new(Error)
  UnauthorizedError   = Class.new(Error)

  class << self
    # Alias for Force::Data::Client.new
    #
    # Shamelessly pulled from https://github.com/pengwynn/octokit/blob/master/lib/octokit.rb
    def new(*args)
      data(*args)
    end

    def data(*args)
      Force::Data::Client.new(*args)
    end

    def tooling(*args)
      Force::Tooling::Client.new(*args)
    end

    # Helper for decoding signed requests.
    def decode_signed_request(*args)
      SignedRequest.decode(*args)
    end
  end

  # Add .tap method in Ruby 1.8
  module CoreExtensions
    def tap
      yield self
      self
    end
  end
  
  Object.send :include, Force::CoreExtensions unless Object.respond_to? :tap
end
