class RailEntrance
  attr_accessor :name, :id, :stations, :lat, :lon, :desc, :station_name

  def initialize
    @stations = []
  end

  def to_json(*opt)
    {
      'name' => @name,
      'id' => @id,
      'desc' => @desc,
      'lat' => @lat,
      'lon' => @lon,
      'stations' => @stations,
      'station_name' => @station_name,
    }.to_json(*opt)
  end
end