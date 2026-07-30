module Pages.Tarefas exposing (viewTarefas)

import Data.Task exposing (Task)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewTarefas : Model -> Html Msg
viewTarefas model =
    let
        filteredTasks =
            if model.tarefasTab == "arquivadas" then
                List.filter .archived model.tasks

            else
                List.filter (\t -> not t.archived) model.tasks
    in
    div [ class "space-y-6" ]
        [ -- Title & Description
          div [ class "flex flex-col sm:flex-row sm:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Tarefas" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Veja e gerencie todas as tarefas, incluindo as vindas de rotinas e planos." ]
                ]
            , a
                [ href "/tarefas/nova"
                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2.5 rounded-lg transition-colors shadow-sm text-sm flex items-center justify-center gap-2 cursor-pointer no-underline self-start sm:self-auto"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
                , text "Nova Tarefa"
                ]
            ]
        , -- Tabs for Active / Archived
          div [ class "border-b border-slate-200 flex gap-4 text-sm" ]
            [ button
                [ type_ "button"
                , id "tab-ativas"
                , onClick (SetTarefasTab "ativas")
                , class <|
                    "pb-3 font-semibold transition-all border-b-2 px-2 cursor-pointer "
                        ++ (if model.tarefasTab == "ativas" then
                                "border-red-600 text-red-600"

                            else
                                "border-transparent text-slate-500 hover:text-slate-800"
                           )
                ]
                [ text "Ativas" ]
            , button
                [ type_ "button"
                , id "tab-arquivadas"
                , onClick (SetTarefasTab "arquivadas")
                , class <|
                    "pb-3 font-semibold transition-all border-b-2 px-2 cursor-pointer "
                        ++ (if model.tarefasTab == "arquivadas" then
                                "border-red-600 text-red-600"

                            else
                                "border-transparent text-slate-500 hover:text-slate-800"
                           )
                ]
                [ text "Arquivadas" ]
            ]
        , -- Tasks List
          div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
            [ if List.isEmpty filteredTasks then
                div [ class "p-12 text-center space-y-3" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "task_alt" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ]
                        [ text <|
                            if model.tarefasTab == "arquivadas" then
                                "Nenhuma tarefa arquivada"

                            else
                                "Nenhuma tarefa encontrada"
                        ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ]
                        [ text <|
                            if model.tarefasTab == "arquivadas" then
                                "As tarefas que você arquivar aparecerão aqui. Você poderá restaurá-las a qualquer momento!"

                            else
                                "Crie tarefas avulsas no botão acima ou gere tarefas a partir de suas rotinas ou planos!"
                        ]
                    ]

              else
                ul [ class "divide-y divide-slate-100" ]
                    (List.map (viewTaskItem model.tarefasTab) filteredTasks)
            ]
        ]


viewTaskItem : String -> Task -> Html Msg
viewTaskItem currentTab task =
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
                    , viewHistoryBadge task.history
                    ]
                ]
            ]
        , div [ class "flex items-center gap-1" ]
            (if currentTab == "arquivadas" then
                [ button
                    [ type_ "button"
                    , onClick (RestoreTask task.id)
                    , class "text-slate-400 hover:text-green-600 p-2 rounded-lg hover:bg-green-50 transition-all flex items-center justify-center"
                    , title "Restaurar Tarefa"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "unarchive" ] ]
                , button
                    [ type_ "button"
                    , onClick (DeleteTaskAction task.id)
                    , class "text-slate-400 hover:text-rose-600 p-2 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                    , title "Excluir Permanente"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "delete" ] ]
                ]

             else
                [ a
                    [ href <| "/tarefas/editar/" ++ task.id
                    , class "text-slate-400 hover:text-amber-600 p-2 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center no-underline cursor-pointer"
                    , title "Editar Tarefa"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "edit" ] ]
                , button
                    [ type_ "button"
                    , onClick (ArchiveTask task.id)
                    , class "text-slate-400 hover:text-amber-600 p-2 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center"
                    , title "Arquivar Tarefa"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "archive" ] ]
                ]
            )
        ]


viewHistoryBadge : List String -> Html Msg
viewHistoryBadge history =
    let
        versionCount =
            List.length history
    in
    if versionCount == 0 then
        text ""

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "history" ]
            , text <| String.fromInt (versionCount + 1) ++ "ª versão"
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
