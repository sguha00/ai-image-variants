# replicate_client.rb
require "faraday"
require "faraday_middleware"  # adds automatic JSON encoding/decoding

module Replicate
  API_ROOT   = "https://api.replicate.com".freeze
  API_PATH   = "/v1/predictions".freeze
  API_TOKEN  = ENV.fetch("REPLICATE_API_TOKEN", Rails.application.credentials[:replicate_api_token])

  class << self
    # Creates a prediction and waits for it to finish (equivalent to `Prefer: wait`)
    #
    # @param image_url [String]  URL of the image to crop
    # @param padding   [Float]   Padding value (0‑1); defaults to 0.5
    # @return [Hash]            Parsed JSON response body
    def create_prediction(version:, input:)
      connection.post(API_PATH) do |req|
        req.headers["Authorization"] = "Bearer #{API_TOKEN}"
        req.headers["Prefer"]        = "wait"

        # Faraday::Request::Json middleware encodes the body for us
        req.body = {
          version:,
          input:
        }
      end.body

    rescue Faraday::Error => e
      warn "Replicate API error: #{e.message}"
      raise
    end

    def get_prediction(id)
      connection.get("#{API_PATH}/#{id}") do |req|
        req.headers["Authorization"] = "Bearer #{API_TOKEN}"
      end.body
    end

    def run(version:, input:)
      prediction = create_prediction(version: version, input: input)
      prediction_id = prediction["id"]
      loop do
        prediction = Replicate.get_prediction(prediction_id)
        break if prediction["status"] == "succeeded"
        sleep 1
      end
      prediction
    end

    private

    def connection
      @connection ||= Faraday.new(API_ROOT) do |f|
        f.request  :json           # encode Ruby hash as JSON
        f.response :json           # parse JSON response into Ruby hash
        f.response :raise_error    # raise on 4xx/5xx
        f.adapter  Faraday.default_adapter
      end
    end
  end
end
