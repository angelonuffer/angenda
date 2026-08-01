module Pages.Planos exposing (viewPlanos, viewNovoPlano, viewEditarPlano)

import Data.Plan exposing (Plan, PlanTask)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewPlanos : Model -> Html Msg
viewPlanos model =
    div [ class "space-y-6" ]
        [ div [ class "flex flex-col sm:flex-row sm:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Meus Planos" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Crie sequências de tarefas estruturadas para alcançar um objetivo maior." ]
                ]
            , a
                [ href "/planos/novo"
                , id "btn-novo-plano"
                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2.5 rounded-lg transition-colors shadow-sm text-sm flex items-center justify-center gap-2 cursor-pointer no-underline self-start sm:self-auto"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
                , text "Criar Plano"
                ]
            ]
        , -- Plans List & Editor
          div [ class "space-y-4" ]
            [ if List.isEmpty model.plans then
                div [ class "bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "schema" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhum plano cadastrado" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Comece criando um plano para estruturar sua jornada!" ]
                    ]

              else
                let
                    activePlans =
                        List.filter (\p -> not p.archived) model.plans
                in
                if List.isEmpty activePlans then
                    div [ class "bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                        [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "schema" ]
                        , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhum plano ativo" ]
                        , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Comece criando um plano para estruturar sua jornada!" ]
                        ]

                else
                    div [ class "space-y-4" ]
                        (List.map (viewPlanItem model) activePlans)
            ]
        ]


viewNovoPlano : Model -> Html Msg
viewNovoPlano model =
    div [ class "space-y-6 max-w-xl mx-auto" ]
        [ -- Title & Description
          div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Criar Novo Plano" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Defina o título e o objetivo de seu novo plano (projeto)." ]
            ]
        , -- Add Plan Form Card
          div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ Html.form [ onSubmit CreatePlan, class "space-y-4" ]
                [ div []
                    [ label [ for "new-plan-title", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Título do Plano" ]
                    , input
                        [ type_ "text"
                        , id "new-plan-title"
                        , placeholder "Ex: Aprender Alemão, Organizar Viagem de Férias..."
                        , value model.planTitleInput
                        , onInput InputPlanTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        , autofocus True
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-plan-desc", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Descrição" ]
                    , textarea
                        [ id "new-plan-desc"
                        , placeholder "Descreva o objetivo do plano..."
                        , value model.planDescInput
                        , onInput InputPlanDesc
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 h-24 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div [ class "flex items-center justify-end gap-3 pt-2" ]
                    [ a
                        [ href "/planos"
                        , class "px-5 py-2 rounded-lg border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-colors text-center text-sm no-underline"
                        ]
                        [ text "Cancelar" ]
                    , button
                        [ type_ "submit"
                        , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm text-sm"
                        ]
                        [ text "Criar Plano" ]
                    ]
                ]
            ]
        ]


viewPlanItem : Model -> Plan -> Html Msg
viewPlanItem model plan =
    let
        totalTasks =
            List.length plan.tasks

        completedTasks =
            List.filter .completed plan.tasks |> List.length

        progressPercent =
            if totalTasks == 0 then
                0

            else
                round ((toFloat completedTasks / toFloat totalTasks) * 100)
    in
    div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden hover:shadow-md transition-shadow" ]
        [ div [ class "p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-50/50" ]
            [ div [ class "space-y-1 flex-1" ]
                [ h4 [ class "font-bold text-lg text-slate-800" ] [ text plan.title ]
                , p [ class "text-slate-500 text-sm" ] [ text plan.description ]
                , if totalTasks > 0 then
                    div [ class "flex items-center gap-3 mt-2" ]
                        [ div [ class "w-24 bg-slate-200 rounded-full h-2 overflow-hidden" ]
                            [ div [ class "bg-amber-500 h-full rounded-full transition-all duration-300", style "width" (String.fromInt progressPercent ++ "%") ] [] ]
                        , span [ class "text-xs font-semibold text-slate-600" ] [ text (String.fromInt completedTasks ++ "/" ++ String.fromInt totalTasks ++ " concluídas (" ++ String.fromInt progressPercent ++ "%)") ]
                        ]

                  else
                    p [ class "text-xs text-slate-400 italic mt-1" ] [ text "Nenhuma tarefa adicionada a este plano." ]
                ]
            , div [ class "flex items-center gap-2 self-start sm:self-center" ]
                [ a
                    [ href <| "/planos/editar/" ++ plan.id
                    , id <| "editar-plano-" ++ plan.id
                    , class "bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 font-semibold text-sm px-4 py-2 rounded-lg transition-colors flex items-center gap-1.5 no-underline cursor-pointer shadow-sm"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "edit" ]
                    , text "Editar"
                    ]
                , button
                    [ type_ "button"
                    , onClick (ArchivePlan plan.id)
                    , class "text-slate-400 hover:text-amber-600 p-2 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center"
                    , title "Arquivar Plano"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "archive" ] ]
                ]
            ]
        ]


viewEditarPlano : Model -> String -> Html Msg
viewEditarPlano model planId =
    case List.filter (\p -> p.id == planId) model.plans |> List.head of
        Just plan ->
            div [ class "space-y-6 max-w-xl mx-auto" ]
                [ -- Title & Description
                  div []
                    [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Editar Plano" ]
                    , p [ class "text-slate-600 text-sm mt-1" ] [ text "Altere o título, a descrição e gerencie as tarefas deste plano." ]
                    ]
                , -- Edit Plan Form Card
                  div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
                    [ Html.form [ onSubmit (SaveEditedPlan planId), class "space-y-4" ]
                        [ div []
                            [ label [ for "edit-plan-title", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Título do Plano" ]
                            , input
                                [ type_ "text"
                                , id "edit-plan-title"
                                , placeholder "Ex: Aprender Alemão, Organizar Viagem de Férias..."
                                , value model.planTitleInput
                                , onInput InputPlanTitle
                                , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                                , autofocus True
                                ]
                                []
                            ]
                        , div []
                            [ label [ for "edit-plan-desc", class "block text-sm font-semibold text-slate-700 mb-1" ] [ text "Descrição" ]
                            , textarea
                                [ id "edit-plan-desc"
                                , placeholder "Descreva o objetivo do plano..."
                                , value model.planDescInput
                                , onInput InputPlanDesc
                                , class "w-full border border-slate-300 rounded-lg px-4 py-2 h-24 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                                ]
                                []
                            ]
                        , div [ class "flex items-center justify-end gap-3 pt-2" ]
                            [ a
                                [ href "/planos"
                                , class "px-5 py-2 rounded-lg border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-colors text-center text-sm no-underline"
                                ]
                                [ text "Cancelar" ]
                            , button
                                [ type_ "submit"
                                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm text-sm"
                                ]
                                [ text "Salvar" ]
                            ]
                        ]
                    ]
                , -- Sequence of Tasks of the Plan
                  div [ class "bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
                    [ h3 [ class "font-bold text-slate-800 text-base" ] [ text "Sequência de Tarefas do Plano" ]
                    , -- Button to navigate to new task page
                      div [ class "flex justify-end" ]
                        [ a
                            [ href <| "/tarefas/nova/" ++ plan.id
                            , id "add-plan-task-btn"
                            , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-4 py-1.5 rounded-lg text-sm transition-colors no-underline inline-flex items-center gap-1.5 cursor-pointer shadow-sm"
                            ]
                            [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "playlist_add" ]
                            , text "Adicionar Tarefa ao Plano"
                            ]
                        ]
                    , -- List of current plan tasks
                      if List.isEmpty plan.tasks then
                        p [ class "text-sm text-slate-400 italic text-center py-4" ] [ text "Sem tarefas adicionadas a este plano. Adicione tarefas para iniciar a sequência!" ]

                      else
                        ol [ class "divide-y divide-slate-100 border border-slate-100 rounded-lg overflow-hidden bg-slate-50/20" ]
                            (List.indexedMap (viewPlanTaskItem plan.id) plan.tasks)
                    ]
                ]

        Nothing ->
            div [ class "space-y-6 max-w-xl mx-auto text-center p-12" ]
                [ h2 [ class "text-xl font-bold text-slate-800" ] [ text "Plano não encontrado" ]
                , a
                    [ href "/planos"
                    , class "mt-4 inline-block bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors"
                    ]
                    [ text "Voltar para Planos" ]
                ]


viewPlanTaskItem : String -> Int -> PlanTask -> Html Msg
viewPlanTaskItem planId index pt =
    li [ class <| "p-3 flex items-center justify-between gap-3 text-sm " ++ if pt.completed then "opacity-70 bg-amber-50/10" else "" ]
        [ div [ class "flex items-center gap-2" ]
            [ button
                [ type_ "button"
                , onClick (TogglePlanTask planId pt.id)
                , class <|
                    "w-5 h-5 rounded-full border flex items-center justify-center transition-all "
                        ++ (if pt.completed then
                                "bg-amber-500 border-amber-500 text-white"

                            else
                                "border-slate-300 text-transparent hover:border-red-500"
                           )
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "12px", style "font-weight" "bold" ] [ text "check" ] ]
            , span [ class "font-semibold text-slate-400" ] [ text (String.fromInt (index + 1) ++ ".") ]
            , span [ class <| "font-medium " ++ if pt.completed then "line-through text-slate-400" else "text-slate-700" ] [ text pt.title ]
            ]
        , div [ class "flex items-center gap-1" ]
            [ a
                [ href <| "/tarefas/editar/task_" ++ pt.id
                , class "text-slate-400 hover:text-amber-600 p-1 rounded-lg hover:bg-amber-50 transition-all flex items-center justify-center no-underline cursor-pointer"
                , title "Editar Tarefa"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "edit" ] ]
            , button
                [ type_ "button"
                , onClick (DeletePlanTask planId pt.id)
                , class "text-slate-400 hover:text-rose-600 p-1 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                , title "Excluir Passo"
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "delete" ] ]
            ]
        ]
