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
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Fieldset as Fieldset
import Bootstrap.Button as Button
import Bootstrap.Alert as Alert


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
  , fileLoaded: Bool
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
  (Model [] False 0 100 {
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
      ( {model | fileLoaded = False}
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
      ( {model| customers = [], decodeErrors = 0, fileLoaded = True} 
      , Task.perform GotData <| Task.sequence <|
          List.map File.toString (file :: files)
      )

    GotResult (Ok dirtyCustomer) -> -- when json is processed
      ( {model|customers = ({ -- transform dirtyCustomer in customer
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
    [ style "max-width" "50em", style "margin" "auto"]
    [  
      h1 [] [ text "Welcome to the customer filter by distance"]
    , if model.fileLoaded 
        then 
          div [] []
        else 
          Alert.simpleInfo [] [text "Please select a file"] 
    , Form.group []
        [ Form.label [for "distance"] [ text "Max istance in km"]
        , Input.number [ Input.id "distance", Input.value (String.fromFloat model.distance), Input.attrs [ onInput Distance ]  ]
        ]
    , Form.group []
        [ Form.label [for "latitude"] [ text "Starting point latitude"]
        , Input.number [ Input.id "latitude", Input.value (String.fromFloat model.point.latitude), Input.attrs [ onInput Latitude ]  ]
        , Form.label [for "longitude"] [ text "Starting point longitude"]
        , Input.number [ Input.id "longitude", Input.value (String.fromFloat model.point.longitude), Input.attrs [ onInput Longitude ]  ]
        ]
    , Button.button [ Button.primary,  Button.attrs [ onClick Pick ]] [ text "Upload Customers file"  ]
    , if model.decodeErrors == 0 
        then if model.fileLoaded 
          then 
            Alert.simpleLight [] [ text (String.fromInt (List.length model.customers) ++ " customers in the database")]
          else
            div [] []
        else  
          Alert.simpleDanger [] [text ("There are " ++ String.fromInt model.decodeErrors ++ " errors in your uploaded file, leaving " ++ String.fromInt (List.length model.customers) ++ " customers in the database")]
    , let
        filteredCustomers: List Customer
        filteredCustomers = (filterCustomersByDistance model.point model.distance model.customers)
      in
        if List.length filteredCustomers > 0
        then 
        div [] [ 
          Alert.simpleSuccess [] [
            text (String.fromInt (List.length filteredCustomers) ++ " customers within range")
            
          ] 
        , ul
          []
          (List.map viewCustomers filteredCustomers)
        ]
        else if model.fileLoaded 
        then 
          Alert.simpleWarning [] [text "No customers within range"] 
        else 
          div [] []
    ]  

viewCustomers : Customer -> Html msg
viewCustomers customer =
  li
    []
    [text customer.name]

