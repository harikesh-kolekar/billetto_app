class FetchEventJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Billetto::LoadDataService.new.call
  end
end
