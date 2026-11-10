require "rails_helper"

RSpec.describe "Events", type: :request do
  it "lists events by start date across pages" do
    11.downto(1) do |day|
      Event.create!(title: "Concert #{day}", external_id: day, startdate: Time.utc(2026, 11, day))
    end

    get events_path

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css(".events-table tbody tr td:first-child").map(&:text))
      .to eq((1..10).map { |day| "Concert #{day}" })

    get events_path(page: 2)

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css(".events-table tbody tr td:first-child").map(&:text))
      .to eq([ "Concert 11" ])
  end

  it "shows the totals stored on the event" do
    event = create(:event, upvotes: 7, downvotes: 2)

    get event_path(event)

    expect(response).to have_http_status(:ok)
    buttons = Nokogiri::HTML(response.body).css(".vote-button").map { |button| button.text.strip }
    expect(buttons).to eq([ "👍 7", "👎 2" ])
  end

  it "returns 404 for a missing event" do
    get event_path(-1)

    expect(response).to have_http_status(:not_found)
  end
end
