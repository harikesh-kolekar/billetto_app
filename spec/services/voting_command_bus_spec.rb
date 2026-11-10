require "rails_helper"

RSpec.describe "Voting command bus" do
  let(:event) { Event.create!(title: "Concert", external_id: 12345) }
  let(:bus) { Rails.configuration.command_bus }

  def history
    Rails.configuration.event_store.read.stream(event.stream_name).to_a
  end

  it "records an upvote" do
    bus.call(Voting::UpvoteEvent.new(event_id: event.id, user_id: "alice"))

    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
    expect(history.map(&:event_type)).to eq([ "EventUpvoted" ])
  end

  it "switches an upvote to a downvote" do
    bus.call(Voting::UpvoteEvent.new(event_id: event.id, user_id: "alice"))
    bus.call(Voting::DownvoteEvent.new(event_id: event.id, user_id: "alice"))

    expect(event.vote_count("EventUpvoted")).to eq(0)
    expect(event.vote_count("EventDownvoted")).to eq(1)
    expect(history.map(&:event_type)).to eq(%w[EventUpvoted EventDownvoted])
  end

  it "ignores repeat votes" do
    2.times { bus.call(Voting::DownvoteEvent.new(event_id: event.id, user_id: "alice")) }

    expect(history.size).to eq(1)
    expect(event.event_votes.count).to eq(1)
  end

  it "rejects a missing event" do
    expect do
      bus.call(Voting::UpvoteEvent.new(event_id: -1, user_id: "alice"))
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
