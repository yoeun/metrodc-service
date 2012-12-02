class RailPrediction
  attr_accessor :cars, :dest_name, :dest_id, :group, :line_id, :station_id, :minutes

  def to_json(*opt)
    {
      'cars' => @cars,
      'dest_name' => @dest_name,
      'dest_id' => @dest_id,
      'group' => @group,
      'line_id' => @line_id,
      'station_id' => @station_id,
      'minutes' => @minutes,
    }.to_json(*opt)
  end
end