module Force
  class AbstractClient
    include Force::Concerns::Base
    include Force::Concerns::Connection
    include Force::Concerns::Authentication
    include Force::Concerns::Caching
    include Force::Concerns::API
  end
end
