require 'spec_helper'

describe Force::Middleware::Authentication do
  let(:options) do
    { :host => 'login.salesforce.com',
      :proxy_uri => 'https://not-a-real-site.com',
      :authentication_retries => retries }
  end

  describe '.authenticate!' do
    subject { lambda { middleware.authenticate! }}
    it      { should raise_error NotImplementedError }
  end

  describe '.call' do
    subject { lambda { middleware.call(env) } }

    context 'when successfull' do
      before do
        app.should_receive(:call).once
      end

      it { should_not raise_error }
    end

    context 'when an exception is thrown' do
      before do
        env.stub :body => 'foo', :request => { :proxy => nil }
        middleware.stub :authenticate!
        app.should_receive(:call).once.
          and_raise(Force::UnauthorizedError.new('something bad'))
      end

      it { should raise_error Force::UnauthorizedError }
    end
  end

  describe '.connection' do
    subject(:connection) { middleware.connection }

    its(:url_prefix)     { should eq(URI.parse('https://login.salesforce.com')) }
    its(:proxy)          { should eq({ :uri => URI.parse('https://not-a-real-site.com') }) }

    describe '.builder' do
      subject(:builder) { connection.builder }

      context 'with logging disabled' do
        before do
          Force.stub :log? => false
        end

        its(:handlers) { should include FaradayMiddleware::ParseJson,
          Faraday::Adapter::NetHttp }
        its(:handlers) { should_not include Force::Middleware::Logger  }
      end

      context 'with logging enabled' do
        before do
          Force.stub :log? => true
        end

        its(:handlers) { should include FaradayMiddleware::ParseJson,
          Force::Middleware::Logger, Faraday::Adapter::NetHttp }
      end
    end
  end
end
