port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, map2, field, string, decodeString)

-- MAIN


main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- PORTS


port messageReceiver : (String -> msg) -> Sub msg

-- MODEL

type alias FacebookAuthInfo =
    { userID : String
    , accessToken : String
    }

type alias Model =
  { facebookAuthInfo : FacebookAuthInfo }


init : () -> ( Model, Cmd Msg )
init _ =
  ( { facebookAuthInfo = FacebookAuthInfo "" "" }
  , Cmd.none
  )

-- UPDATE


type Msg
  = RecvFCToken String
  -- | 


-- Use the `sendMessage` port when someone presses ENTER or clicks
-- the "Send" button. Check out index.html to see the corresponding
-- JS where this is piped into a WebSocket.
--
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    RecvFCToken message ->
      ( { model | facebookAuthInfo = parseFacebookAuthInfo message }
      , Cmd.none
      )

-- SUBSCRIPTIONS


-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--
subscriptions : Model -> Sub Msg
subscriptions _ =
  messageReceiver RecvFCToken



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h1 [] [ text "Facebook Token" ]
    , div [] [text ("Access token " ++ model.facebookAuthInfo.accessToken)]
    , div [] [text ("userID " ++  model.facebookAuthInfo.userID)]
    ]

parseFacebookAuthInfo : String -> FacebookAuthInfo
parseFacebookAuthInfo info =
  case (decodeString decodeFacebookAuthInfo info) of
      Err _ -> FacebookAuthInfo "" ""
      Ok v -> v



decodeFacebookAuthInfo : Decoder FacebookAuthInfo
decodeFacebookAuthInfo =
  map2 FacebookAuthInfo
    (field "userID" string)
    (field "accessToken" string)
