class RailLine
  attr_accessor :name, :id, :first_station, :last_station, :stations

  def initialize
    @stations = []
  end

  def to_json(*opt)
    {
      'name' => @name,
      'id' => @id,
      'first_station' => @first_station,
      'last_station' => @last_station,
      'stations' => @stations,
    }.to_json(*opt)
  end
end