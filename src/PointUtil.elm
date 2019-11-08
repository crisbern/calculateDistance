module PointUtil exposing (RadiantPoint, GPSPoint, toRadiantPoint, validateLatitude, validateLongitude)

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

validateLatitude: String -> Float
validateLatitude latitude = 
        case (String.toFloat latitude) of
            Nothing ->
                0
            Just existingLatitude ->
                if  existingLatitude < -90
                then
                    -90
                else 
                    if existingLatitude >90 
                    then
                        90
                    else 
                        existingLatitude

validateLongitude: String -> Float
validateLongitude longitude = 
        case (String.toFloat longitude) of
            Nothing ->
                0
            Just existingLongitude ->
                if  existingLongitude < -180
                then
                    -180
                else 
                    if existingLongitude >180 
                    then
                        180
                    else 
                        existingLongitude                        