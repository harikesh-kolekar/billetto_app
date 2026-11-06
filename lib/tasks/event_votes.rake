namespace :event_votes do
  desc "Rebuild user votes and vote totals from event history (optionally set EVENT_ID)"
  task rebuild: :environment do
    projection = Billetto::EventVotesProjection.new
    events = ENV["EVENT_ID"].present? ? Event.where(id: Event.find(ENV["EVENT_ID"]).id) : Event.all

    events.find_each do |event|
      projection.rebuild(event)
      puts "Rebuilt vote projection for event #{event.id}"
    end
  end
end
