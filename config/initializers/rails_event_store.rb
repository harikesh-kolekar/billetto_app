require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Rails.configuration.event_store.tap do |store|
    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)

    store.subscribe(Billetto::EventVotesProjection.new, to: [ EventUpvoted, EventDownvoted ])
  end

  Rails.configuration.command_bus.tap do |bus|
    bus.register(Voting::UpvoteEvent, Voting::UpvoteEventHandler.new)
    bus.register(Voting::DownvoteEvent, Voting::DownvoteEventHandler.new)
  end
end
