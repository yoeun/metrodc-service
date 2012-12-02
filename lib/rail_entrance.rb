class RailEntrance
  attr_accessor :name, :id, :stations, :lat, :lon, :desc

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
    }.to_json(*opt)
  end
end