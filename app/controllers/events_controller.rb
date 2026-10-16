class EventsController < ApplicationController
  def index
    @events = Event.order(startdate: :asc)
                   .paginate(page: params[:page], per_page: 10)
  end

  def show
    @event = Event.find(params[:id])
  end
end
