FactoryBot.define do
  factory :event_vote do
    event { event }
    user_id { "MyString" }
    vote_type { "EventDownvoted" }
  end
end
