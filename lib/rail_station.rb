class RailStation
  attr_accessor :name, :id, :line_id, :lat, :lon, :entrances

  def initialize
    @lat = 0
    @lon = 0
    @entrances = []
  end

  def to_json(*opt)
    {
      'name' => @name,
      'id' => @id,
      'line_id' => @line_id,
      'lat' => @lat,
      'lon' => @lon,
      'entrances' => @entrances,
    }.to_json(*opt)
  end
end