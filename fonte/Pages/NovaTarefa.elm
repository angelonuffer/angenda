module Pages.NovaTarefa exposing (viewNovaTarefa)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Route exposing (Route(..))
import Types exposing (Model, Msg(..))


viewNovaTarefa : Model -> Html Msg
viewNovaTarefa model =
    let
        config =
            case model.route of
                Route.EditarTarefa id ->
                    let
                        maybeTask =
                            model.tasks |> List.filter (\t -> t.id == id) |> List.head

                        cancelHref =
                            case maybeTask of
                                Just task ->
                                    if String.startsWith "plano:" task.origin then
                                        "/planos"

                                    else
                                        "/tarefas"

                                Nothing ->
                                    "/tarefas"
                    in
                    { pageTitle = "Editar Tarefa"
                    , pageDesc = "Edite os detalhes de sua tarefa."
                    , submitMsg = SaveEditedTask id
                    , buttonText = "Salvar"
                    , editingId = Just id
                    , cancelHref = cancelHref
                    }

                Route.AdicionarTarefa (Just planId) ->
                    let
                        maybePlan =
                            model.plans |> List.filter (\p -> p.id == planId) |> List.head

                        planTitle =
                            maybePlan |> Maybe.map .title |> Maybe.withDefault "Plano"
                    in
                    { pageTitle = "Nova Tarefa no Plano"
                    , pageDesc = "Crie uma nova tarefa vinculada ao plano: " ++ planTitle ++ "."
                    , submitMsg = CreateTask
                    , buttonText = "Adicionar"
                    , editingId = Nothing
                    , cancelHref = "/planos"
                    }

                _ ->
                    { pageTitle = "Nova Tarefa"
                    , pageDesc = "Crie uma nova tarefa avulsa para sua lista de tarefas."
                    , submitMsg = CreateTask
                    , buttonText = "Adicionar"
                    , editingId = Nothing
                    , cancelHref = "/tarefas"
                    }

        maybeEditingTask =
            case config.editingId of
                Just id ->
                    model.tasks |> List.filter (\t -> t.id == id) |> List.head

                Nothing ->
                    Nothing
    in
    div [ class "space-y-6 max-w-xl mx-auto" ]
        [ -- Title & Description
          div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text config.pageTitle ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text config.pageDesc ]
            ]
        , -- Add Task Form Card
          div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ Html.form [ onSubmit config.submitMsg, class "space-y-4" ]
                [ div []
                    [ label [ for "new-task-title", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Título da Tarefa" ]
                    , input
                        [ type_ "text"
                        , id "new-task-title"
                        , placeholder "Ex: Comprar mantimentos, Revisar relatório..."
                        , value model.taskTitleInput
                        , onInput InputTaskTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        , autofocus True
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-task-date", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Data da Tarefa" ]
                    , input
                        [ type_ "date"
                        , id "new-task-date"
                        , value model.taskDateInput
                        , onInput InputTaskDate
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div [ class "flex items-center justify-end gap-3 pt-2" ]
                    [ a
                        [ href config.cancelHref
                        , class "px-5 py-2 rounded-lg border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-colors text-center text-sm no-underline"
                        ]
                        [ text "Cancelar" ]
                    , button
                        [ type_ "submit"
                        , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm text-sm"
                        ]
                        [ text config.buttonText ]
                    ]
                ]
            ]
        , -- Version History Section
          case maybeEditingTask of
            Just task ->
                if List.isEmpty task.history then
                    text ""

                else
                    div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-3" ]
                        [ div [ class "flex items-center gap-2 text-slate-700 font-semibold text-sm border-b border-slate-100 pb-2" ]
                            [ span [ class "material-symbols-outlined text-slate-500", style "font-size" "18px" ] [ text "history" ]
                            , text "Histórico de Versões"
                            ]
                        , ul [ class "space-y-2 text-sm text-slate-600" ]
                            (List.indexedMap
                                (\index oldTitle ->
                                    li [ class "flex items-start gap-2.5 py-1" ]
                                        [ span [ class "text-slate-400 font-medium" ] [ text ("v" ++ String.fromInt (index + 1) ++ ":") ]
                                        , span [ class "text-slate-700 font-normal italic" ] [ text oldTitle ]
                                        ]
                                )
                                task.history
                            )
                        ]

            Nothing ->
                text ""
        ]
