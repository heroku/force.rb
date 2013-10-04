module Force
  # Middleware the converts sobject records from JSON into Force::SObject objects
  # and collections of records into Force::Collection objects.
  class Middleware::Mashify < Force::Middleware
    def call(env)
      @env = env
      response = @app.call(env)
      env[:body] = Force::Mash.build(body, client)
      response
    end

    def body
      @env[:body]
    end  
  end
end
