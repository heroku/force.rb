require 'hashie/mash'

module Force
  class Mash < Hashie::Mash

    class << self

      # Pass in an Array or Hash and it will be recursively converted into the
      # appropriate Force::Collection, Force::SObject and
      # Force::Mash objects.
      def build(val, client)
        if val.is_a?(Array)
          val.collect { |val| self.build(val, client) }
        elsif val.is_a?(Hash)
          self.klass(val).new(val, client)
        else
          val
        end
      end

      # When passed a hash, it will determine what class is appropriate to
      # represent the data.
      def klass(val)
        if val.has_key? 'records'
          # When the hash has a records key, it should be considered a collection
          # of sobject records.
          Force::Collection
        elsif val.has_key? 'attributes'
          if val['attributes']['type'] == 'Attachment'
            Force::Attachment
          else
            # When the hash contains an attributes key, it should be considered an
            # sobject record
            Force::SObject
          end
        else
          # Fallback to a standard Force::Mash for everything else
          Force::Mash
        end
      end

    end

    def initialize(source_hash = nil, client = nil, default = nil, &blk)
      @client = client
      deep_update(source_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    def dup
      self.class.new(self, @client, self.default)
    end
  
    def convert_value(val, duping=false)
      case val
      when self.class
        val.dup
      when ::Hash
        val = val.dup if duping
        self.class.klass(val).new(val, @client)
      when Array
        val.collect{ |e| convert_value(e) }
      else
        val
      end
    end

  end
end
