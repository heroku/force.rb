require 'spec_helper'

describe Force::Mash do
  describe '#build' do
    subject { described_class.build(input, nil) }

    context 'when array' do
      let(:input) { [{ :foo => 'hello' }, { :bar => 'world' }] }
      it { should be_all { |obj| expect(obj).to be_a Force::Mash } }
    end
  end

  describe '#klass' do
    subject { described_class.klass(input) }

    context 'when the hash has a "records" key' do
      let(:input) { { 'records' => nil } }
      it { should eq Force::Collection }
    end

    context 'when the hash has an "attributes" key' do
      let(:input) { { 'attributes' => { 'type' => 'Account' } } }
      it { should eq Force::SObject }

      context 'when the sobject type is an Attachment' do
        let(:input) { { 'attributes' => { 'type' => 'Attachment' } } }
        it { should eq Force::Attachment }
      end
    end

    context 'else' do
      let(:input) { {} }
      it { should eq Force::Mash }
    end
  end
end
