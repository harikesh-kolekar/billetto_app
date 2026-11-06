class Event < ApplicationRecord
  validates :title,       presence: true
  validates :external_id, presence: true, uniqueness: true
  validates :upvotes, :downvotes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :event_votes

  def up_vote(user_id)
    create_vote(user_id: user_id, voted: EventUpvoted)
  end

  def down_vote(user_id)
    create_vote(user_id: user_id, voted: EventDownvoted)
   end

   def vote_count(vote_type)
     column = { "EventUpvoted" => :upvotes, "EventDownvoted" => :downvotes }[vote_type]
     return 0 unless column

     self.class.where(id: id).pick(column) || 0
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
    with_lock do
      next if user_vote_type(user_id) == voted.name

      Rails.configuration.event_store.publish(
        voted.new(data: { event_id: id, user_id: user_id }),
        stream_name: stream_name
      )
    end
  end

  def stream_name
    "Eventvoted$#{id}"
  end
end
