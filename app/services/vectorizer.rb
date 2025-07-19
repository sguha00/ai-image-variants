require "faraday"

module Vectorizer
  API_ROOT   = "https://vectorizer.ai".freeze
  API_PATH   = "/api/v1/vectorize".freeze
  API_TOKEN  = ENV.fetch("VECTORIZER_API_TOKEN", Rails.application.credentials[:vectorizer_auth_token])

  class << self
    # Vectorizes an image using the Vectorizer API
    #
    # @param image_path [String] Path to the image file
    # @return [String]           SVG result or error message
    def run(image)
      image_data = image.write_to_buffer(".jpeg")
      data_uri = "data:image/jpeg;base64,#{Base64.strict_encode64(image_data)}"

      response = connection.post(API_PATH) do |req|
        req.headers["Authorization"] = "Basic #{API_TOKEN}"
        req.body = {
          "image.base64": data_uri,
          mode: "test"
        }
      end

      if response.status == 200
        Vips::Image.new_from_buffer(response.body, "")
      else
        warn "Vectorizer API error: Code: #{response.status}, Reason: #{response.reason_phrase}"
        "Error"
      end

    rescue Faraday::Error => e
      warn "Vectorizer API error: #{e.message}"
      raise
    end

    private

    def connection
      @connection ||= Faraday.new(API_ROOT) do |f|
        f.request  :multipart
        f.request  :url_encoded
        f.response :raise_error
        f.adapter  Faraday.default_adapter
      end
    end
  end
end
