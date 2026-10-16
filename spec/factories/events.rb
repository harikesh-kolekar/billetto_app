FactoryBot.define do
  factory :event do
    id { 1 }
    external_id { 1 }
    title { "MyString" }
    description { "MyText" }
    image_url { "MyString" }
    starts_at { "2026-10-16 11:14:43" }
    ends_at { "2026-10-16 11:14:43" }
    billetto_url { "MyString" }
    location { "MyString" }
    organiser_name { "MyString" }
    available { false }
    minimum_price { "MyString" }
    categorization { "" }
    billetto_data { "" }
  end
end
