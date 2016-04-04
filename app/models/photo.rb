class Photo
	attr_accessor :id, :location
	attr_writer :contents

  def self.mongo_client
    Mongoid::Clients.default
  end

  def initialize(params={})
    if params
      @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
      if (params[:metadata] && params[:metadata][:location])
        @location = Point.new(params[:metadata][:location])
      end
    end
  end

  # tell Rails whether this instance is persisted
  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      gps=EXIFR::JPEG.new(@contents).gps
      @location=Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
      description = {}
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      description[:metadata][:location] = @location.to_hash

      if @contents
      	@contents.rewind
        grid_file = Mongo::Grid::File.new(@contents.read, description)
      	id=self.class.mongo_client.database.fs.insert_one(grid_file)
      	@id=id.to_s      	
      end
      
      # use the exifr gem to extract geolocation information from the jpeg image.
      # store the content type of image/jpeg in the GridFS contentType file property.
      # store the GeoJSON Point format of the image location in the GridFS metadata file 
      # property and the object in class location property.
      # store the data contents in GridFS
      # store the generated _id for the file in the :id property of the Photo model instance
    else

      dt = Photo.mongo_client.database.fs
      object_id = BSON::ObjectId.from_string(@id) 
 
      dt.find(:_id=> object_id).update_one(:$set=>{:metadata=>{:location => @location.to_hash}})	
    end
  end

  
  def self.all(offset=0, limit=nil)
    dt = Photo.mongo_client.database.fs

    if !limit.nil? 
      d = dt.find.skip(offset).limit(limit).map { |p| Photo.new(p) } 
  	else
      d = dt.find.skip(offset).map { |p| Photo.new(p) } 
  	end
  	
  	return d
  end

  def self.find(id)
  	dt = Photo.mongo_client.database.fs
    object_id = BSON::ObjectId.from_string(id) 
    doc = dt.find( :_id => object_id ).first
    return doc.nil? ? nil : Photo.new(doc)
  end

  def contents
    f=self.class.mongo_client.database.fs.find_one(id_criteria)
    if f 
      buffer = ""
      f.chunks.reduce([]) do |x,chunk| 
          buffer << chunk.data.data 
      end
      return buffer
    end 
  end

  def self.id_criteria id
    {_id:BSON::ObjectId.from_string(id)}
  end


  def id_criteria
    self.class.id_criteria @id
  end

  def destroy
    self.class.mongo_client.database.fs.find(id_criteria).delete_one
  end
  
  # returns the _id of the document within the places collection
  def find_nearest_place_id(max_meters)
    places = Place.near(@location, max_meters).projection(_id:true).limit(1)

    if (places && places.count>0)
      places.first[:_id]
    else
  	  nil
    end

    # limit the result to only the nearest matching place (Hint: limit())
    # limit the result to only the _id of the matching place document (Hint: projection())
    # returns zero or one BSON::ObjectIds for the nearby place found
  end


end
