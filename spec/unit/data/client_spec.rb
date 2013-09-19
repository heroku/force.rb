require 'spec_helper'

describe Force::Client do
  subject { described_class }

  it { should < Force::AbstractClient }
  it { should < Force::Concerns::Picklists }
  it { should < Force::Concerns::Streaming }
  it { should < Force::Concerns::Canvas }
end