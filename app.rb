require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'

require 'date'
require 'json'
require 'memcache'

require './lib/wmata'

class App < Sinatra::Base
  EXP_HOUR = 60*60
  EXP_DAY = 60*60*24

  def initialize
    super()

    @cache = MemCache.new 'localhost:11211'
  end

  get '/' do
    "MetroDC API 1.0"
  end

  # ====================
  # rail
  # ====================

  # return list of all rail lines
  get '/rail/lines' do
    result = from_cache('/rail/lines', EXP_DAY*7) do
      WMATA.rail_lines
    end

    as_response(result)
  end

  # return list of all stations by line
  get '/rail/lines/:line_id/stations' do
    result = from_cache('/rail/stations', EXP_DAY*7) do
      WMATA.rail_stations
    end

    line_id = params[:line_id].upcase
    stations = result.select do |s|
      s["LineCode1"] == line_id ||
      s["LineCode2"] == line_id ||
      s["LineCode3"] == line_id ||
      s["LineCode4"] == line_id
    end

    as_response(stations)
  end

  # return list of all stations
  get '/rail/stations' do
    result = from_cache('/rail/stations', EXP_DAY*7) do
      WMATA.rail_stations
    end

    as_response(result)
  end

  # return list of all stations by location
  get '/rail/stations/:station_id/entrances' do
    as_error(500, "Not implemented")
  end

  # return list of arrival times by station ID
  get '/rail/stations/:station_id/arrivals' do
    station_id = params[:station_id].upcase

    result = from_cache("/rail/arrivals", 30) do
      WMATA.rail_arrivals
    end

    arrivals = result.select do |a|
      a["LocationCode"] == station_id
    end

    as_response(arrivals)
  end

  # return list of all stations by location
  get '/rail/stations/nearest/:lat/:lon' do
    result = WMATA.rail_nearest(params[:lat], params[:lon])
    as_response(result)
  end

  get '/rail/fares/:from/:to/:leave_by?/:arrive_by?' do
    from = params[:from]
    to = params[:to]
    leave_by = params[:leave_by].nil? ? nil : DateTime.parse(params[:leave_by])
    arrive_by = params[:arrive_by].nil? ? nil : DateTime.parse(params[:arrive_by])
    result = WMATA.get_rail_fares(from, to, leave_by, arrive_by)
    as_response(result)
  end

  # ====================
  # bus
  # ====================

  # return list of all bus routes
  get '/bus/routes' do
    result = from_cache('/bus/routes', EXP_DAY*7) do
      WMATA.bus_routes
    end

    as_response(result)
  end

  # return list of all bus stops
  get '/bus/routes/:route_id/stops' do
    result = from_cache('/bus/stops', EXP_DAY*7) do
      WMATA.bus_stops
    end

    as_response(result)
  end

  get '/bus/stops/:stop_id/arrivals' do
    stop_id = params[:stop_id]
    result = from_cache('/rail/arrivals', 30) do
      WMATA.bus_arrivals(stop_id)
    end

    as_response(result)
  end

  get '/bus/fares/:from/:to/:leave_by?/:arrive_by?' do
    from = params[:from]
    to = params[:to]
    leave_by = params[:leave_by].nil? ? nil : DateTime.parse(params[:leave_by])
    arrive_by = params[:arrive_by].nil? ? nil : DateTime.parse(params[:arrive_by])
    result = WMATA.get_bus_fares(from, to, leave_by, arrive_by)
    as_response(result)
  end

  # ====================
  # user
  # ====================

  # save user
  post '/users' do
    200
  end

  # update user
  put '/users/:user_id' do
    200
  end

  # delete user
  delete '/users/:user_id' do
    200
  end

  # ====================
  # saved trips
  # ====================

  # return list of saved trips
  get '/users/:user_id/trips' do
    # get list of saved rail and bus
  end

  # save trip
  post '/users/:user_id/trips' do
    200
  end

  # update trip
  put '/users/:user_id/trips/:trip_id' do
    200
  end

  # delete trip
  delete '/users/:user_id/trips/:trip_id' do
    200
  end

  # ====================
  # helper methods
  # ====================

  def from_cache(key, expires)
    begin
      result = @cache.get(key)
      if result.nil?
        puts "Cache miss: #{key}"
        result = yield
        @cache.add(key, result, expires)
      end
      result
    rescue MemCache::MemCacheError
      puts "Cache miss: #{key}"
      result = yield
    end
  end

  def as_response(data)
    {
      "error" => nil,
      "data" => data
    }.to_json
  end

  def as_error(code, msg)
    {
      "data" => nil,
      "error" => {
        "code" => code,
        "message" => msg
      }
    }.to_json
  end
end