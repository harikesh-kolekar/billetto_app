module Billetto
  class LoadDataService
    attr_accessor :after
    def initialize(client: nil)
      @client = client || BillettoClient.instance
      @after   = nil
    end

    def call
      loop do
        page = @client.list_events(after: @after)
        data = page.fetch(:data, [])
        update_or_create_evenets(data)
        break unless page[:has_more]

        @after = data.last&.[](:id)
        raise "Data last element not found" if @after.blank?
      end
    end

    def update_or_create_evenets(data)
      data.each do |e|
        create_or_update_evenet(e)
      end
    end

    def create_or_update_evenet(e)
      event = Event.find_or_initialize_by(external_id: e[:id])
      event.assign_attributes(parse_event_attributes(e))
      event.save!
    end

    def parse_event_attributes(e)
      attributes  = e.slice(:title, :description, :image_link, :startdate, :enddate, :url, :availability, :categorization)
      attributes[:minimum_price] = minimum_price(e[:minimum_price])
      attributes[:location] = build_location(e[:location])
      attributes[:description] =  sanitize(attributes[:description])
      attributes[:organiser_name] = e.dig(:organiser, :name)
      attributes[:billetto_data] = e
      attributes
    end

    def build_location(loc)
      return nil unless loc

      [ loc[:location_name], loc[:address_line], loc[:city], loc[:country] ]
        .reject(&:blank?)
        .join(", ")
    end

    def minimum_price(price)
         [ price[:amount_in_cents], price[:currency] ].join(" ")
    end

    def sanitize(text)
      return nil unless text

      stripped = ActionController::Base.helpers.strip_tags(text)
      CGI.unescapeHTML(stripped)
    end
  end
end
