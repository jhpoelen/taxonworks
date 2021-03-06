require 'rails_helper'

describe Queries::Citation::Filter, type: :model do

  let(:query) { Queries::Citation::Filter.new({}) }

  specify '#polymorphic_ids 0' do
    q = Queries::Citation::Filter.new( { collecting_event_id: 1 } )
    expect(q.polymorphic_ids).to eq({collecting_event_id: 1})
  end

  specify '#polymorphic_ids 1' do
    query.polymorphic_ids = { collecting_event_id: 1 }
    expect(query.polymorphic_ids).to eq({collecting_event_id: 1})
  end

  specify '#polymorphic_ids 2' do
    query.polymorphic_ids = { collecting_event_id: 1, foo_id: 22 }
    expect(query.polymorphic_ids).to eq({collecting_event_id: 1})
  end

  specify '#matching_polymorphic_ids 1' do
    query.polymorphic_ids = { collecting_event_id: 1 }
    expect(query.matching_polymorphic_ids.class).to eq(Arel::Nodes::And)
  end

  specify '#matching_polymorphic_ids 2' do
    query.polymorphic_ids = { collecting_event_id: 1, citation_object_id: 99 }
    expect(query.matching_polymorphic_ids.to_sql).to eq("\"citations\".\"citation_object_id\" = 1 AND \"citations\".\"citation_object_type\" = 'CollectingEvent'")
  end

  specify 'no polymorphic_ids' do
    query.source_id = 22
    expect(query.matching_polymorphic_ids).to eq(nil)
  end


end
