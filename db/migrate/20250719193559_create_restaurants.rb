class CreateRestaurants < ActiveRecord::Migration[8.0]
  def change
    create_table :restaurants do |t|

      t.timestamps
    end
  end
end
