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
      if !params[:address_components].nil?
        params[:address_components].each do |ac|
          @address_components << AddressComponent.new(ac)
        end
      end
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

  def self.find(id)
    object_id = BSON::ObjectId.from_string(id) 
    doc = collection.find( :_id => object_id ).first
    return doc.nil? ? nil : Place.new(doc)
  end

  def self.all(offset=0, limit=0)
    return collection.find.skip(offset).limit(limit).map { |p| Place.new(p) }
  end

  def destroy
    self.class.collection
              .find(:_id => BSON::ObjectId.from_string(@id))
              .delete_one
  end

  def self.get_address_components(sort=nil, offset=0, limit=nil)
    pipeline = []
    pipeline << {:$unwind=>'$address_components'}
    pipeline << {:$project=>{ :_id=>1, :address_components=>1, :formatted_address=>1, :"geometry.geolocation"=>1}}
    pipeline << {:$sort=> sort } if !sort.nil?
    pipeline << {:$skip=> offset }
    pipeline << {:$limit=> limit } if !limit.nil?

    return self.collection.find.aggregate(pipeline)                                     
                                    
    # returns a collection of hash documents with address_components 
    # and their associated _id, formatted_address and location properties
  end

  def self.get_country_names
    pipeline = []
    pipeline << {:$unwind=>'$address_components'}
    pipeline << {:$unwind=>'$address_components.types'}
    pipeline << {:$match =>{:"address_components.types" =>'country'}}
    pipeline << {:$project=>{:_id=>0, :address_components=>{:long_name =>1,:types=>1}}}
    pipeline << {:$group=> {:_id => '$address_components.long_name'}}

    result = self.collection.find.aggregate(pipeline)
    return result.to_a.map {|h| h[:_id]}  
  end

  def self.find_ids_by_country_code(code)
    pipeline = []
    pipeline << {:$match =>{:"address_components.types" =>'country'}}
    pipeline << {:$match =>{:"address_components.short_name" => code }}  
    pipeline << {:$project=>{:_id=>1 }}
  
    result = self.collection.find.aggregate(pipeline)
    return result.to_a.map {|doc| doc[:_id].to_s}

    # will return the id of each document in the places collection that has an 
    # address_component.short_name of type country and matches the provided parameter
  end

  # create a 2dsphere index to your collection for the geometry.geolocation property
  def self.create_indexes
    self.collection.indexes.create_one({ :"geometry.geolocation"=>Mongo::Index::GEO2DSPHERE })
  end
  
  # remove a 2dsphere index to your collection for the geometry.geolocation property
  def self.remove_indexes
    self.collection.indexes.drop_one("geometry.geolocation_2dsphere")
  end

  def self.near(pt, max_meters=nil)    
    pt_hash = pt.to_hash   

    if !max_meters.nil?
      self.collection.find(
          :"geometry.geolocation"=>{:$near=>{
            :$geometry=>pt_hash, 
            :$maxDistance=>max_meters }}
          )
    else
      self.collection.find(
          :"geometry.geolocation"=>{:$near=>{
            :$geometry=>pt_hash }}
          )
    end

    #:$geometry=>{:type=>"Point",:coordinates=>[@longitude,@latitude]}, 
    # returns places that are closest to the provided Point
  end


  def near(max_dist=nil)

    if (max_dist.nil?)
      pnear = self.class.near(@location)
    else
      pnear = self.class.near(@location, max_dist)
    end

    self.class.to_places(pnear)

  end


end


















