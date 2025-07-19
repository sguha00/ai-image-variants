json.extract! restaurant, :id, :owner_image, :logo, :hero, :created_at, :updated_at
json.url restaurant_url(restaurant, format: :json)
json.owner_image url_for(restaurant.owner_image)
json.logo url_for(restaurant.logo)
json.hero url_for(restaurant.hero)
