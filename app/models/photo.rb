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
end
