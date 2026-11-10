class Billetto::EventVotesProjection
  VOTE_COLUMNS = { "EventUpvoted" => :upvotes, "EventDownvoted" => :downvotes }.freeze

  def call(vote_event)
    data = vote_event.data.symbolize_keys
    event = Event.find(data[:event_id])

    event.with_lock do
      vote = event.event_votes.find_or_initialize_by(user_id: data[:user_id])
      if vote.vote_type != vote_event.event_type
        previous_column = VOTE_COLUMNS[vote.vote_type]
        event[previous_column] -= 1 if previous_column
        event[VOTE_COLUMNS[vote_event.event_type]] += 1
      end
      vote.update!(vote_type: vote_event.event_type)
      event.save!
    end
  end

  def rebuild(event)
    event.with_lock do
      EventVote.where(event_id: event.id).delete_all
      event.update!(upvotes: 0, downvotes: 0)

      Rails.configuration.event_store.read.stream(event.stream_name).forward.each do |vote_event|
        call(vote_event) if VOTE_COLUMNS.key?(vote_event.event_type)
      end
    end
  end
end
