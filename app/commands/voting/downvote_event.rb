module Voting
  class DownvoteEvent
    attr_reader :event_id, :user_id

    def initialize(event_id:, user_id:)
      @event_id = event_id
      @user_id = user_id
    end
  end
end
