class Place

  PLACE_COLLECTION='places'

  # helper function to obtain connection to server and 
  # set connection to use specific DB called out in mongoid.yml
  def self.mongo_client
    Mongoid::Clients.default
  end

  # helper method to obtain collection used to make race results.
  def self.collection
    collection=ENV['PLACE_COLLECTION'] ||= PLACE_COLLECTION
    return mongo_client[collection]
  end


end
