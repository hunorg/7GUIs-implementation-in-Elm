module Counter exposing (..)

import Browser
import Html exposing (Html, button, text)
import Html.Events exposing (onClick)

type Msg = Increment

type alias Model = Int

initialModel : Model
initialModel = 0

update : Msg -> Model -> Model
update msg model =
  case msg of
    Increment ->
      model + 1

view : Model -> Html Msg
view model =
  Html.div []
    [ text (String.fromInt model)
    , button [onClick Increment ] [ Html.text "Increment" ]
    ]

main : Program () Model Msg
main =
  Browser.sandbox
    { init = initialModel
    , view = view
    , update = update 
    }
