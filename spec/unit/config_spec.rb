require 'spec_helper'

describe Force do
  before do
    ENV['SALESFORCE_USERNAME']       = nil
    ENV['SALESFORCE_PASSWORD']       = nil
    ENV['SALESFORCE_SECURITY_TOKEN'] = nil
    ENV['SALESFORCE_CLIENT_ID']      = nil
    ENV['SALESFORCE_CLIENT_SECRET']  = nil
  end

  after do
    Force.instance_variable_set :@configuration, nil
  end

  describe '#configuration' do
    subject { Force.configuration }

    it { should be_a Force::Configuration }

    context 'by default' do
      its(:api_version)            { should eq '26.0' }
      its(:host)                   { should eq 'login.salesforce.com' }
      its(:authentication_retries) { should eq 3 }
      its(:adapter)                { should eq Faraday.default_adapter }
      [:username, :password, :security_token, :client_id, :client_secret,
       :oauth_token, :refresh_token, :instance_url, :compress, :timeout,
       :proxy_uri, :authentication_callback].each do |attr|
        its(attr) { should be_nil }
      end
    end

    context 'when environment variables are defined' do
      before do
        { 'SALESFORCE_USERNAME'       => 'foo',
          'SALESFORCE_PASSWORD'       => 'bar',
          'SALESFORCE_SECURITY_TOKEN' => 'foobar',
          'SALESFORCE_CLIENT_ID'      => 'client id',
          'SALESFORCE_CLIENT_SECRET'  => 'client secret',
          'PROXY_URI'                 => 'proxy',
          'SALESFORCE_HOST'           => 'test.host.com' }.
        each { |var, value| ENV.stub(:[]).with(var).and_return(value) }
      end

      its(:username)       { should eq 'foo' }
      its(:password)       { should eq 'bar'}
      its(:security_token) { should eq 'foobar' }
      its(:client_id)      { should eq 'client id' }
      its(:client_secret)  { should eq 'client secret' }
      its(:proxy_uri)      { should eq 'proxy' }
      its(:host)           { should eq 'test.host.com' }
    end
  end

  describe '#configure' do
    [:username, :password, :security_token, :client_id, :client_secret, :compress, :timeout,
     :oauth_token, :refresh_token, :instance_url, :api_version, :host, :authentication_retries,
     :proxy_uri, :authentication_callback].each do |attr|
      it "allows #{attr} to be set" do
        Force.configure do |config|
          config.send("#{attr}=", 'foobar')
        end
        expect(Force.configuration.send(attr)).to eq 'foobar'
      end
    end
  end

  describe '#log?' do
    subject { Force.log? }

    context 'by default' do
      it { should be_false }
    end
  end

  describe '#log' do
    context 'with logging disabled' do
      before do
        Force.stub :log? => false
      end

      it 'doesnt log anytning' do
        Force.configuration.logger.should_not_receive(:debug)
        Force.log 'foobar'
      end
    end

    context 'with logging enabled' do
      before do
        Force.stub :log? => true
        Force.configuration.logger.should_receive(:debug).with('foobar')
      end

      it 'logs something' do
        Force.log 'foobar'
      end
    end
  end
end
