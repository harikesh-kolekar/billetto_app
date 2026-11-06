module Voting
  class UpvoteEventHandler
    def call(command)
      Event.find(command.event_id).up_vote(command.user_id)
    end
  end
end
