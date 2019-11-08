module Main exposing (..)

import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Task exposing (Task)

import PointUtil exposing (..)
import GreatCircleDistance exposing (earthCircleDistance)

-- MAIN
-- this is where everything starts

main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL
-- model shape (similar to state in React)
type alias Model =
  { 
    customers : List Customer
  , decodeErrors: Int
  , distance: Float
  , point: GPSPoint
  }


type alias Customer =
  { point: GPSPoint
  , id: Int
  , name: String
  }

-- DirtyCustomer is needed because lat/lon are string in the API
-- They could be Float and there would not be need of parsing
type alias DirtyCustomer = 
  { latitude: String
  , longitude: String
  , user_id: Int
  , name: String
  }

init : () -> (Model, Cmd Msg)
init _ =
  (Model [] 0 100 {
      latitude= 53.339428
    , longitude=-6.257664
    }, Cmd.none) -- initial values no customers, 100km, Intercom GPS


-- UPDATE
-- what happens when something changes
type Msg
  = Pick
  | GotFiles File (List File)
  | GotData (List String)
  | GotResult (Result D.Error (DirtyCustomer))
  | Distance String
  | Latitude String
  | Longitude String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Pick -> -- when the select file is pressed
      ( model
      , Select.files ["text/*"] GotFiles
      )

    Distance distance -> (  
      {model | distance = validateDistance distance}
      , Cmd.none
      )
     
    Latitude latitude->( 
      { model | point = {latitude = validateLatitude latitude, longitude = model.point.longitude} }
      , Cmd.none
      )

    Longitude longitude -> (
      { model | point = {latitude = model.point.latitude, longitude = validateLongitude longitude} }  
      , Cmd.none
      )
      
    GotFiles file files -> -- when files are selected
      ( {model| customers = [], decodeErrors = 0} 
      , Task.perform GotData <| Task.sequence <|
          List.map File.toString (file :: files)
      )

    GotResult (Ok dirtyCustomer) -> -- when json is processed
      ( {model|customers = ({
        name=dirtyCustomer.name
      , id=dirtyCustomer.user_id
      , point={
                latitude=validateLatitude dirtyCustomer.latitude
              , longitude=validateLongitude dirtyCustomer.longitude
              }
      } :: model.customers)}, Cmd.none )

    GotResult (Err error)  -> ( {model|decodeErrors = model.decodeErrors + 1}, Cmd.none )

    GotData content -> -- when files are processed
      (model, Cmd.batch (List.map decodeCustomer (List.concat (List.map  (String.lines) content ))))


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- DECODERS            

decodeCustomer: String -> Cmd Msg
decodeCustomer json = Task.succeed 
 (GotResult (D.decodeString customerDecoder json))
 |> Task.perform identity        

customerDecoder: D.Decoder DirtyCustomer
customerDecoder  =  D.map4 DirtyCustomer 
    (D.at ["latitude"] D.string)   
    (D.at ["longitude"] D.string) 
    (D.at ["user_id"] D.int) 
    (D.at ["name"] D.string) 

-- filter
filterCustomersByDistance: GPSPoint -> Float -> List Customer -> List Customer
filterCustomersByDistance  startingPoint distance customerData =
    let 
        isWithinRange: Customer -> Bool
        isWithinRange customer = (earthCircleDistance startingPoint customer.point)  <= distance
    in
    customerData
    |> List.filter isWithinRange
    |> List.sortBy .id


-- VIEW

view : Model -> Html Msg
view model =
  div
    [ ]
    [  
      input [  type_ "number", placeholder "Max distance", value (String.fromFloat model.distance), onInput Distance][]
    , input [  type_ "number", placeholder "Latitude", value (String.fromFloat model.point.latitude), onInput Latitude][]
    , input [  type_ "number", placeholder "Logitude", value (String.fromFloat model.point.longitude), onInput Longitude][]
    , button [ onClick Pick ] [ text "Upload Customers file" ]
    , div [] [text (String.fromInt model.decodeErrors)]
    , ul
        []
        (List.map viewCustomers (filterCustomersByDistance model.point model.distance model.customers))
    ]  

viewCustomers : Customer -> Html msg
viewCustomers customer =
  li
    []
    [text customer.name]
