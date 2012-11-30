require 'date'
require 'excon'
require 'json'
require 'nokogiri'

require_relative './bus_route'
require_relative './bus_stop'
require_relative './prediction'
require_relative './rail_line'
require_relative './rail_station'
require_relative './rail_entrance'
require_relative './trip'

class WMATA
  API_KEY = 'wancf3trz46npvzu8mw3xzp8'
  API_URL = 'http://api.wmata.com'

  @@lines = nil
  @@stations = nil
  @@routes = nil
  @@stops = nil
  @@arrivals = {}

  # ====================
  # rail
  # ====================

  def WMATA.lines
    rail_lines if @@lines.nil?
    @@lines
  end

  def WMATA.stations
    rail_stations if @@stations.nil?
    @@stations
  end

  # {
  #   DisplayName: "Red",
  #   EndStationCode: "B11",
  #   InternalDestination1: "A11",
  #   InternalDestination2: "B08",
  #   LineCode: "RD",
  #   StartStationCode: "A15"
  # }
  def WMATA.rail_lines
    result = begin
      response = Excon.get("#{API_URL}/Rail.svc/json/JLines?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/lines.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/lines.json"))
    end

    @@lines = result["Lines"].map do |ln|
      line = RailLine.new
      line.id = ln['LineCode']
      line.name = ln['DisplayName']
      line.first_station = ln['StartStationCode']
      line.last_station = ln['EndStationCode']
      line
    end
  end

  # {
  #   Code: "A03",
  #   Lat: 38.9095980575,
  #   LineCode1: "RD",
  #   LineCode2: null,
  #   LineCode3: null,
  #   LineCode4: null,
  #   Lon: -77.0434143597,
  #   Name: "Dupont Circle",
  #   StationTogether1: "",
  #   StationTogether2: ""
  # }
  def WMATA.rail_stations
    result = begin
      response = Excon.get("#{API_URL}/Rail.svc/json/JStations?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/stations.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/stations.json"))
    end

    @@stations = result["Stations"].map do |st|
      station = RailStation.new
      station.id = st['Code']
      station.name = st['Name']
      station.line_id = st['LineCode1']
      station.lat = st['Lat']
      station.lon = st['Lon']
      station
    end
  end

  def WMATA.rail_stations_for(line_id)
    line = lines.select { |ln| ln.id == line_id }[0]
    line.stations = rail_station_to_station(line.first_station, line.last_station)
  end

  def WMATA.rail_station_to_station(startStation, endStation)
    result = begin
      response = Excon.get("#{API_URL}/Rail.svc/json/JPath?FromStationCode=#{startStation}&ToStationCode=#{endStation}&api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/station_path.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/station_path.json"))
    end

    result["Path"].map do |st|
      station = RailStation.new
      station.id = st['StationCode']
      station.name = st['StationName']
      station.line_id = st['LineCode']
      station
    end
  end

  # {
  #   Car: "6",
  #   Destination: "Shady Gr",
  #   DestinationCode: "A15",
  #   DestinationName: "Shady Grove",
  #   Group: "2",
  #   Line: "RD",
  #   LocationCode: "A02",
  #   LocationName: "Farragut North",
  #   Min: "BRD"
  # }
  def WMATA.rail_arrivals(station_id = "all")
    result = begin
      response = Excon.get("#{API_URL}/StationPrediction.svc/json/GetPrediction/#{station_id}?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/station_predictions.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/station_predictions.json"))
    end
    @@arrivals[station_id] = result["Trains"]
  end

  # {
  #   DateUpdated: "/Date(1353749495000+0000)/",
  #   DelaySeverity: null,
  #   Description: "Orange Line: Expect residual delays in both directions due to an earlier train malfunction outside Deanwood.",
  #   EmergencyText: null,
  #   EndLocationFullName: null,
  #   IncidentID: "1D2F85B5-D9C8-4FE4-8032-6BF7C0262264",
  #   IncidentType: "Delay",
  #   LinesAffected: "OR;",
  #   PassengerDelay: 0,
  #   StartLocationFullName: null
  # }
  def WMATA.rail_incidents
    result = begin
      response = Excon.get("#{API_URL}/Incidents.svc/json/Incidents?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/incidents.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/incidents.json"))
    end
    result["Incidents"]
  end

  # {
  #   Description: "Ballston, Elevator",
  #   ID: "151",
  #   Lat: 38.882353,
  #   Lon: -77.112131,
  #   Name: "Ballston Elevator",
  #   StationCode1: "K04",
  #   StationCode2: ""
  # }
  def WMATA.rail_nearest(lat, lon, radius = 3128)
    result = begin
      response = Excon.get("#{API_URL}/Rail.svc/json/JStationEntrances?lat=#{lat}&lon=#{lon}&radius=#{radius}&api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/station_nearest.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/station_nearest.json"))
    end
    result["Entrances"].map do |e|
      ent = RailEntrance.new
      ent.name = e['Name']
      ent.id = e['ID']
      ent.lat = e['Lat']
      ent.lon = e['Lon']
      ent.desc = e['Description']
      ent.stations.push(e['StationCode1']) unless e['StationCode1'].nil? || e['StationCode1'] == ''
      ent.stations.push(e['StationCode2']) unless e['StationCode2'].nil? || e['StationCode2'] == ''
      ent
    end
  end

  def WMATA.rail_entrances(station_id)
    radius = 805 # in meters (0.5 miles)
    station_id = station_id.upcase
    station = stations.select {|s| s.id == station_id}[0]
    rail_nearest(station.lat, station.lon, radius).select do |e|
      e.stations.include? station_id
    end
  end

  # ====================
  # bus
  # ====================

  def WMATA.routes
    rail_routes if @@routes.nil?
    @@routes
  end

  def WMATA.stops
    rail_stops if @@stops.nil?
    @@stops
  end

  # {
  #   Name: "10:00:00 AM - 10A HUNTING POINT-PEN",
  #   RouteID: "10A"
  # }
  def WMATA.bus_routes
    result = begin
      response = Excon.get("#{API_URL}/Bus.svc/json/JRoutes?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/routes.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/routes.json"))
    end
    @@routes = result["Routes"]
  end

  # {
  #   Lat: 38.832962,
  #   Lon: -77.122586,
  #   Name: "#1801 BEAUREGARD ST",
  #   Routes: [ "7A", "7Av1", "7Av2", "7F", "7Fv1", "7W", "7X" ],
  #   StopID: "4000472"
  # }
  def WMATA.bus_stops
    result = begin
      response = Excon.get("#{API_URL}/Bus.svc/json/JStops?api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/stops.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/stops.json"))
    end
    @@stops = result["Stops"]
  end

  # {
  #   Lat: 38.832962,
  #   Lon: -77.122586,
  #   Name: "#1801 BEAUREGARD ST",
  #   Routes: [ "7A", "7Av1", "7Av2", "7F", "7Fv1", "7W", "7X" ],
  #   StopID: "4000472"
  # }
  def WMATA.bus_nearest(lat, lon, radius = 1500)
    result = begin
      response = Excon.get("#{API_URL}/Bus.svc/json/JStops?lat=#{lat}&lon=#{lon}&radius=#{radius}&api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/stops.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/stops.json"))
    end
    @@stops = result["Stops"]
  end

  # {
  #   DirectionNum: "0",
  #   DirectionText: "WEST",
  #   Shape: [
  #     {
  #       Lat: 38.901529999,
  #       Lon: -77.0385099999,
  #       SeqNum: 1
  #     },
  #     {
  #       Lat: 38.901329999,
  #       Lon: -77.0385099999,
  #       SeqNum: 2
  #     }
  #   ],
  #   Stops: [
  #     {
  #       Lat: 38.901518,
  #       Lon: -77.038603,
  #       Name: "17TH ST (EAST) + I ST NW",
  #       Routes: [ "38B", "38Bv2", "38Bv3", "D5", "G8", "N2", "N4", "N4v1", "N6" ],
  #       StopID: "1001193"
  #     }
  #   ],
  #   TripHeadsign: "BALLSTON STATION"
  # }
  def WMATA.bus_route_details(route_id)
    date = DateTime.now
    result = begin
      response = Excon.get("#{API_URL}/Bus.svc/json/JRouteDetails?routeId=#{route_id}&date=#{date}&api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/route_details.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/route_details.json"))
    end
    details = [result["Direction0"]]
    details.push(result["Direction1"]) unless result["Direction1"].nil?
    details
  end

  # {
  #   DirectionNum: "1",
  #   DirectionText: "East to Farragut Square",
  #   Minutes: 13,
  #   RouteID: "38B",
  #   VehicleID: "2670"
  # }
  def WMATA.bus_arrivals(stop_id)
    result = begin
      response = Excon.get("#{API_URL}/NextBusService.svc/json/JPredictions?StopID=#{stop_id}&api_key=#{API_KEY}")
      response.status == 200 ? JSON.parse(response.body) : JSON.parse(File.read("data/sample/bus_predictions.json"))
    rescue Excon::Errors::SocketError
      JSON.parse(File.read("data/sample/bus_predictions.json"))
    end
    @@arrivals[stop_id] = result["Predictions"]
  end

  # ====================
  # fares
  # ====================

  def WMATA.get_rail_fares(from, to, leaveBy = DateTime.now, arriveBy = nil)
    params = get_fare_params(from, to, leaveBy, arriveBy)
    params['Mode'] = 'R'
    result = get_fares(params)
  end

  def WMATA.get_bus_fares(from, to, leaveBy = DateTime.now, arriveBy = nil)
    params = get_fare_params(from, to, leaveBy, arriveBy)
    params['Mode'] = 'B'
    result = get_fares(params)
  end

  def WMATA.get_fares(params)
    body = parameterize(params)
    html = begin
      response = Excon.post("http://www.wmata.com/rider_tools/tripplanner/tripplanner.cfm", :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}, :body => parameterize(params))
      response.status == 200 ? response.body : File.read('data/sample/fares.html')
    rescue Excon::Errors::SocketError
      File.read('data/sample/fares.html')
    end
    result = WMATA.parse_fare_html(html)
    result
  end

  # ====================
  # helpers
  # ====================

  private

  def WMATA.parameterize(params)
    params.collect{|k,v| "#{k}=#{v}"}.join('&')
  end

  def WMATA.get_fare_params(from, to, leaveBy = DateTime.now, arriveBy = nil)
    the_date = arriveBy.nil? ? leaveBy : arriveBy
    params = {
      'show_email'=>'on',
      'Minimize'=>'T',
      'COOKIES_ALLOWED'=>'yes',
      'Mode' => 'A', # R = Rail, B = Bus, A = All
      'WalkDistance' => 0.75,
      'StreetAddressFrom' => from, # Ballston
      'StreetAddressTo' => to, # Dupont Circle
      'ArrDep' => arriveBy.nil? ? 'D' : 'A',
      'Time' => the_date.strftime('%H:%M'), # 01:23
      'AMPM' => the_date.strftime('%p'), # AM or PM
      'dateMonth' => the_date.strftime('%m'), # 01
      'dateDay' => the_date.strftime('%d'), # 23
      'dateYear' => the_date.strftime('%Y'), # 2012
      'datepicker' => the_date.strftime('%m/%d/%Y') # 01/23/2012
    }
  end

  def WMATA.parse_fare_html(html)
    options = []
    doc = Nokogiri::HTML(html)
    doc.css('.trip_planner.tr').each do |tr|
      trip = {}
      #trip['name'] = tr.css('#top_heading h2').text
      trip['travel_time'] = tr.css('.t_results font').text.match(/(\d+ min?)/)[1]

      trip['steps'] = []
      tr.css('.ltinerary li').each do |i|
        step = {}
        area = i.text
        matches = area.match(/(?:RAIL|BUS) DEPARTS FROM\s*([\w &\-\(\)]+)\s*at\s*(\d{1,2}\:\d{2}[ap]m)\s*BOARD\s*([\w &\-\(\)]+)\s*(RAIL|BUS)\s*towards\s*([\w &\-\(\)]+)\s*ARRIVE\s*([\w &\-\(\)]+)\s*at\s*(\d{1,2}\:\d{2}[ap]m)/i)
        if matches.nil?
          if (area.match(/(To get to next stop:)\s*(.*)/))
            step['walk'] = $2.strip
            step['text'] = $2.strip
          else
            directions = area.sub(/Get directions/, '').strip
            if (directions.match(/(.*)\s+to\s+(.*)/))
              step['walk'] = $1.strip
              step['arrive_name'] = $2.strip
              step['arrive_id'] = 0
              step['text'] = "#{$1.strip} to #{$2.strip}"
            end
          end
        else
          step['depart_name'] = matches[1].strip
          step['depart_id'] = 0
          step['depart_time'] = matches[2].strip
          step['board'] = matches[3].strip
          step['board_id'] = 0
          step['board_type'] = matches[4].strip.upcase
          step['towards'] = matches[5].strip
          step['towards_id'] = 0
          step['arrive_name'] = matches[6].strip
          step['arrive_id'] = 0
          step['arrive_time'] = matches[7].strip
          step['text'] = "From #{matches[1]} at #{matches[2]} board #{matches[3]} (#{matches[4].strip.upcase}) towards #{matches[5]} arrive #{matches[6].strip} at #{matches[7]}"
        end
        trip['steps'].push(step)
      end

      trip['fares'] = {}
      trip['fares']['SmarTrip'] = tr.css('.st_fare .price').text.match(/(\d+\.\d{2})/)[1]

      tr.css('.fares li').each do |f|
        matches = f.text.match(/\$\s+(\d+\.\d{2})\s+(.*)/)
        next if matches.nil?
        trip['fares'][matches[2]] = matches[1]
      end

      options.push(trip)
    end

    options
  end
end