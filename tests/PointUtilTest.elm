module PointUtilTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import PointUtil exposing (RadiantPoint, GPSPoint, toRadiantPoint)


suite : Test
suite =
    describe "The point utility"
    [describe "toRadiantPoint"
        [ test "transforms a (0,0) GPS point to a (0,0) Radiant" <|
            \_ ->
                let
                    testGPSPoint = 
                        {
                            latitude = 0
                            , longitude = 0
                        }
                in
                    Expect.equal (toRadiantPoint testGPSPoint) {
                        latitude = 0
                        , longitude = 0
                    }
        ,test "transforms a (90,90) GPS point to a (pi/2,pi/2) Radiant" <|
            \_ ->
                let
                    testGPSPoint = 
                        {
                            latitude = 90
                            , longitude = 90
                        }
                in
                    Expect.equal (toRadiantPoint testGPSPoint) {
                        latitude = pi/2
                        , longitude = pi/2
                    }
        ,test "transforms a (-90,-90) GPS point to a (-pi/2,-pi/2) Radiant" <|
            \_ ->
                let
                    testGPSPoint = 
                        {
                            latitude = -90
                            , longitude = -90
                        }
                in
                    Expect.equal (toRadiantPoint testGPSPoint) {
                        latitude = -pi/2
                        , longitude = -pi/2
                    }
        ,test "transforms a (180,180) GPS point to a (pi,pi) Radiant" <|
            \_ ->
                let
                    testGPSPoint = 
                        {
                            latitude = 180
                            , longitude = 180
                        }
                in
                    Expect.equal (toRadiantPoint testGPSPoint) {
                        latitude = pi
                        , longitude = pi
                    }
        ,test "transforms a (540,-540) GPS point to a (3*pi,-3pi) Radiant" <|
            \_ ->
                let
                    testGPSPoint = 
                        {
                            latitude = 540
                            , longitude = -540
                        }
                in
                    Expect.equal (toRadiantPoint testGPSPoint) {
                        latitude = 3*pi
                        , longitude = -3*pi
                    }
        ]
    ]
