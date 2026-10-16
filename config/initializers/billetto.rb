require "singleton"
class BillettoClient
  include Singleton

  BASE_URL = "https://billetto.dk/"
  @client = nil

  def initialize(
    access_key_id:     ENV.fetch("BILLETTO_ACCESS_KEY_ID"),
    access_key_secret: ENV.fetch("BILLETTO_ACCESS_KEY_SECRET")
  )
    return @client if @client.present?
    @access_key_id     = access_key_id
    @access_key_secret = access_key_secret
  end

  def list_events(after: nil, limit: 25)
    params = { limit: limit }
    params[:after] = after if after

    response = connection["/api/v3/public/events"].get(params: params)
    handle_response(response)
  end

  private

  def connection
    @client ||= RestClient::Resource.new(
      BASE_URL,
      timeout: 10,
      open_timeout: 5,
      headers: {
        content_type: :json,
        accept: :json,
        "Api-Keypair" => "#{@access_key_id}:#{@access_key_secret}"
      }
    )
  end

  def handle_response(response)
    case response.code
    when 200..299 then JSON.parse(response.body, symbolize_names: true)
    when 401      then raise AuthenticationError, "Invalid API credentials"
    when 429      then raise RateLimitError, "Rate limit exceeded"
    else               raise ApiError, "Unexpected API response: #{response.status}"
    end
  end
end
