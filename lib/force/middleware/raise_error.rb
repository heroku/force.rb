module Force
  class Middleware::RaiseError < Faraday::Response::Middleware
    def on_complete(env)
      @env = env
      case env[:status]
      when 404
        raise Faraday::Error::ResourceNotFound, message
      when 401
        raise Force::UnauthorizedError, message
      when 413
        raise Faraday::Error::ClientError.new("HTTP 413 - Request Entity Too Large", env[:response])
      when 400...600
        raise Faraday::Error::ClientError.new(message, env[:response])
      end
    end

    def message
      "#{body.first['errorCode']}: #{body.first['message']}"
    end

    def body
      JSON.parse(@env[:body])
    end
  end
end
