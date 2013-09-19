module Force
  module Data
    class Client < AbstractClient
      include Force::Concerns::Streaming
      include Force::Concerns::Picklists
      include Force::Concerns::Canvas

      # Public: Returns a url to the resource.
      #
      # resource - A record that responds to to_sparam or a String/Fixnum.
      #
      # Returns the url to the resource.
      def url(resource)
        "#{instance_url}/#{(resource.respond_to?(:to_sparam) ? resource.to_sparam : resource)}"
      end
    end
  end
end
