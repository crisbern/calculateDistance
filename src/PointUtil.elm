module PointUtil exposing (RadiantPoint, GPSPoint, toRadiantPoint)

type alias RadiantPoint =
  { latitude: Float
  , longitude: Float
  }

type alias GPSPoint =
  { latitude: Float
  , longitude: Float
  }

toRadiantPoint: GPSPoint -> RadiantPoint
toRadiantPoint point =  { 
  latitude= degrees point.latitude
  , longitude= degrees point.longitude
  }