class RailLine
  attr_accessor :name, :id, :first_station, :last_station, :stations

  def initialize
    @stations = []
  end
end