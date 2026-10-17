class EventVote < ApplicationRecord
  belongs_to :event

  validates :user_id, presence: true,
                      uniqueness: { scope: :event_id }

  validates :vote_type,
            presence: true,
            inclusion: { in: %w[EventDownvoted EventUpvoted] }
end
