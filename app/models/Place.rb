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

  # def self.load_hash(file_path) 
  #   file=File.read(file_path)
  #   JSON.parse(file)
  # end

  # def load_collection(file_path) 
  #   hash=self.class.load_hash(file_path)
  #   @coll.insert_many(hash)
  # end


  def self.load_all(file)
    json = file.read
    hash=JSON.parse(json)
    self.collection.insert_many(hash)
  end

end
