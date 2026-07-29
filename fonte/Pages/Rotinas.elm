module Pages.Rotinas exposing (viewRotinas)

import Data.Routine exposing (Routine)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewRotinas : Model -> Html Msg
viewRotinas model =
    div [ class "space-y-6" ]
        [ div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Rotinas" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Defina tarefas recorrentes e crie instâncias delas na lista principal com um clique." ]
            ]
        , -- Add Routine Form
          Html.form [ onSubmit CreateRoutine, class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ h3 [ class "font-semibold text-slate-700 text-sm" ] [ text "Nova Rotina" ]
            , div [ class "grid grid-cols-1 md:grid-cols-3 gap-4" ]
                [ div [ class "md:col-span-2" ]
                    [ label [ for "new-routine-title", class "sr-only" ] [ text "Nome da Rotina" ]
                    , input
                        [ type_ "text"
                        , id "new-routine-title"
                        , placeholder "Ex: Beber 2L de água, Fazer academia..."
                        , value model.routineTitleInput
                        , onInput InputRoutineTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-routine-recurrence", class "sr-only" ] [ text "Recorrência" ]
                    , select
                        [ id "new-routine-recurrence"
                        , value model.routineRecurrenceInput
                        , onInput InputRoutineRecurrence
                        , class "w-full border border-slate-300 rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        [ option [ value "Diária" ] [ text "Diária" ]
                        , option [ value "Semanal" ] [ text "Semanal" ]
                        , option [ value "Mensal" ] [ text "Mensal" ]
                        ]
                    ]
                ]
            , div [ class "flex justify-end" ]
                [ button
                    [ type_ "submit"
                    , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm"
                    ]
                    [ text "Criar Rotina" ]
                ]
            ]
        , -- Routines List
          div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
            [ if List.isEmpty model.routines then
                div [ class "col-span-full bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "autorenew" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma rotina configurada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Adicione rotinas para tarefas diárias, semanais ou mensais usando o formulário acima!" ]
                    ]

              else
                div [ class "col-span-full grid grid-cols-1 md:grid-cols-2 gap-4" ]
                    (List.map viewRoutineItem model.routines)
            ]
        ]


viewRoutineItem : Routine -> Html Msg
viewRoutineItem routine =
    div [ class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between gap-4 hover:shadow-md transition-shadow" ]
        [ div [ class "space-y-2" ]
            [ div [ class "flex items-start justify-between gap-4" ]
                [ h4 [ class "font-bold text-lg text-slate-800" ] [ text routine.title ]
                , button
                    [ type_ "button"
                    , onClick (DeleteRoutineAction routine.id)
                    , class "text-slate-400 hover:text-rose-600 p-1.5 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                    , title "Excluir Rotina"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "delete" ] ]
                ]
            , div [ class "flex items-center gap-1.5" ]
                [ span [ class "material-symbols-outlined text-red-500", style "font-size" "18px" ] [ text "repeat" ]
                , span [ class "text-xs font-semibold text-red-600 uppercase tracking-wider" ] [ text routine.recurrence ]
                ]
            ]
        , button
            [ type_ "button"
            , onClick (GenerateTaskFromRoutine routine)
            , class "w-full bg-slate-50 hover:bg-red-50 border border-slate-200 hover:border-red-200 text-red-600 hover:text-red-700 font-semibold py-2 rounded-lg transition-colors text-sm flex items-center justify-center gap-2"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
            , text "Gerar Tarefa"
            ]
        ]
