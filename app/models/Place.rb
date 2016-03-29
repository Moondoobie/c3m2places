class Place
  attr_accessor :id, :formatted_address, :location, :address_components

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

  # read string from file, parse and turn into a ruby hash
  def self.load_all(file)
    json = file.read
    hash=JSON.parse(json)
    self.collection.insert_many(hash)
  end

  def initialize(params={})
    if params
      @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
      #@id = params[:_id].to_s
      @formatted_address = params[:formatted_address]
      @location = Point.new(params[:geometry][:geolocation])

      @address_components = []
      #if !place_hash[:address_components].nil?
        params[:address_components].each do |ac|
          @address_components << AddressComponent.new(ac)
        end
      #end
    end

  end

  def self.find_by_short_name(string_in)
    return self.collection.find(:"address_components.short_name"=>string_in)
    #doc=collection.find(:"address_components.short_name"=>string_in)
    #return doc.nil? ? nil : Place.new(doc)
  end

  def self.to_places input
    r=input.map { |p| Place.new(p) }
  end

  def self.find id
    object_id = BSON::ObjectId.from_string(id) 
    doc = collection.find( :_id => object_id ).first
    return doc.nil? ? nil : Place.new(doc)
  end

end
