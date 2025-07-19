require "image_processing"

module ImageProcessing::Vips::AiProcessors
  extend ActiveSupport::Concern

  included do
    def lighten(percentage)
      overlay = image.new_from_image([ 255, 255, 255, (255 * percentage).to_i ])
      image.composite(overlay, :over)
    end

    def face_crop(padding: 0.5)
      puts "Running face crop with padding: #{padding} #{image.format}"
      image_data = image.write_to_buffer(".jpg")
      data_uri = "data:image/jpg;base64,#{Base64.strict_encode64(image_data)}"

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
      image_data = image.write_to_buffer(".jpg")
      data_uri = "data:image/jpg;base64,#{Base64.strict_encode64(image_data)}"

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

    def reframe(aspect_ratio: "4:3", quality: :low, prompt: nil, url:)
      puts "Running reframe with aspect_ratio: #{aspect_ratio}"
      prediction = Replicate.run(
        version: "luma/reframe-image",
        input: {
          image_url: "https://a9832f7c3d7d.ngrok-free.app#{url}",
          aspect_ratio: aspect_ratio,
          model: "photon-1",
          prompt:
        }
        # input: { image: data_uri, model: quality == :low ? "photon-flash-1" : "photon-1", prompt: "", aspect_ratio: }
      )

      # Assuming the response contains a URL to the cropped image
      cropped_image_url = prediction["output"]
      image_data = Down.open(cropped_image_url).read
      Vips::Image.new_from_buffer(image_data, "")
    rescue StandardError => e
      Rails.logger.error("Error during reframe: #{e.message}")
      raise
    end

    def vectorize
      Vectorizer.run(image)
    end
  end
end
