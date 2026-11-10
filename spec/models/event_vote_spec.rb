
require "rails_helper"

RSpec.describe EventVote, type: :model do
  describe "associations" do
    it "belongs to an event" do
      association = described_class.reflect_on_association(:event)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    let(:event) { create(:event) }

    it "is valid with valid attributes" do
      vote = described_class.new(
        event: event,
        user_id: "user_123",
        vote_type: "EventUpvoted"
      )

      expect(vote).to be_valid
    end

    it "requires an event" do
      vote = described_class.new(
        event: nil,
        user_id: "user_123",
        vote_type: "EventUpvoted"
      )

      expect(vote).not_to be_valid
      expect(vote.errors[:event]).to be_present
    end

    it "requires a user_id" do
      vote = described_class.new(
        event: event,
        user_id: nil,
        vote_type: "EventUpvoted"
      )

      expect(vote).not_to be_valid
      expect(vote.errors[:user_id]).to be_present
    end

    it "requires a vote_type" do
      vote = described_class.new(
        event: event,
        user_id: "user_123",
        vote_type: nil
      )

      expect(vote).not_to be_valid
      expect(vote.errors[:vote_type]).to be_present
    end

    it "accepts EventUpvoted" do
      vote = build(
        :event_vote,
        event: event,
        vote_type: "EventUpvoted"
      )

      expect(vote).to be_valid
    end

    it "accepts EventDownvoted" do
      vote = build(
        :event_vote,
        event: event,
        vote_type: "EventDownvoted"
      )

      expect(vote).to be_valid
    end

    it "rejects invalid vote types" do
      vote = build(
        :event_vote,
        event: event,
        vote_type: "InvalidVote"
      )

      expect(vote).not_to be_valid
      expect(vote.errors[:vote_type]).to be_present
    end

    it "prevents the same user from voting twice on the same event" do
      create(
        :event_vote,
        event: event,
        user_id: "user_123"
      )

      duplicate_vote = build(
        :event_vote,
        event: event,
        user_id: "user_123"
      )

      expect(duplicate_vote).not_to be_valid
      expect(duplicate_vote.errors[:user_id]).to include(
        "has already been taken"
      )
    end

    it "allows the same user to vote on different events" do
      create(
        :event_vote,
        event: event,
        user_id: "user_123"
      )

      another_event = create(:event, id: 234, external_id: 'new_external_id')

      vote = build(
        :event_vote,
        event: another_event,
        user_id: "user_123"
      )

      expect(vote).to be_valid
    end

    it "allows different users to vote on the same event" do
      create(
        :event_vote,
        event: event,
        user_id: "user_123"
      )

      vote = build(
        :event_vote,
        event: event,
        user_id: "user_456"
      )

      expect(vote).to be_valid
    end
  end
end
