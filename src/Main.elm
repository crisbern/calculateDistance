module Main exposing (..)

import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Task exposing (Task)

import PointUtil exposing (GPSPoint, validateLatitude, validateLongitude)

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
        (   
        case (String.toFloat distance) of
            Nothing ->
                {model | distance = 0}
            Just existingDistance ->
                if existingDistance >= 0 
                then
                    {model | distance = existingDistance}
                else
                    model
        )
      , Cmd.none
      )
     

    Latitude latitude->( 
      { model | point = {latitude = validateLatitude latitude, longitude = model.point.longitude} }
      , Cmd.none
      )

    Longitude longitude -> (
        (   
          { model | point = {latitude = model.point.latitude, longitude = validateLongitude longitude} }  
        )
      , Cmd.none
      )
      
    GotFiles file files -> -- when files are selected
      ( {model|customers = [], decodeErrors = 0} 
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

    GotResult (Err error)  -> ( {model|decodeErrors = model.decodeErrors + 1, customers = ({
      name=D.errorToString error
      , id=0
      , point={
          latitude=0
        , longitude=0
      }} :: model.customers)}, Cmd.none )

    
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
        (List.map viewCustomers model.customers)
    ]  

viewCustomers : Customer -> Html msg
viewCustomers customer =
  li
    []
    [text customer.name]