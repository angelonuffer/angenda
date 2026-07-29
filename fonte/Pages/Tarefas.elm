module Pages.Tarefas exposing (viewTarefas)

import Data.Task exposing (Task)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewTarefas : Model -> Html Msg
viewTarefas model =
    div [ class "space-y-6" ]
        [ -- Title & Description
          div [ class "flex flex-col md:flex-row md:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Tarefas" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Veja e gerencie todas as tarefas, incluindo as vindas de rotinas e planos." ]
                ]
            ]
        , -- Add Task Form
          Html.form [ onSubmit CreateTask, class "bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3" ]
            [ input
                [ type_ "text"
                , id "new-task-title"
                , placeholder "Adicionar nova tarefa avulsa..."
                , value model.taskTitleInput
                , onInput InputTaskTitle
                , class "flex-1 border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                ]
                []
            , button
                [ type_ "submit"
                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm w-full sm:w-auto"
                ]
                [ text "Adicionar" ]
            ]
        , -- Tasks List
          div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
            [ if List.isEmpty model.tasks then
                div [ class "p-12 text-center space-y-3" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "task_alt" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma tarefa encontrada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Crie tarefas avulsas no formulário acima ou gere tarefas a partir de suas rotinas ou planos!" ]
                    ]

              else
                ul [ class "divide-y divide-slate-100" ]
                    (List.map viewTaskItem model.tasks)
            ]
        ]


viewTaskItem : Task -> Html Msg
viewTaskItem task =
    li [ class <| "p-4 flex items-center justify-between gap-4 hover:bg-slate-50 transition-colors " ++ if task.completed then "opacity-75" else "" ]
        [ div [ class "flex items-start gap-3 flex-1" ]
            [ button
                [ type_ "button"
                , onClick (ToggleTask task.id)
                , class <|
                    "mt-0.5 w-6 h-6 rounded-full border flex items-center justify-center transition-all "
                        ++ (if task.completed then
                                "bg-amber-500 border-amber-500 text-white"

                            else
                                "border-slate-300 text-transparent hover:border-red-500"
                           )
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "14px", style "font-weight" "bold" ] [ text "check" ] ]
            , div [ class "space-y-1" ]
                [ p
                    [ class <|
                        "font-medium "
                            ++ (if task.completed then
                                    "line-through text-slate-400"

                                else
                                    "text-slate-800"
                               )
                    ]
                    [ text task.title ]
                , div [ class "flex flex-wrap items-center gap-2" ]
                    [ -- Badge
                      viewOriginBadge task.origin
                    ]
                ]
            ]
        , button
            [ type_ "button"
            , onClick (DeleteTaskAction task.id)
            , class "text-slate-400 hover:text-rose-600 p-2 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
            , title "Excluir Tarefa"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "delete" ] ]
        ]


viewOriginBadge : String -> Html Msg
viewOriginBadge origin =
    if origin == "avulsa" then
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "push_pin" ]
            , text "Avulsa"
            ]

    else if String.startsWith "rotina:" origin then
        let
            routineTitle =
                String.dropLeft (String.length "rotina:") origin
        in
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-red-50 text-red-700 border border-red-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "repeat" ]
            , text <| "Rotina: " ++ routineTitle
            ]

    else if String.startsWith "plano:" origin then
        -- Format "plano:planId:planTaskId" -> we can just display "Plano"
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "schema" ]
            , text "Plano"
            ]

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ text origin ]
