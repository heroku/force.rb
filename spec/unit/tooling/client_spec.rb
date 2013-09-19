require 'spec_helper'

describe Force::Tooling::Client do
  subject { described_class }

  it { should < Force::AbstractClient }
end