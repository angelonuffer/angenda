module Pages.Arquivo exposing (viewArquivo)

import Data.Plan exposing (Plan)
import Data.Task exposing (Task)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


type ArchivedItem
    = ArchivedTask Task
    | ArchivedPlan Plan


viewArquivo : Model -> Html Msg
viewArquivo model =
    let
        archivedTasks =
            List.filter .archived model.tasks
                |> List.map ArchivedTask

        archivedPlans =
            List.filter .archived model.plans
                |> List.map ArchivedPlan

        allArchivedItems =
            archivedTasks ++ archivedPlans
    in
    div [ class "space-y-6" ]
        [ -- Title & Description
          div [ class "flex flex-col sm:flex-row sm:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Arquivo" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Gerencie suas tarefas e planos arquivados e restaure-os quando necessário." ]
                ]
            ]
        , -- Unified List
          div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
            [ if List.isEmpty allArchivedItems then
                div [ class "p-12 text-center space-y-3" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "archive" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhum item arquivado" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Suas tarefas e planos arquivados aparecerão aqui." ]
                    ]

              else
                ul [ class "divide-y divide-slate-100" ]
                    (List.map viewArchivedItem allArchivedItems)
            ]
        ]


viewArchivedItem : ArchivedItem -> Html Msg
viewArchivedItem item =
    case item of
        ArchivedTask task ->
            viewArchivedTaskItem task

        ArchivedPlan plan ->
            viewArchivedPlanItem plan


viewArchivedTaskItem : Task -> Html Msg
viewArchivedTaskItem task =
    li [ class <| "p-4 flex items-center justify-between gap-4 hover:bg-slate-50 transition-colors " ++ if task.completed then "opacity-75" else "" ]
        [ div [ class "flex items-start gap-3 flex-1" ]
            [ div [ class <| "mt-1 w-5 h-5 rounded-full border flex items-center justify-center " ++ if task.completed then "bg-amber-500 border-amber-500 text-white" else "border-slate-300 text-transparent" ]
                [ span [ class "material-symbols-outlined", style "font-size" "12px", style "font-weight" "bold" ] [ text "check" ] ]
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
                    , viewDateBadge task.date
                    ]
                ]
            ]
        , div [ class "flex items-center gap-1" ]
            [ button
                [ type_ "button"
                , onClick (RestoreTask task.id)
                , class "text-slate-400 hover:text-red-700 p-2 rounded-lg hover:bg-red-50 transition-all flex items-center justify-center"
                , title "Restaurar Tarefa"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "unarchive" ] ]
            ]
        ]


viewArchivedPlanItem : Plan -> Html Msg
viewArchivedPlanItem plan =
    li [ class "p-4 flex items-center justify-between gap-4 hover:bg-slate-50 transition-colors" ]
        [ div [ class "flex items-start gap-3 flex-1" ]
            [ div [ class "mt-1 text-slate-400 flex items-center justify-center" ]
                [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "schema" ] ]
            , div [ class "space-y-1" ]
                [ p [ class "font-medium text-slate-800" ] [ text plan.title ]
                , div [ class "flex flex-wrap items-center gap-2" ]
                    [ span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-100" ]
                        [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "schema" ]
                        , text "Plano"
                        ]
                    ]
                ]
            ]
        , div [ class "flex items-center gap-1" ]
            [ button
                [ type_ "button"
                , onClick (RestorePlan plan.id)
                , class "text-slate-400 hover:text-red-700 p-2 rounded-lg hover:bg-red-50 transition-all flex items-center justify-center"
                , title "Restaurar Plano"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "unarchive" ] ]
            ]
        ]


formatDate : String -> String
formatDate rawDate =
    case String.split "-" rawDate of
        [ year, month, day ] ->
            day ++ "/" ++ month ++ "/" ++ year

        _ ->
            rawDate


viewDateBadge : String -> Html Msg
viewDateBadge dateStr =
    if String.trim dateStr == "" then
        text ""

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "calendar_month" ]
            , text (formatDate dateStr)
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
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "schema" ]
            , text "Plano"
            ]

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ text origin ]
