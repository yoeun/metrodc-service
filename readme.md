REST API for DC metro data. Abstracts standard WMATA REST API by normalising data field, adding additional meta-data and adding support for caching.

# Support

    GET /1/has_updates
    GET /1/updates
    GET /1/feed

    GET /1/user
    POST /1/user/:user_id
    PUT /1/user/:user_id
    DELETE /1/user/:user_id
    GET /1/user/:user_id/restore

# Rail

    GET /1/rail/lines
    GET /1/rail/stations
    GET /1/rail/lines/:line_id/stations
    GET /1/rail/lines/:line_id/feed
    GET /1/rail/stations/:station_id/arrivals
    GET /1/rail/stations/:station_id/entrances
    GET /1/rail/stations/nearest/:lat/:lon
    GET /1/rail/fares/:from/:to/:leave_by?/:arrive_by?
    GET /1/rail/stations/:station_id/feed

# Bus

    GET /1/bus/routes
    GET /1/bus/routes/:route_id/stops
    GET /1/bus/stops/:stop_id/arrivals
    GET /1/bus/stops/nearest/:lat/:lon
    GET /1/bus/fares/:from/:to/:leave_by?/:arrive_by?

# Architecture

* JSON REST API
* Raw data from WMATA API, Twitter and RSS feed are organised, tagged, cached and filtered
  * Make data relational
* All data is cached, even if for 30 seconds for arrivals
  * Minimise REST calls to WMATA API
* All data is versioned to determine if client is out of date relative to server
  * In other words, silver line is now active
  * Versioned data:
    * Lines
    * Stations
    * Routes
    * Stops
    * News feed
  * Non-versioned data (these should always get latest)
    * Arrivals
    * Trip planner
* Apps should be able to quickly ping server for updates
  * Client sends server list of versions of all components
  * Server returns list of components that need to be updated
  * To minimise toom many network connections on mobile, allow collection of REST calls per HTTP request
* Server response should be gzipped
* News feed is all-in-one Twitter and RSS feed of incidents, alerts and advisories
  * Contains meta-data for affected line/station/route/stop
* User settings
  * Allow user accounts
  * Allow users to save stations/stops/trips
  * Allow user to restore these settings on new device