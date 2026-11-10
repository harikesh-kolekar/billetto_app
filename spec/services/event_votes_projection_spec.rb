require "rails_helper"

RSpec.describe Billetto::EventVotesProjection do
  let(:event) { Event.create!(title: "Concert", external_id: 12345) }
  let(:store) { Rails.configuration.event_store }
  let(:projection) { described_class.new }

  def history
    store.read.stream(event.stream_name).to_a
  end

  it "updates the totals when a vote changes" do
    event.up_vote("alice")
    event.down_vote("bob")
    event.down_vote("alice")

    expect(event.vote_count("EventUpvoted")).to eq(0)
    expect(event.vote_count("EventDownvoted")).to eq(2)
    expect(event.event_votes.count).to eq(2)
    expect(history.map(&:event_type)).to eq(%w[EventUpvoted EventDownvoted EventDownvoted])
  end

  it "skips publishing a repeat vote" do
    event.up_vote("alice")
    event.up_vote("alice")

    expect(history.size).to eq(1)
    expect(event.event_votes.count).to eq(1)
    expect(event.vote_count("EventUpvoted")).to eq(1)
  end

  it "reads the totals from the event" do
    event.up_vote("alice")
    EventVote.where(event_id: event.id).delete_all

    expect(event.vote_count("EventUpvoted")).to eq(1)
    expect(event.reload.upvotes).to eq(1)
  end

  it "counts a repeated event once" do
    event.up_vote("alice")

    2.times { projection.call(history.first) }

    expect(event.vote_count("EventUpvoted")).to eq(1)
  end

  it "updates the vote when an event is published" do
    store.publish(
      EventUpvoted.new(data: { event_id: event.id, user_id: "alice" }),
      stream_name: event.stream_name
    )

    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
  end

  it "rolls back the vote if totals fail to save" do
    event.up_vote("alice")
    allow_any_instance_of(Event).to receive(:save!).and_raise("totals failed")

    expect { event.down_vote("alice") }.to raise_error("totals failed")
    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
    expect(event.vote_count("EventUpvoted")).to eq(1)
    expect(event.vote_count("EventDownvoted")).to eq(0)
    expect(history.map(&:event_type)).to eq([ "EventUpvoted" ])
  end

  it "updates the vote and links the event" do
    vote_event = EventUpvoted.new(
      data: { event_id: event.id, user_id: "alice" },
      metadata: { correlation_id: "vote-request", causation_id: "vote-command" }
    )

    store.publish(vote_event, stream_name: event.stream_name)

    expect(store).to be_a(RailsEventStore::JSONClient)
    %w[$by_type_EventUpvoted $by_correlation_id_vote-request $by_causation_id_vote-command].each do |stream|
      expect(store.read.stream(stream).map(&:event_id)).to include(vote_event.event_id)
    end
    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
  end

  it "rolls back history if the subscriber fails" do
    event.up_vote("alice")
    allow_any_instance_of(described_class).to receive(:call).and_raise("projection failed")

    expect { event.down_vote("alice") }.to raise_error("projection failed")
    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
    expect(history.map(&:event_type)).to eq([ "EventUpvoted" ])
  end

  it "rebuilds votes without adding to history" do
    event.up_vote("alice")
    event.down_vote("bob")
    event.down_vote("alice")
    event.up_vote("bob")
    original_ids = history.map(&:event_id)
    EventVote.where(event_id: event.id).delete_all
    event.event_votes.create!(user_id: "stale", vote_type: "EventUpvoted")
    event.update!(upvotes: 99, downvotes: 99)

    2.times { projection.rebuild(event) }

    expect(event.event_votes.pluck(:user_id, :vote_type).to_h).to eq(
      "alice" => "EventDownvoted", "bob" => "EventUpvoted"
    )
    expect(history.map(&:event_id)).to eq(original_ids)
    expect(event.vote_count("EventUpvoted")).to eq(1)
    expect(event.vote_count("EventDownvoted")).to eq(1)
  end

  it "rebuilds only the selected event" do
    other = Event.create!(title: "Another concert", external_id: 67890)
    other.up_vote("alice")
    event.down_vote("alice")

    projection.rebuild(event)

    expect(other.user_vote_type("alice")).to eq("EventUpvoted")
  end

  it "keeps the old votes if rebuild fails" do
    event.up_vote("alice")
    allow(projection).to receive(:call).and_raise("replay failed")

    expect { projection.rebuild(event) }.to raise_error("replay failed")
    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
    expect(event.vote_count("EventUpvoted")).to eq(1)
  end

  it "resets totals when there is no history" do
    event.event_votes.create!(user_id: "stale", vote_type: "EventUpvoted")
    event.update!(upvotes: 99)

    projection.rebuild(event)

    expect(event.event_votes).to be_empty
    expect(event.vote_count("EventUpvoted")).to eq(0)
    expect(event.vote_count("EventDownvoted")).to eq(0)
  end
end
