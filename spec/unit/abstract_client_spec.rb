require 'spec_helper'

describe Force::AbstractClient do
  subject { described_class }

  it { should < Force::Concerns::Base }
  it { should < Force::Concerns::Connection }
  it { should < Force::Concerns::Authentication }
  it { should < Force::Concerns::Caching }
  it { should < Force::Concerns::API }
end