FactoryBot.define do
  factory :event_vote do
    event { nil }
    user_id { "MyString" }
    event_id { 1 }
    type { "" }
  end
end
