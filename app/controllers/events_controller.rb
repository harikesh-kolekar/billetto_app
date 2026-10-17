class EventsController < ApplicationController
  before_action :find_vote, only: [ :show, :up_vote, :down_vote ]

  before_action :validate_user, only: [ :up_vote, :down_vote ]

  def index
    @events = Event.order(startdate: :asc)
                   .paginate(page: params[:page], per_page: 10)
  end

  def show
    @total_up_votes = @event.vote_count("EventUpvoted")
    @total_down_votes = @event.vote_count("EventDownvoted")
    @current_user_vote_type = @event.user_vote_type(clerk.user&.id)
  end

  def up_vote
    @event.up_vote(clerk.user.id)
    redirect_to event_path(@event)
  end

  def down_vote
    @event.down_vote(clerk.user.id)
    redirect_to event_path(@event)
  end

  private

  def find_vote
    @event = Event.find(params[:id])
  end

  def validate_user
    return if clerk.user?

    redirect_back fallback_location: events_path,
                alert: "Please log in to vote."
  end
end
