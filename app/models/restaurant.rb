class Restaurant < ApplicationRecord
  has_one_attached :owner_image do |attachable|
    attachable.variant :lighten, lighten: 0.5
    attachable.variant :face_crop, face_crop: { padding: 0.2 }, preprocessed: true
  end
  has_one_attached :logo do |attachable|
    attachable.variant :vectorized, vectorize: true
  end
  has_one_attached :hero
end
