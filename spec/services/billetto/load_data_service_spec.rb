require "rails_helper"

RSpec.describe Billetto::LoadDataService do
  let(:client) { instance_double(BillettoClient) }
  let(:payload) do
    {
      id: 42,
      title: "Concert",
      description: "<p>Music &amp; dancing</p>",
      minimum_price: { amount_in_cents: 1200, currency: "DKK" },
      location: { location_name: "Main Hall", address_line: "", city: "Copenhagen" },
      organiser: { name: "Local promoter" }
    }
  end

  it "imports every page, including the last one" do
    allow(client).to receive(:list_events).with(after: nil)
      .and_return(data: [ payload ], has_more: true)
    allow(client).to receive(:list_events).with(after: 42)
      .and_return(data: [ payload.merge(id: 43) ], has_more: false)

    described_class.new(client: client).call

    expect(Event.order(:external_id).pluck(:external_id)).to eq([ 42, 43 ])
    expect(Event.find_by!(external_id: 42)).to have_attributes(
      description: "Music & dancing",
      minimum_price: "1200 DKK",
      location: "Main Hall, Copenhagen",
      organiser_name: "Local promoter"
    )
  end

  it "updates an existing event without resetting its votes" do
    event = create(:event, external_id: 42)
    event.up_vote("alice")
    allow(client).to receive(:list_events).with(after: nil)
      .and_return(data: [ payload ], has_more: false)

    expect { described_class.new(client: client).call }.not_to change(Event, :count)

    expect(event.reload).to have_attributes(title: "Concert", upvotes: 1)
    expect(event.user_vote_type("alice")).to eq("EventUpvoted")
  end

  it "does not import anything from an empty page" do
    allow(client).to receive(:list_events).with(after: nil)
      .and_return(data: [], has_more: false)

    expect { described_class.new(client: client).call }.not_to change(Event, :count)
  end
end
