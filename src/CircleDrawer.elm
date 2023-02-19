module CircleDrawer exposing (..)

import Browser
import Color
import Html exposing (Html, button, div, input, text)
import Html.Attributes as Attr exposing (step, style, type_, value)
import Html.Events exposing (onClick, onInput, onMouseUp)
import Html.Events.Extra.Mouse as Mouse
import List.Extra exposing (unique)
import TypedSvg exposing (circle, svg)
import TypedSvg.Attributes exposing (cx, cy, fill, height, r, stroke, width)
import TypedSvg.Types exposing (Paint(..), px)


type alias Model =
    { circles : List Circle
    , selected : Maybe Circle
    , showSlider : Bool
    , sliderValue : Float
    , lastSelected : Circle
    , undoStack : List Action
    , redoStack : List Action
    }


type Action
    = AddCircle Circle
    | ChangeDiameter Circle Circle


initialModel : Model
initialModel =
    { circles = []
    , selected = Nothing
    , showSlider = False
    , sliderValue = 0
    , lastSelected = { id = 0, x = 0, y = 0, r = 0 }
    , undoStack = []
    , redoStack = []
    }


relativePos : Mouse.Event -> ( Float, Float )
relativePos mouseEvent =
    mouseEvent.offsetPos


type alias Circle =
    { id : Int, x : Float, y : Float, r : Float }


type Msg
    = DownMsg Mouse.Button ( Float, Float )
    | HoverMsg ( Float, Float )
    | RightClickMsg ( Float, Float )
    | SliderValueChanged Float
    | UpdateCircles
    | ClickedX
    | Undo
    | Redo


viewCircles : Maybe Circle -> List Circle -> List (Html Msg)
viewCircles maybeSelected circles =
    List.map
        (\c ->
            let
                attrs =
                    [ cx (px c.x)
                    , cy (px c.y)
                    , r (px c.r)
                    , stroke (Paint Color.white)
                    ]
            in
            if Just c == maybeSelected then
                circle (attrs ++ [ fill (Paint Color.gray) ]) []

            else
                circle attrs []
        )
        circles


update : Msg -> Model -> Model
update msg model =
    case msg of
        DownMsg button clientPos ->
            if button == Mouse.MainButton then
                let
                    circle =
                        { id = List.length model.circles
                        , x = Tuple.first clientPos
                        , y = Tuple.second clientPos - 25
                        , r = 20
                        }

                    newCircles =
                        circle :: model.circles
                in
                { model
                    | circles = unique newCircles
                    , undoStack = AddCircle circle :: model.undoStack
                }

            else
                model

        HoverMsg clientPos ->
            let
                distanceTo c =
                    sqrt ((c.x - Tuple.first clientPos) ^ 2 + (c.y - Tuple.second clientPos) ^ 2)

                maybeSelected =
                    List.filter (\c -> distanceTo c < c.r) model.circles
                        |> List.sortBy (\c -> distanceTo c)
                        |> List.head
            in
            { model | selected = maybeSelected }

        RightClickMsg clientPos ->
            let
                isOnSelected =
                    case model.selected of
                        Just selected ->
                            let
                                distanceToSelected =
                                    sqrt ((selected.x - Tuple.first clientPos) ^ 2 + (selected.y - Tuple.second clientPos) ^ 2)
                            in
                            distanceToSelected < selected.r

                        Nothing ->
                            False
            in
            if isOnSelected then
                { model
                    | showSlider = True
                    , lastSelected =
                        case model.selected of
                            Just c ->
                                c

                            Nothing ->
                                model.lastSelected
                }

            else
                model

        SliderValueChanged v ->
            { model | sliderValue = v }

        UpdateCircles ->
            let
                lastSelected =
                    model.lastSelected

                updatedSelected =
                    { lastSelected | r = model.sliderValue }

                updatedCircles =
                    updatedSelected :: List.filter (\c -> c /= model.lastSelected) model.circles
            in
            { model
                | circles = updatedCircles
                , lastSelected = updatedSelected
                , undoStack = ChangeDiameter model.lastSelected updatedSelected :: model.undoStack
            }

        ClickedX ->
            { model | showSlider = False }

        Undo ->
            case List.head model.undoStack of
                Just action ->
                    case action of
                        AddCircle _ ->
                            { model | circles = unique (Maybe.withDefault [] (List.tail model.circles)), undoStack = Maybe.withDefault [] (List.tail model.undoStack), redoStack = action :: model.redoStack }

                        ChangeDiameter oldCircle newCircle ->
                            let
                                updatedCircles =
                                    List.map
                                        (\c ->
                                            if c == newCircle then
                                                oldCircle

                                            else
                                                c
                                        )
                                        model.circles
                            in
                            { model | circles = unique updatedCircles, undoStack = Maybe.withDefault [] (List.tail model.undoStack), redoStack = action :: model.redoStack }

                Nothing ->
                    model

        Redo ->
            case List.head model.redoStack of
                Just action ->
                    case action of
                        AddCircle circle ->
                            { model | circles = unique (circle :: model.circles), undoStack = action :: model.undoStack, redoStack = Maybe.withDefault [] (List.tail model.redoStack) }

                        ChangeDiameter oldCircle newCircle ->
                            let
                                updatedCircles =
                                    List.map
                                        (\c ->
                                            if c == oldCircle then
                                                newCircle

                                            else
                                                c
                                        )
                                        model.circles
                            in
                            { model | circles = unique updatedCircles, undoStack = action :: model.undoStack, redoStack = Maybe.withDefault [] (List.tail model.redoStack) }

                Nothing ->
                    model


view : Model -> Html Msg
view model =
    div [ style "height" "25px", style "background-color" "black", style "width" "400px" ]
        [ button [ style "width" "200px", onClick Undo ] [ text "Undo" ]
        , button [ style "width" "200px", onClick Redo ] [ text "Redo" ]
        , div [ style "background-color" "black", style "width" "400px", style "height" "400px" ]
            [ svg
                [ width (px 400)
                , height (px 400)
                , fill (Paint Color.black)
                , Mouse.onDown (\event -> DownMsg event.button event.clientPos)
                , Mouse.onOver (\event -> HoverMsg event.offsetPos)
                , Mouse.onContextMenu (\event -> RightClickMsg event.offsetPos)
                ]
                (viewCircles model.selected model.circles)
            ]
        , if model.showSlider then
            let
                c =
                    model.lastSelected

                cX =
                    c.x

                cY =
                    c.y
            in
            div [ style "margin-top" "-215px", style "background-color" "blue", style "position" "relative", style "color" "white", style "width" "300px", style "font-size" "16px", style "top" "50%", style "left" "50%", style "transform" "translate(-50%, -50%)", style "height" "60px", style "padding-top" "40px", style "padding-left" "15px" ]
                [ button [ onClick ClickedX, style "font-size" "14px", style "font-weight" "bold", style "right" "0", style "top" "0", style "position" "absolute" ] [ text " X " ]
                , div []
                    [ text ("Adjust diameter of circle at " ++ "(" ++ (String.fromFloat cX ++ ", " ++ String.fromFloat cY) ++ "). ")
                    , input
                        [ type_ "range"
                        , Attr.min "0"
                        , Attr.max "200"
                        , step "1"
                        , style "width" "285px"
                        , style "margin-top" "10px"
                        , value (String.fromFloat model.sliderValue)
                        , onInput (\v -> SliderValueChanged (Maybe.withDefault 0 (String.toFloat v)))
                        , onMouseUp UpdateCircles
                        ]
                        []
                    ]
                ]

          else
            div [] []
        ]


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }
