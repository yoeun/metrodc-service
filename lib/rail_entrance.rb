class RailEntrance
  attr_accessor :name, :id, :stations, :lat, :lon, :desc

  def initialize
    @stations = []
  end
end