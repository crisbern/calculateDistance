module GreatCircleDistance exposing (greatCircleDistance, earthCircleDistance)
import PointUtil exposing (RadiantPoint, GPSPoint, toRadiantPoint)

longitudeAbsDifference:RadiantPoint -> RadiantPoint -> Float
longitudeAbsDifference point1 point2 = abs (point1.longitude-point2.longitude)

numerator : RadiantPoint -> RadiantPoint -> Float
numerator point1 point2  = (cos point2.latitude * sin (longitudeAbsDifference point1 point2))^2+((cos point1.latitude * sin point2.latitude)-(sin point1.latitude * cos point2.latitude * cos (longitudeAbsDifference point1 point2 )))^2

denominator : RadiantPoint -> RadiantPoint -> Float
denominator point1 point2  = (sin point1.latitude * sin point2.latitude) + (cos point1.latitude * cos point2.latitude * cos (longitudeAbsDifference point1 point2 ) ) 

arcLength: RadiantPoint -> RadiantPoint -> Float
arcLength point1 point2 =  atan ((sqrt (numerator point1 point2)) / denominator point1 point2)

greatCircleDistance: Float -> GPSPoint -> GPSPoint -> Float
greatCircleDistance radius point1 point2 = radius * (arcLength (toRadiantPoint point1) (toRadiantPoint point2) )

earthCircleDistance: GPSPoint -> GPSPoint -> Float
earthCircleDistance point1 point2 = greatCircleDistance 6371 point1 point2 -- in kilometres


