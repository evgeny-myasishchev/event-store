require 'spec-helper'

describe Xtms::EventStore::Persistence::Engines::InMemoryEngine do
  it_behaves_like "generic-persistence-engine"
end
