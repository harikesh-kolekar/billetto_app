module Voting
  class DownvoteEventHandler
    def call(command)
      Event.find(command.event_id).down_vote(command.user_id)
    end
  end
end
