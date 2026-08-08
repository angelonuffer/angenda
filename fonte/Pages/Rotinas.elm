module Pages.Rotinas exposing (viewRotinas, viewNovaRotina)

import Data.Routine exposing (Routine)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Route exposing (Route(..))
import Types exposing (Model, Msg(..))


viewRotinas : Model -> Html Msg
viewRotinas model =
    div [ class "space-y-6" ]
        [ div [ class "flex flex-col sm:flex-row sm:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Rotinas" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Defina tarefas recorrentes e crie instâncias delas na lista principal com um clique." ]
                ]
            , a
                [ href "/rotinas/nova"
                , id "btn-nova-rotina"
                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2.5 rounded-lg transition-colors shadow-sm text-sm flex items-center justify-center gap-2 cursor-pointer no-underline self-start sm:self-auto"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
                , text "Criar Rotina"
                ]
            ]
        , -- Routines List
          div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
            [ let
                activeRoutines =
                    List.filter (\r -> not r.archived) model.routines
              in
              if List.isEmpty activeRoutines then
                div [ class "col-span-full bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "autorenew" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma rotina configurada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Adicione rotinas para tarefas diárias, semanais ou mensais usando o formulário acima!" ]
                    ]

              else
                div [ class "col-span-full grid grid-cols-1 md:grid-cols-2 gap-4" ]
                    (List.map viewRoutineItem activeRoutines)
            ]
        ]


viewRoutineItem : Routine -> Html Msg
viewRoutineItem routine =
    div [ class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between gap-4 hover:shadow-md transition-shadow" ]
        [ div [ class "space-y-2" ]
            [ div [ class "flex items-start justify-between gap-4" ]
                [ h4 [ class "font-bold text-lg text-slate-800" ] [ text routine.title ]
                , div [ class "flex items-center gap-1" ]
                    [ a
                        [ href <| "/rotinas/editar/" ++ routine.id
                        , class "text-slate-400 hover:text-amber-600 p-1.5 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center cursor-pointer no-underline"
                        , title "Editar Rotina"
                        ]
                        [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "edit" ] ]
                    , button
                        [ type_ "button"
                        , onClick (ArchiveRoutine routine.id)
                        , class "text-slate-400 hover:text-amber-600 p-1.5 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center"
                        , title "Arquivar Rotina"
                        ]
                        [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "archive" ] ]
                    ]
                ]
            , div [ class "flex items-center gap-1.5 flex-wrap" ]
                [ span [ class "material-symbols-outlined text-red-500", style "font-size" "18px" ] [ text "repeat" ]
                , span [ class "text-xs font-semibold text-red-600 uppercase tracking-wider" ] [ text routine.recurrence ]
                , if routine.recurrence == "Semanal" && not (List.isEmpty routine.selectedDays) then
                    span [ class "text-xs font-medium text-slate-500 ml-2" ]
                        [ text ("(" ++ String.join ", " routine.selectedDays ++ ")") ]
                  else
                    text ""
                ]
            ]
        , if routine.recurrence == "Diária" || routine.recurrence == "Semanal" then
            div [ class "w-full bg-slate-50 border border-slate-200 text-slate-500 font-medium py-2 rounded-lg text-sm flex items-center justify-center gap-2" ]
                [ span [ class "material-symbols-outlined text-slate-400", style "font-size" "18px" ] [ text "auto_awesome" ]
                , text "Gerada Automaticamente"
                ]
          else
            button
                [ type_ "button"
                , onClick (GenerateTaskFromRoutine routine)
                , class "w-full bg-slate-50 hover:bg-red-50 border border-slate-200 hover:border-red-200 text-red-600 hover:text-red-700 font-semibold py-2 rounded-lg transition-colors text-sm flex items-center justify-center gap-2"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
                , text "Gerar Tarefa"
                ]
        ]


viewNovaRotina : Model -> Html Msg
viewNovaRotina model =
    let
        config =
            case model.route of
                Route.EditarRotina id ->
                    { pageTitle = "Editar Rotina"
                    , pageDesc = "Edite o nome da rotina e sua frequência."
                    , submitMsg = SaveEditedRoutine id
                    , buttonText = "Salvar"
                    }

                _ ->
                    { pageTitle = "Criar Nova Rotina"
                    , pageDesc = "Defina o nome da rotina e sua frequência."
                    , submitMsg = CreateRoutine
                    , buttonText = "Criar Rotina"
                    }
    in
    div [ class "space-y-6 max-w-xl mx-auto" ]
        [ -- Title & Description
          div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text config.pageTitle ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text config.pageDesc ]
            ]
        , -- Add Routine Form Card
          div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ Html.form [ onSubmit config.submitMsg, class "space-y-4" ]
                [ div []
                    [ label [ for "new-routine-title", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Nome da Rotina" ]
                    , input
                        [ type_ "text"
                        , id "new-routine-title"
                        , placeholder "Ex: Beber 2L de água, Fazer academia..."
                        , value model.routineTitleInput
                        , onInput InputRoutineTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        , autofocus True
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-routine-recurrence", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Recorrência" ]
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
                , if model.routineRecurrenceInput == "Semanal" then
                    div []
                        [ label [ class "block text-sm font-semibold text-slate-700 mb-2" ] [ text "Dias da Semana" ]
                        , div [ class "flex flex-wrap gap-2" ]
                            (List.map
                                (\day ->
                                    let
                                        isSelected =
                                            List.member day model.routineSelectedDaysInput

                                        btnClass =
                                            if isSelected then
                                                "bg-red-600 text-white border-red-600"
                                            else
                                                "bg-white text-slate-600 border-slate-300 hover:bg-slate-50"
                                    in
                                    button
                                        [ type_ "button"
                                        , onClick (ToggleRoutineDay day)
                                        , class ("px-3 py-1.5 rounded border text-sm font-medium transition-colors " ++ btnClass)
                                        ]
                                        [ text day ]
                                )
                                [ "Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb" ]
                            )
                        ]
                  else
                    text ""
                , div [ class "flex items-center justify-end gap-3 pt-2" ]
                    [ a
                        [ href "/rotinas"
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
        ]
