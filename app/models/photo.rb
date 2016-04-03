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
        grid_file = Mongo::Grid::File.new(@contents.read, description)
      	id=self.class.mongo_client.database.fs.insert_one(grid_file)
      	@id=id.to_s
      	@contents.rewind
      end
      
      # use the exifr gem to extract geolocation information from the jpeg image.
      # store the content type of image/jpeg in the GridFS contentType file property.
      # store the GeoJSON Point format of the image location in the GridFS metadata file 
      # property and the object in class location property.
      # store the data contents in GridFS
      # store the generated _id for the file in the :id property of the Photo model instance

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


end
