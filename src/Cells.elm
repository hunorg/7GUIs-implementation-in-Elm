module Cells exposing (..)

import Browser
import Browser.Events exposing (onKeyPress)
import Dict exposing (Dict)
import Html exposing (Html, input, table, td, text, th, tr)
import Html.Attributes exposing (style, type_, value)
import Html.Events exposing (onDoubleClick, onInput)
import Json.Decode as Decode
import Parser exposing (..)
import Set



--types:


type alias Pos =
    { col : Char, row : Int }


type alias Cell =
    { pos : Pos
    , formula : String
    , value : Result String String -- The result of evaluating the formula, or an error message
    , dependencies : List Pos
    }


type alias Spreadsheet =
    { cells : Dict String Cell
    , dependencies : Dict String (List Pos)
    }


type alias Model =
    { spreadsheet : Spreadsheet
    , editing : Maybe Pos -- If Just (r, c), the cell at row r and column c is being edited
    }


type Msg
    = EditCell Pos
    | ChangeFormula Pos String
    | FinishEditing
    | NoOp


type Expr
    = ExprNum Float
    | ExprRef Pos
    | ExprRange Range
    | ExprBinOp BinOp


type alias BinOp =
    { opName : String, args : List Expr }


type alias Range =
    { from : Pos, to : Pos }


type CellContent
    = Expr Expr
    | Text String



--utils:


posToString : Pos -> String
posToString { col, row } =
    String.fromChar col ++ String.fromInt row


cellToString : Cell -> String
cellToString cell =
    case cell.value of
        Ok value ->
            value

        Err error ->
            error


emptyCell : Pos -> Cell
emptyCell pos =
    { pos = pos
    , formula = ""
    , value = Ok ""
    , dependencies = []
    }


cellView : Model -> Pos -> Html Msg
cellView model pos =
    let
        cell =
            Dict.get (posToString pos) model.spreadsheet.cells |> Maybe.withDefault (emptyCell pos)

        editing =
            model.editing == Just pos

        content =
            case cell.value of
                Ok value ->
                    text value

                Err error ->
                    text error
    in
    if editing then
        input
            [ type_ "text"
            , value cell.formula
            , onInput (ChangeFormula pos)
            ]
            []

    else
        td
            [ onDoubleClick (EditCell pos)
            , style "border" "1px solid black"
            ]
            [ content ]


rowCells : Int -> Model -> List (Html Msg)
rowCells rowIndex model =
    let
        colLabels =
            List.map Char.fromCode (List.range 65 90)

        -- A to Z in Unicode
        cellViews =
            List.map
                (\colChar ->
                    let
                        pos =
                            { col = colChar, row = rowIndex }
                    in
                    cellView model pos
                )
                colLabels
    in
    td
        [ style "background-color" "gray"
        , style "border" "1px solid black"
        ]
        [ text (String.fromInt rowIndex) ]
        :: cellViews


rowView : Int -> Model -> Html Msg
rowView rowIndex model =
    tr [] (rowCells rowIndex model)


headerView : Html Msg
headerView =
    let
        colLabels =
            List.map Char.fromCode (List.range 65 90)

        -- A to Z in Unicode
        thViews =
            List.map
                (\colChar ->
                    th
                        [ style "padding-right" "182px"
                        , style "background-color" "gray"
                        , style "border" "1px solid black"
                        ]
                        [ text (String.fromChar colChar) ]
                )
                colLabels
    in
    tr []
        (td [ style "background-color" "gray", style "border" "1px solid black" ] []
            :: thViews
        )


viewSpreadsheet : Model -> Html Msg
viewSpreadsheet model =
    let
        rowViews =
            List.map (\rowIndex -> rowView rowIndex model) (List.range 0 99)
    in
    table [ style "border-collapse" "collapse" ]
        (headerView :: rowViews)


getRefVal : Model -> Pos -> Maybe Float
getRefVal model ref =
    let
        spreadsheet =
            model.spreadsheet

        cells =
            spreadsheet.cells
    in
    case Dict.get (posToString ref) cells of
        Just cell ->
            case cell.value of
                Ok val ->
                    Just (Maybe.withDefault 0 (String.toFloat val))

                _ ->
                    Nothing

        _ ->
            Nothing


fromXY : { x : Int, y : Int } -> Pos
fromXY { x, y } =
    Pos (columnToChar x) y


toXY : Pos -> { x : Int, y : Int }
toXY { col, row } =
    { x = charToColumn col, y = row }


columnToChar : Int -> Char
columnToChar col =
    Char.fromCode (Char.toCode 'A' + col - 1)


charToColumn : Char -> Int
charToColumn char =
    Char.toCode char - Char.toCode 'A' + 1


getAllPosFromRange : Range -> Result String (List Pos)
getAllPosFromRange { from, to } =
    if from.col == to.col then
        let
            ( from_, to_ ) =
                ( toXY from, toXY to )

            columns =
                List.range from_.x to_.x

            rows =
                List.range from.row to.row
        in
        Ok
            (columns
                |> List.concatMap
                    (\x ->
                        rows |> List.map (\y -> fromXY { x = x, y = y })
                    )
            )

    else
        Err "parsing failed"



--main stuff:


initialModel : Model
initialModel =
    { spreadsheet =
        { cells =
            let
                colLabels =
                    List.map Char.fromCode (List.range 65 90)

                -- A to Z in Unicode
            in
            List.range 0 99
                |> List.concatMap
                    (\row ->
                        List.map
                            (\( colLabel, _ ) ->
                                let
                                    pos =
                                        { col = colLabel, row = row }
                                in
                                ( posToString pos, { pos = pos, formula = "", value = Err "", dependencies = [] } )
                            )
                            (List.map (\c -> ( c, () )) colLabels)
                    )
                |> Dict.fromList
        , dependencies = Dict.fromList []
        }
    , editing = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditCell pos ->
            ( { model | editing = Just pos }, Cmd.none )

        ChangeFormula pos newFormula ->
            let
                spreadsheet =
                    model.spreadsheet

                newValue =
                    if newFormula /= "" then
                        case evalInput newFormula of
                            Just expr ->
                                evalCellContent model expr

                            Nothing ->
                                Err "parsing failed"

                    else
                        Err ""

                updatedCells =
                    case Dict.get (posToString pos) spreadsheet.cells of
                        Just cell ->
                            Dict.update
                                (posToString pos)
                                (\_ -> Just { cell | formula = newFormula, value = newValue })
                                spreadsheet.cells

                        Nothing ->
                            spreadsheet.cells
            in
            ( { model | spreadsheet = { spreadsheet | cells = updatedCells } }, Cmd.none )

        FinishEditing ->
            ( { model | editing = Nothing }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    viewSpreadsheet model


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



--Parsers


exprParser : Parser Expr
exprParser =
    oneOf
        [ map ExprNum float
        , map ExprRef posParser
        , map ExprRange rangeParser
        , map ExprBinOp binOpParser
        ]


binOpParser : Parser BinOp
binOpParser =
    succeed BinOp
        |= variable { start = Char.isAlpha, inner = \c -> Char.isAlpha c || c == '_', reserved = Set.empty }
        |= sequence
            { start = "("
            , separator = ","
            , end = ")"
            , spaces = spaces
            , item = lazy (\_ -> exprParser)
            , trailing = Optional
            }


cellContentParser : Parser CellContent
cellContentParser =
    succeed identity
        |= oneOf
            [ succeed Expr |. symbol "=" |= exprParser
            , succeed Text |= (getChompedString <| chompWhile (always True))
            ]
        |. end


posParser : Parser Pos
posParser =
    succeed
        (\column row ->
            Pos (String.uncons column |> Maybe.map Tuple.first |> Maybe.withDefault 'A') row
        )
        |= (getChompedString <|
                succeed ()
                    |. chompIf Char.isUpper
           )
        |= int


rangeParser : Parser Range
rangeParser =
    succeed Range
        |. symbol "("
        |= posParser
        |. symbol ":"
        |= posParser
        |. symbol ")"



--Eval


evalInput : String -> Maybe CellContent
evalInput input =
    case run cellContentParser input of
        Ok (Expr expr) ->
            Just (Expr expr)

        Ok (Text string) ->
            Just (Text string)

        _ ->
            Nothing


evalExpr : Model -> Expr -> Result String Float
evalExpr model expr =
    case expr of
        ExprNum n ->
            Ok n

        ExprRef ref ->
            Ok (Maybe.withDefault 0 (getRefVal model ref))

        ExprRange range ->
            case getAllPosFromRange range of
                Ok positions ->
                    Ok (evalListPos model positions)

                Err err ->
                    Err err

        ExprBinOp nameArgs ->
            case nameArgs.opName of
                "sum" ->
                    opOnExprList model nameArgs.args "sum"

                "sub" ->
                    opOnExprList model nameArgs.args "sub"

                "mul" ->
                    opOnExprList model nameArgs.args "mul"

                "div" ->
                    opOnExprList model nameArgs.args "div"

                _ ->
                    Err "parsing failed"


evalCellContent : Model -> CellContent -> Result String String
evalCellContent model cellContent =
    case cellContent of
        Expr expr ->
            case evalExpr model expr of
                Ok num ->
                    Ok (String.fromFloat num)

                _ ->
                    Err ""

        Text string ->
            Ok string


opOnExprList : Model -> List Expr -> String -> Result String Float
opOnExprList model listExp op =
    case List.map (evalExpr model) listExp of
        [ Ok n1, Ok n2 ] ->
            case op of
                "sum" ->
                    Ok (n1 + n2)

                "sub" ->
                    Ok (n1 - n2)

                "mul" ->
                    Ok (n1 * n2)

                "div" ->
                    Ok (n1 / n2)

                _ ->
                    Err ""

        _ ->
            Err "parsing failed"


evalListPos : Model -> List Pos -> Float
evalListPos model listPos =
    let
        maybeToVal listMaybeFloat =
            List.map (Maybe.withDefault 0) listMaybeFloat
    in
    List.map (getRefVal model) listPos |> maybeToVal |> List.foldl (+) 0



--subscription and key decoder:


subscriptions : a -> Sub Msg
subscriptions _ =
    onKeyPress (Decode.map submitKey keyDecoder)


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string


submitKey : String -> Msg
submitKey key =
    if key == "Enter" then
        FinishEditing

    else
        NoOp
