$LOAD_PATH << '.'
require_relative '../services/neighborhoods'

class Restaurant < ActiveRecord::Base
  has_many :dishes
  attr_accessor :this_restaurant

  BANNED_WORDS = ["bar", "drinks", "beverages", "wine", "beer", "vino", "desserts", "dolci", "tea", "coffee", "artiginali", "sweet wine", "port", "grappa", "madeira"]
  include Neighborhoods

  def self.data_dump
    NEIGHBORHOODS.each do |hood,value|
      value.each do |zip|
        response = HTTParty.get("http://api.locu.com/v1_0/venue/search/?api_key=#{ENV['API_KEY']}&postal_code=#{zip}")
        response["objects"].each do |restaurant|
          if (restaurant["has_menu"] == true) && restaurant["categories"].include?("restaurant")
            name = restaurant["name"]
            zip = restaurant["postal_code"]
            this_restaurant = Restaurant.create(name: name,location: "#{zip}")
            menu_id = restaurant["id"]
            this_restaurant.get_dishes(menu_id, this_restaurant)
          end 
        end
      end
    end

  end

  def self.find_restaurant(neighborhood)
    arr = NEIGHBORHOODS[neighborhood.downcase.split(" ").join("_").to_sym]
    list = []
    arr.each do |zip|
      restaurant = Restaurant.where(location: zip)
      list.push(restaurant)
    end
    list
  end


  def get_dishes(menu_id, this_restaurant)
     menus = HTTParty.get("http://api.locu.com/v1_0/venue/#{menu_id}/?api_key=#{ENV['API_KEY']}")
        dish_name = ""
        description = ""
        menus["objects"].each do |menu|
          menu["menus"].each do |sub_menu|
            if BANNED_WORDS.include?(sub_menu["menu_name"].downcase.strip)
              next
            end
            sub_menu["sections"].each do |sub_sub|
              if BANNED_WORDS.include?(sub_sub["section_name"].downcase.strip)
                    next
                end
              sub_sub["subsections"].each do |sub_sec|
                 if BANNED_WORDS.include?(sub_sec["subsection_name"].downcase.strip)
                    next
                end
                sub_sec["contents"].each do |content|
                  dish_name = content["name"]
                  description = content["description"]
                  Dish.create(name: dish_name, description: description, restaurant_id: this_restaurant.id)
                end
              end
            end
          end
        end

  end
end
