class Point

  attr_accessor :longitude, :latitude

  def initialize(params={})

    @type="Point"
    if params[:coordinates]
      @longitude=params[:coordinates][0]
      @latitude=params[:coordinates][1]
    else 
      @longitude=params[:lng]
      @latitude=params[:lat]
    end	

  end

  #GeoJSON Point format
  # {"type":"Point", "coordinates":[ -1.8625303, 53.8256035]}
  # {"lat":53.8256035, "lng":-1.8625303}

  def to_hash
  	hash = { :type => "Point", :coordinates=>[@longitude,@latitude]}
  end


end
