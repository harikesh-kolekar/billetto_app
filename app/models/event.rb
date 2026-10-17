class Event < ApplicationRecord
  validates :title,       presence: true
  validates :external_id, presence: true, uniqueness: true

  has_many :event_votes

  def up_vote(user_id)
    return if user_vote_type(user_id) == "EventUpvoted"

    create_vote(user_id: user_id, voted: EventUpvoted)
  end

  def down_vote(user_id)
    return if user_vote_type(user_id) == "EventDownvoted"

    create_vote(user_id: user_id, voted: EventDownvoted)
   end

   def vote_count(vote_type)
       event_votes.where(vote_type: vote_type).count
   end

   def user_vote_type(user_id)
     return nil if user_id.blank?

    event_vote(user_id)&.vote_type
  end

  private

  def event_vote(user_id)
    event_votes.find_by(user_id: user_id)
  end

  def create_vote(user_id:, voted:)
    ActiveRecord::Base.transaction do
      event_vote = EventVote.find_or_initialize_by(event_id: id, user_id: user_id)
      event_vote.vote_type = voted.name
      event_vote.save!
      Rails.configuration.event_store.publish(voted.new(data: { event_id: id, user_id: user_id }), stream_name: stream_name)
    end
  end

  def stream_name
    "Eventvoted$#{id}"
  end
end
