FactoryBot.define do
  factory :event do
    id { 1 }
    external_id { 1 }
    title { "MyTitle" }
    description { "Description text" }
    image_link { "Image URL" }
    startdate { "2026-10-16 11:14:43" }
    enddate { "2026-10-16 11:14:43" }
    url { "Billeto URL" }
    location { "MyLocation" }
    organiser_name { "MyOrgName" }
    availability { true }
    minimum_price { "34 DTC" }
    categorization { "" }
    billetto_data { "" }
  end
end
