module Force
  class Middleware::Multipart < Faraday::Request::UrlEncoded
    self.mime_type = 'multipart/form-data'.freeze
    DEFAULT_BOUNDARY = "--boundary_string".freeze

    def call(env)
      match_content_type(env) do |params|
        env[:request] ||= {}
        env[:request][:boundary] ||= DEFAULT_BOUNDARY
        env[:request_headers][CONTENT_TYPE] += ";boundary=#{env[:request][:boundary]}"
        env[:body] = create_multipart(env, params)
      end
      @app.call env
    end

    def process_request?(env)
      type = request_type(env)
      env[:body].respond_to?(:each_key) and !env[:body].empty? and (
        (type.empty? and has_multipart?(env[:body])) or
        type == self.class.mime_type
      )
    end

    def has_multipart?(obj)
      # string is an enum in 1.8, returning list of itself
      if obj.respond_to?(:each) && !obj.is_a?(String)
        (obj.respond_to?(:values) ? obj.values : obj).each do |val|
          return true if (val.respond_to?(:content_type) || has_multipart?(val))
        end
      end
      false
    end

    def create_multipart(env, params)
      boundary = env[:request][:boundary]
      parts = []

      # Fields
      parts << Faraday::Parts::Part.new(boundary, 'entity_content', params.reject { |k,v| v.respond_to? :content_type }.to_json)

      # Files
      params.each do |k,v|
        parts << Faraday::Parts::Part.new(boundary, k.to_s, v) if v.respond_to? :content_type
      end

      parts << Faraday::Parts::EpiloguePart.new(boundary)

      body = Faraday::CompositeReadIO.new(parts)
      env[:request_headers]['Content-Length'] = body.length.to_s
      return body
    end
  end
end
