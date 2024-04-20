port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, map2, field, string, decodeString)
import Http

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

type alias UserInfo =
    { id : String
    , name : String
    }

type alias FacebookAuthInfo =
    { userID : String
    , accessToken : String
    }

type alias Model =
  { facebookAuthInfo : FacebookAuthInfo, userInfo : UserInfo }


init : () -> ( Model, Cmd Msg )
init _ =
  ( { facebookAuthInfo = FacebookAuthInfo "" "", userInfo = UserInfo "" ""  }
  , Cmd.none
  )

-- UPDATE


type Msg
  = RecvFCToken String
  | RequestUserInfo
  | RecvUserInfo (Result Http.Error String)


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
    RequestUserInfo -> (model, getUserInfo model.facebookAuthInfo)
    RecvUserInfo message ->
      case message of
        Ok info -> ( { model | userInfo = parseUserInfo info }
          , Cmd.none
          )
        Err _ -> ( model
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


-- `https://graph.facebook.com/${authResponse.userID}?access_token=${authResponse.accessToken}`

getUserInfo : FacebookAuthInfo -> Cmd Msg
getUserInfo authInfo =
  Http.get
      { url = "https://graph.facebook.com/" ++ authInfo.userID ++ "?access_token=" ++ authInfo.accessToken
      , expect = Http.expectString RecvUserInfo
      }

-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h1 [] [ text "Facebook Token" ]
    , div [] [text ("Access token " ++ model.facebookAuthInfo.accessToken)]
    , div [] [text ("userID " ++  model.facebookAuthInfo.userID)]
    , div [] [text ("User name " ++ model.userInfo.name)]
    , button [onClick RequestUserInfo] [text "getUserInfo"]
    ]

parseFacebookAuthInfo : String -> FacebookAuthInfo
parseFacebookAuthInfo info =
  case (decodeString decodeFacebookAuthInfo info) of
      Err _ -> FacebookAuthInfo "" ""
      Ok v -> v

parseUserInfo : String -> UserInfo
parseUserInfo info =
  case (decodeString decodeUserInfo info) of
      Err _ -> UserInfo "" ""
      Ok v -> v



decodeFacebookAuthInfo : Decoder FacebookAuthInfo
decodeFacebookAuthInfo =
  map2 FacebookAuthInfo
    (field "userID" string)
    (field "accessToken" string)

decodeUserInfo : Decoder UserInfo
decodeUserInfo =
  map2 UserInfo
    (field "id" string)
    (field "name" string)
