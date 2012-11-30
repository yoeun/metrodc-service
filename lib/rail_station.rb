class RailStation
  attr_accessor :name, :id, :entrances, :line_id, :lat, :lon

  def initialize
    @lat = 0
    @lon = 0
    @entrances = []
  end
end