module TemperatureConv exposing (..)

import Browser
import Html exposing (Html, input, text)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput)
import String


type Msg
    = CelsiusChanged String
    | FahrenheitChanged String


type alias Model =
    { celsius : String, fahrenheit : String }


initialModel : Model
initialModel =
    { celsius = "", fahrenheit = "" }


update : Msg -> Model -> Model
update msg model =
    case msg of
        CelsiusChanged celsius ->
            { model | celsius = celsius, fahrenheit = convertCelsiusToFahrenheit celsius }

        FahrenheitChanged fahrenheit ->
            { model | fahrenheit = fahrenheit, celsius = convertFahrenheitToCelsius fahrenheit }


convertCelsiusToFahrenheit : String -> String
convertCelsiusToFahrenheit celsius =
    case String.toFloat celsius of
        Just c ->
            String.fromFloat (c * 9 / 5 + 32)

        Nothing ->
            ""


convertFahrenheitToCelsius : String -> String
convertFahrenheitToCelsius fahrenheit =
    case String.toFloat fahrenheit of
        Just f ->
            String.fromFloat ((f - 32) * 5 / 9)

        Nothing ->
            ""


view : Model -> Html Msg
view model =
    Html.div []
        [ input [ onInput CelsiusChanged, value model.celsius ] []
        , text "°C"
        , text " = "
        , input [ onInput FahrenheitChanged, value model.fahrenheit ] []
        , text "°F"
        ]


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }
