require "rails_helper"

RSpec.describe Event, type: :model do
  it "requires a title and external ID" do
    event = described_class.new

    expect(event).not_to be_valid
    expect(event.errors[:title]).to be_present
    expect(event.errors[:external_id]).to be_present
  end

  it "rejects a duplicate external ID" do
    create(:event, external_id: 42)
    duplicate = described_class.new(title: "Another concert", external_id: 42)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:external_id]).to include("has already been taken")
  end

  it "rejects negative vote totals" do
    event = build(:event, upvotes: -1, downvotes: -1)

    expect(event).not_to be_valid
    expect(event.errors[:upvotes]).to be_present
    expect(event.errors[:downvotes]).to be_present
  end
end
