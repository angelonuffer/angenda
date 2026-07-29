module Pages.NovaTarefa exposing (viewNovaTarefa)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewNovaTarefa : Model -> Html Msg
viewNovaTarefa model =
    div [ class "space-y-6 max-w-xl mx-auto" ]
        [ -- Title & Description
          div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Nova Tarefa" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Crie uma nova tarefa avulsa para sua lista de tarefas." ]
            ]
        , -- Add Task Form Card
          div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ Html.form [ onSubmit CreateTask, class "space-y-4" ]
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
                , div [ class "flex items-center justify-end gap-3 pt-2" ]
                    [ a
                        [ href "/tarefas"
                        , class "px-5 py-2 rounded-lg border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-colors text-center text-sm no-underline"
                        ]
                        [ text "Cancelar" ]
                    , button
                        [ type_ "submit"
                        , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm text-sm"
                        ]
                        [ text "Adicionar" ]
                    ]
                ]
            ]
        ]
