require 'spec_helper'

describe Force::Concerns::Canvas do
  let(:options) { Hash.new }

  before do
    client.stub :options => options
  end

  describe '.decode_signed_request' do
    subject              { client.decode_signed_request(signed_request) }
    let(:signed_request) { double('Signed Request') }

    context 'when the client_secret is set' do
      let(:options) { { :client_secret => 'secret' } }

      it 'delegates to Force::SignedRequest' do
        Force::SignedRequest.should_receive(:decode).
          with(signed_request, options[:client_secret])
        client.decode_signed_request(signed_request)
      end
    end

    context 'when the client_secret is not set' do
      it 'raises an exception' do
        expect { subject }.to raise_error 'client_secret not set.'
      end
    end
  end
end