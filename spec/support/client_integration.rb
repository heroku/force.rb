module ClientIntegrationExampleGroup
  def self.included(base)
    base.class_eval do
      let(:oauth_token)    { '00Dx0000000BV7z!AR8AQAxo9UfVkh8AlV0Gomt9Czx9LjHnSSpwBMmbRcgKFmxOtvxjTrKW19ye6PE3Ds1eQz3z8jr3W7_VbWmEu4Q8TVGSTHxs' }
      let(:refresh_token)  { 'refresh' }
      let(:instance_url)   { 'https://na1.salesforce.com' }
      let(:username)       { 'foo'            }
      let(:password)       { 'bar'            }
      let(:security_token) { 'security_token' }
      let(:client_id)      { 'client_id'      }
      let(:client_secret)  { 'client_secret'  }
      let(:cache)          { nil }

      let(:base_options) do
        {
          :oauth_token    => oauth_token,
          :refresh_token  => refresh_token,
          :instance_url   => instance_url,
          :username       => username,
          :password       => password,
          :security_token => security_token,
          :client_id      => client_id,
          :client_secret  => client_secret,
          :cache          => cache
        }
      end

      let(:client_options) { base_options }

      subject(:client) { described_class.new client_options }
    end
  end

  RSpec.configure do |config|
    config.include self,
      :example_group => {
        :describes => lambda { |described| described <= Force::AbstractClient },
        :file_path => %r{spec/integration}
      }

    config.before :mashify => false do
      client.middleware.delete(Force::Middleware::Mashify)
    end
  end
end
