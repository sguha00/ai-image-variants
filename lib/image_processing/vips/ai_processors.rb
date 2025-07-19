require "image_processing"

module ImageProcessing::Vips::AiProcessors
  extend ActiveSupport::Concern

  included do
    def lighten(percentage)
      overlay = image.new_from_image([ 255, 255, 255, (255 * percentage).to_i ])
      image.composite(overlay, :over)
    end

    def face_crop(padding: 0.5)
      image_data = image.write_to_buffer(image.format)
      data_uri = "data:image/#{image.format};base64,#{Base64.strict_encode64(image_data)}"

      prediction = Replicate.run(
        version: "23ef97b1c72422837f0b25aacad4ec5fa8e2423e2660bc4599347287e14cf94d",
        input: { image: data_uri, padding: }
      )

      result = prediction["output"]
      image_data = Down.open(result).read
      Vips::Image.new_from_buffer(image_data, "")
    rescue StandardError => e
      Rails.logger.error("Error during face crop: #{e.message}")
      raise
    end

    def remove_bg
      image_data = image.write_to_buffer(image.format)
      data_uri = "data:image/#{image.format};base64,#{Base64.strict_encode64(image_data)}"

      prediction = Replicate.run(
        version: "lucataco/remove-bg:95fcc2a26d3899cd6c2691c900465aaeff466285a65c14638cc5f36f34befaf1",
        input: { image: data_uri }
      )

      # Assuming the response contains a URL to the cropped image
      cropped_image_url = prediction["output"]
      image_data = Down.open(cropped_image_url).read
      Vips::Image.new_from_buffer(image_data, "")
    rescue StandardError => e
      Rails.logger.error("Error during remove_bg: #{e.message}")
      raise
    end

    def reframe_image
    end

    def vectorize
      Vectorizer.run(image)
    end
  end
end
