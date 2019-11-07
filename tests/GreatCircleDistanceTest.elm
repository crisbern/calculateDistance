module GreatCircleDistanceTest exposing (..)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import GreatCircleDistance exposing (greatCircleDistance, earthCircleDistance)


suite : Test
suite =
    describe "The great circle distance module"
    [describe "greatCircleDistance with radius 1"
        [ test "has no distance between the same point" <|
            \_ ->
                let
                    point = 
                        {
                            latitude = 10
                            , longitude = -50
                        }
                in
                    Expect.equal (greatCircleDistance 1 point point) 0
        ]
    ,describe "earthCircleDistance"
        [ 
        test "has 41km distance between office and first point" <|
            \_ ->
                    Expect.within (Absolute 0.01) 
                        ( 
                            earthCircleDistance
                            {
                                latitude= 53.339428
                            , longitude= -6.257664
                            } 
                            {
                                latitude= 52.986375
                            , longitude= -6.043701
                            })
                        41.77
        ,
        test "has 1600km distance between Dublin and Udine" <|
            \_ ->
                    Expect.within (Absolute 0.1) 
                        ( 
                            earthCircleDistance
                            {
                                latitude= 53.339428
                            , longitude= -6.257664
                            } 
                            {
                                latitude= 46.056041
                            , longitude= 13.1741226
                            })
                        1607.61
        ]
    ]
