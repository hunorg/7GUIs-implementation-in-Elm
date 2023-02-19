module Timer exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes as Attr exposing (step, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Time


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { value : Int
    , timeRemaining : Int
    }


initialModel : Model
initialModel =
    { value = 0
    , timeRemaining = 0
    }



-- UPDATE


type Msg
    = SliderValueChanged Int
    | TimerTick Int
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SliderValueChanged value ->
            ( { model | value = value, timeRemaining = value }, Cmd.none )

        TimerTick _ ->
            if model.timeRemaining > 0 then
                ( { model | timeRemaining = model.timeRemaining - 1 }, Cmd.none )

            else
                ( model, Cmd.none )

        Reset ->
            ( initialModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions model =
    if model.timeRemaining > 0 then
        Time.every 1000 (\_ -> TimerTick model.timeRemaining)

    else
        Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ text "Elapsed time: "
            , div [ style "background-color" "black", style "height" "20px", style "width" "100px" ]
                [ div [ style "background-color" "blue", style "height" "20px", style "width" (String.fromInt (if model.timeRemaining == model.value then 0 else floor (toFloat (model.value - model.timeRemaining) / toFloat model.value * 100)) ++ "px") ] []
                ]
         , div [] [ text (String.fromFloat (toFloat model.value - toFloat model.timeRemaining) ++ " s") ]
        , div []
            [ text "Duration: " ]
        , div [] 
            [ Html.input
                [ type_ "range"
                , Attr.min "0"
                , Attr.max "100"
                , step "1"
                , style "width" "100px"
                , value (String.fromInt model.value)
                , onInput (\v -> SliderValueChanged (Maybe.withDefault 0 (String.toInt v)))
                ]
                []
            ]
            , div [] [ button [ onClick Reset ] [ text "Reset" ] ]
            ]
        ]
