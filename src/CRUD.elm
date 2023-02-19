module CRUD exposing (..)

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (disabled, placeholder, style, type_, value)
import Html.Events exposing (..)



main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , update = update
        , view = view
        }


type alias Model =
    { names : List String
    , inputName : String
    , inputSurname : String
    , selectedName : String
    , inputPrefix : String
    }


initialModel : Model
initialModel =
    { names = [ "Emil, Cioran", "Arthur, Schopenhauer", "Ludwig, Wittgenstein" ]
    , inputName = ""
    , inputSurname = ""
    , selectedName = ""
    , inputPrefix = ""
    }


type Msg
    = UpdateInputName String
    | UpdateInputSurname String
    | Create String String
    | SelectName String
    | DeselectName
    | Delete String
    | UpdatePrefix String
    | Update String String String


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateInputName name ->
            { model | inputName = name }

        UpdateInputSurname surname ->
            { model | inputSurname = surname }

        Create name surname ->
            if name /= "" && surname /= "" then
                { model | names = (name ++ ", " ++ surname) :: model.names, inputName = "", inputSurname = "" }

            else
                model

        SelectName name ->
            let
                parts =
                    String.split ", " name

                selectedName =
                    Maybe.withDefault "" (List.head parts)

                selectedSurname =
                    Maybe.withDefault "" (List.head (Maybe.withDefault [] (List.tail parts)))
            in
            { model | selectedName = name, inputName = selectedName, inputSurname = selectedSurname }

        Delete _ ->
            { model | names = List.filter (\x -> x /= model.selectedName) model.names, selectedName = "", inputName = "", inputSurname = "" }

        DeselectName ->
            { model | selectedName = "", inputName = "", inputSurname = "" }

        UpdatePrefix prefix ->
            { model | inputPrefix = prefix }

        Update oldName newName newSurname ->
            if newName /= "" && newSurname /= "" then
                let
                    updated =
                        List.filter (\x -> x /= oldName) model.names

                    updatedNames =
                        (newName ++ ", " ++ newSurname) :: updated
                in
                { model | names = updatedNames, selectedName = "", inputName = "", inputSurname = "" }

            else
                model


view : Model -> Html Msg
view model =
    div [ style "background-color" "white", style "height" "400px" ]
        [ div []
            [ text "Filter prefix: "
            , input [ type_ "text", placeholder "Prefix", onInput UpdatePrefix ] []
            ]
        , div []
            [ namesList model model.names ]
        , div []
            [ text "Name........... : "
            , input [ type_ "text", placeholder "Name", value model.inputName, onInput UpdateInputName ] []
            ]
        , div []
            [ text "Surname..... : "
            , input [ type_ "text", placeholder "Surname", value model.inputSurname, onInput UpdateInputSurname ] []
            ]
        , div []
            [ button [ onClick (Create model.inputName model.inputSurname) ] [ text "Create" ]
            , button [ disabled (model.selectedName == ""), onClick (Update model.selectedName model.inputName model.inputSurname) ] [ text "Update" ]
            , button [ disabled (model.selectedName == ""), onClick (Delete model.selectedName) ] [ text "Delete" ]
            ]
        ]


namesList : Model -> List String -> Html Msg
namesList model names =
    let
        getSurname name =
            let
                parts =
                    String.split ", " name
            in
            Maybe.withDefault "" (List.head (Maybe.withDefault [] (List.tail parts)))
    in
    div [ style "background-color" "black", style "width" "295px", style "height" "100px", style "overflow-y" "scroll", style "overflow-x" "scroll" ]
        (List.map
            (\name ->
                div
                    [ onClick (SelectName name)
                    , style "background-color"
                        (if name == model.selectedName then
                            "blue"

                         else
                            "black"
                        )
                    , style "color" "white"
                    , style "width" "295px"
                    ]
                    [ text name ]
            )
            (if model.inputPrefix /= "" then
                List.filter (\x -> String.startsWith model.inputPrefix (getSurname x)) names

             else
                names
            )
        )
