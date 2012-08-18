require 'spec-helper'

describe EventStore::Persistence::Engines::InMemoryEngine do
  it_behaves_like "generic-persistence-engine"
end
