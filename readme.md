REST API for DC metro data. Abstracts standard WMATA REST API by normalising data field, adding additional meta-data and adding support for caching.

# Rail

    GET /1/rail/lines
    GET /1/rail/stations
    GET /1/rail/lines/:line_id/stations
    GET /1/rail/stations/:station_id/arrivals
    GET /1/rail/stations/:station_id/entrances
    GET /1/rail/stations/nearest/:lat/:lon
    GET /1/rail/fares/:from/:to/:leave_by?/:arrive_by?

# Bus

    GET /1/bus/routes
    GET /1/bus/routes/:route_id/stops
    GET /1/bus/stops/:stop_id/arrivals
    GET /1/bus/stops/nearest/:lat/:lon
    GET /1/bus/fares/:from/:to/:leave_by?/:arrive_by?