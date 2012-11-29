require 'spec_helper'

describe WMATA do
  context "rail service" do
    it "should return all lines" do
      result = WMATA.rail_lines()
      result.should_not be_empty

      result.length.should eq 5

      result[0].should have_key "DisplayName"
      result[0].should have_key "EndStationCode"
      result[0].should have_key "InternalDestination1"
      result[0].should have_key "InternalDestination2"
      result[0].should have_key "LineCode"
      result[0].should have_key "StartStationCode"
    end

    it "should return all stations" do
      result = WMATA.rail_stations()
      result.should_not be_empty

      result.length.should eq 90

      result[0].should have_key "Code"
      result[0].should have_key "Lat"
      result[0].should have_key "LineCode1"
      result[0].should have_key "LineCode2"
      result[0].should have_key "LineCode3"
      result[0].should have_key "LineCode4"
      result[0].should have_key "Lon"
      result[0].should have_key "Name"
      result[0].should have_key "StationTogether1"
      result[0].should have_key "StationTogether2"
    end

    it "should return all arrivals" do
      result = WMATA.rail_arrivals()
      result.should_not be_empty

      result[0].should have_key "Car"
      result[0].should have_key "Destination"
      result[0].should have_key "DestinationCode"
      result[0].should have_key "DestinationName"
      result[0].should have_key "Group"
      result[0].should have_key "Line"
      result[0].should have_key "LocationCode"
      result[0].should have_key "LocationName"
      result[0].should have_key "Min"
    end

    it "should return all incidents" do
      result = WMATA.rail_incidents()
      unless result.empty?
        result[0].should have_key "DateUpdated"
        result[0].should have_key "DelaySeverity"
        result[0].should have_key "Description"
        result[0].should have_key "EmergencyText"
        result[0].should have_key "EndLocationFullName"
        result[0].should have_key "IncidentID"
        result[0].should have_key "IncidentType"
        result[0].should have_key "LinesAffected"
        result[0].should have_key "PassengerDelay"
        result[0].should have_key "StartLocationFullName"
      end
    end

    it "should return nearest stations" do
      location = { 'lon' => -77.1181486, 'lat' => 38.8852313 } # ava ballston
      result = WMATA.rail_nearest(location['lat'], location['lon'])
      result.should_not be_empty

      result[0].should have_key "Description"
      result[0].should have_key "ID"
      result[0].should have_key "Lat"
      result[0].should have_key "Lon"
      result[0].should have_key "Name"
      result[0].should have_key "StationCode1"
      result[0].should have_key "StationCode2"
    end

    it "should return all entrances for station" do
      station_id = 'K04' # ballston
      result = WMATA.rail_entrances(station_id)
      result.should_not be_empty

      result.each do |r|
        r.should have_key "Description"
        r.should have_key "ID"
        r.should have_key "Lat"
        r.should have_key "Lon"
        r.should have_key "Name"
        r.should have_key "StationCode1"
        r.should have_key "StationCode2"

        # test that station ID is correct
      end
    end
  end

  context "bus service" do
    it "should return all bus routes" do
      result = WMATA.bus_routes()
      result.should_not be_empty

      result.length.should eq 634

      result[0].should have_key "Name"
      result[0].should have_key "RouteID"
    end

    it "should return all bus stops" do
      result = WMATA.bus_stops()
      result.should_not be_empty

      result.length.should eq 11321

      result[0].should have_key "Lat"
      result[0].should have_key "Lon"
      result[0].should have_key "Name"
      result[0].should have_key "Routes"
      result[0].should have_key "StopID"
    end

    it "should return route detail" do
      route_id = "38B"
      result = WMATA.bus_route_details(route_id)
      result.should_not be_empty
      result.length.should eq 2

      result[0].should have_key "DirectionNum"
      result[0].should have_key "DirectionText"
      result[0].should have_key "Shape"
      result[0].should have_key "Stops"
      result[0].should have_key "TripHeadsign"

      result[0]["DirectionText"].should eq "WEST"
      result[0]["TripHeadsign"].should eq "BALLSTON STATION"

      result[1]["DirectionText"].should eq "EAST"
      result[1]["TripHeadsign"].should eq "FARRAGUT SQUARE"
    end

    it "should return all arrivals" do
      stop_id = 6000560 # N Glebe & Washington Blvd
      result = WMATA.bus_arrivals(stop_id)
      result.should_not be_empty

      result[0].should have_key "DirectionNum"
      result[0].should have_key "DirectionText"
      result[0].should have_key "Minutes"
      result[0].should have_key "RouteID"
      result[0].should have_key "VehicleID"
    end

    it "should return fares" do
      result = WMATA.get_rail_fares('Ballston', 'Dupont Circle')
    end
  end
end