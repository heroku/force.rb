require 'spec_helper'

describe Force::Concerns::Authentication do
  describe '.authenticate!' do
    subject { lambda { client.authenticate! } }

    context 'when there is no authentication middleware' do
      before do
        client.stub :authentication_middleware => nil
      end

      it { should raise_error Force::AuthenticationError, 'No authentication middleware present' }
    end

    context 'when there is authentication middleware' do
      let(:authentication_middleware) { double('Authentication Middleware') }
      subject(:result) { client.authenticate! }

      it 'authenticates using the middleware' do
        client.stub :authentication_middleware => authentication_middleware
        client.stub :options
        authentication_middleware.
          should_receive(:new).
          with(nil, client, client.options).
          and_return(double(:authenticate! => 'foo'))
        expect(result).to eq 'foo'
      end
    end
  end

  describe '.authentication_middleware' do
    subject { client.authentication_middleware }

    context 'when username and password options are provided' do
      before do
        client.stub :username_password? => true
      end

      it { should eq Force::Middleware::Authentication::Password }
    end

    context 'when oauth options are provided' do
      before do
        client.stub :username_password? => false
        client.stub :oauth_refresh? => true
      end

      it { should eq Force::Middleware::Authentication::Token }
    end
  end

  describe '.username_password?' do
    subject       { client.username_password? }
    let(:options) { Hash.new }

    before do
      client.stub :options => options
    end

    context 'when username and password options are provided' do
      let(:options) do
        { :username      => 'foo',
          :password      => 'bar',
          :client_id     => 'client',
          :client_secret => 'secret' }
      end

      it { should be_true }
    end

    context 'when username and password options are not provided' do
      it { should_not be_true }
    end
  end

  describe '.oauth_refresh?' do
    subject       { client.oauth_refresh? }
    let(:options) { Hash.new }

    before do
      client.stub :options => options
    end

    context 'when oauth options are provided' do
      let(:options) do
        { :refresh_token => 'token',
          :client_id     => 'client',
          :client_secret => 'secret' }
      end

      it { should be_true }
    end

    context 'when oauth options are not provided' do
      it { should_not be_true }
    end
  end
end
