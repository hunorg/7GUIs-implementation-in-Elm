module FlightBooker exposing (..)

import Browser
import Html exposing (Html, button, div, input, option, select, text)
import Html.Attributes exposing (disabled, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Tuple3 exposing (..)


type alias Model =
    { flightType : String
    , startDate : String
    , returnDate : String
    , datesValid : Bool
    , flightBooked : Bool
    }


initialModel : Model
initialModel =
    { flightType = "One-way"
    , startDate = "1.1.2023"
    , returnDate = ""
    , datesValid = False
    , flightBooked = False
    }


type Msg
    = FlightTypeChanged String
    | StartDateChanged String
    | ReturnDateChanged String
    | BookFlight


update : Msg -> Model -> Model
update msg model =
    case msg of
        FlightTypeChanged flightType ->
            { model
                | flightType = flightType
                , flightBooked = False
                , datesValid = if model.flightType == "One-way" then isFirstDateBeforeSecond model.startDate model.returnDate else isValidDate model.startDate
            }

        StartDateChanged date ->
            { model | startDate = date, datesValid = isValidDate date && model.flightType == "One-way", flightBooked = False }

        ReturnDateChanged date ->
            { model | returnDate = date, datesValid = isValidDate date && model.flightType == "Return" && isFirstDateBeforeSecond model.startDate date, flightBooked = False }

        BookFlight ->
            if model.datesValid then
                { model | flightBooked = True }

            else
                model


isValidDate : String -> Bool
isValidDate date =
    let
        stringToTuple3 : String -> ( Int, Int, Int )
        stringToTuple3 stringDate =
            let
                stringList =
                    String.split "." stringDate
            in
            case List.map String.toInt stringList of
                [ Just n1, Just n2, Just n3 ] ->
                    ( n1, n2, n3 )

                _ ->
                    ( 0, 0, 0 )

        dateTuple3 =
            stringToTuple3 date
    in
    first dateTuple3 > 0 && first dateTuple3 <= 12 && second dateTuple3 >= 1 && second dateTuple3 <= 31 && third dateTuple3 >= 2023 


isFirstDateBeforeSecond : String -> String -> Bool
isFirstDateBeforeSecond date1 date2 =
    let
        stringToTuple3 : String -> ( Int, Int, Int )
        stringToTuple3 stringDate =
            let
                stringList =
                    String.split "." stringDate
            in
            case List.map String.toInt stringList of
                [ Just n1, Just n2, Just n3 ] ->
                    ( n1, n2, n3 )

                _ ->
                    ( 0, 0, 0 )

        dateFirst =
            stringToTuple3 date1

        dateSecond =
            stringToTuple3 date2
    in
    third dateFirst < third dateSecond || third dateFirst == third dateSecond && first dateFirst < first dateSecond || third dateFirst == third dateSecond && first dateFirst <= first dateSecond && second dateFirst <= second dateSecond


styleInput : String -> String
styleInput date =
    if isValidDate date then
        "white"

    else
        "red"


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ select [ onInput (\value -> FlightTypeChanged value) ]
                [ option [ value "One-way" ] [ text "One-way flight" ]
                , option [ value "Return" ] [ text "Return flight" ]
                ]
            , div []
                [ input
                    [ type_ "text"
                    , onInput StartDateChanged
                    , placeholder "Enter start date (m.d.yyyy)"
                    , style "background-color"
                        (if model.startDate /= "" then
                            styleInput model.startDate

                         else
                            "white"
                        )
                    ]
                    []
                ]
            , div []
                [ input
                    [ disabled (model.flightType == "One-way")
                    , type_ "text"
                    , onInput ReturnDateChanged
                    , placeholder "Enter return date (m.d.yyyy)"
                    , style "background-color"
                        (if model.flightType == "Return" && model.returnDate /= "" then
                            styleInput model.returnDate

                         else
                            "white"
                        )
                    ]
                    []
                ]
            , div []
                [ button [ disabled (not model.datesValid), onClick BookFlight ] [ text "Book Flight" ] ]
            , div []
                [ if model.flightBooked && model.datesValid then
                    text
                        ("You have booked a "
                            ++ (if model.flightType == "One-way" then
                                    "one-way"

                                else
                                    "return"
                               )
                            ++ " flight on "
                            ++ model.startDate
                            ++ (if model.flightType == "Return" then
                                    " and returning on " ++ model.returnDate

                                else
                                    ""
                               )
                        )

                  else
                    text ""
                ]
            ]
        ]


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }
