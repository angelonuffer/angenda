module Pages.Planos exposing (viewPlanos)

import Data.Plan exposing (Plan, PlanTask)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewPlanos : Model -> Html Msg
viewPlanos model =
    div [ class "space-y-6" ]
        [ div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Meus Planos" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Crie sequências de tarefas estruturadas para alcançar um objetivo maior." ]
            ]
        , -- Add Plan Form
          Html.form [ onSubmit CreatePlan, class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ h3 [ class "font-semibold text-slate-700 text-sm" ] [ text "Novo Plano (Projeto)" ]
            , div [ class "grid grid-cols-1 gap-4" ]
                [ div []
                    [ label [ for "new-plan-title", class "sr-only" ] [ text "Título do Plano" ]
                    , input
                        [ type_ "text"
                        , id "new-plan-title"
                        , placeholder "Ex: Aprender Alemão, Organizar Viagem de Férias..."
                        , value model.planTitleInput
                        , onInput InputPlanTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-plan-desc", class "sr-only" ] [ text "Descrição" ]
                    , textarea
                        [ id "new-plan-desc"
                        , placeholder "Descreva o objetivo do plano..."
                        , value model.planDescInput
                        , onInput InputPlanDesc
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 h-20 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                ]
            , div [ class "flex justify-end" ]
                [ button
                    [ type_ "submit"
                    , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm"
                    ]
                    [ text "Criar Plano" ]
                ]
            ]
        , -- Plans List & Editor
          div [ class "space-y-4" ]
            [ if List.isEmpty model.plans then
                div [ class "bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "schema" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhum plano cadastrado" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Comece criando um plano no formulário acima para estruturar sua jornada!" ]
                    ]

              else
                div [ class "space-y-4" ]
                    (List.map (viewPlanItem model) model.plans)
            ]
        ]


viewPlanItem : Model -> Plan -> Html Msg
viewPlanItem model plan =
    let
        isEditing =
            model.editingPlanId == Just plan.id

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
        [ div [ class "p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-50/50" ]
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
                [ button
                    [ type_ "button"
                    , id <| "gerenciar-plano-" ++ plan.id
                    , onClick (if isEditing then StopEditPlan else StartEditPlan plan.id)
                    , class <|
                        "font-semibold text-sm px-4 py-2 rounded-lg border transition-colors "
                            ++ (if isEditing then
                                    "bg-red-50 border-red-200 text-red-700 hover:bg-red-100"

                                else
                                    "bg-white border-slate-200 text-slate-600 hover:bg-slate-50"
                               )
                    ]
                    [ text (if isEditing then "Fechar" else "Gerenciar Tarefas") ]
                , button
                    [ type_ "button"
                    , onClick (DeletePlanAction plan.id)
                    , class "text-slate-400 hover:text-rose-600 p-2 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                    , title "Excluir Plano"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "delete" ] ]
                ]
            ]
        , if isEditing then
            div [ class "p-5 bg-white space-y-4 border-t border-slate-100" ]
                [ h5 [ class "font-semibold text-slate-700 text-sm" ] [ text "Sequência de Tarefas do Plano" ]
                , -- Form to add sequential tasks
                  Html.form
                    [ onSubmit (AddPlanTask plan.id)
                    , class "flex gap-2"
                    ]
                    [ input
                        [ type_ "text"
                        , id "new-plan-task"
                        , placeholder "Insira o próximo passo do plano..."
                        , value model.newPlanTaskTitle
                        , onInput InputPlanTaskTitle
                        , class "flex-1 border border-slate-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-red-500 text-sm text-slate-800"
                        ]
                        []
                    , button
                        [ type_ "submit"
                        , id "add-plan-task-btn"
                        , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-4 py-1.5 rounded-lg text-sm transition-colors"
                        ]
                        [ text "Adicionar" ]
                    ]
                , -- List of current plan tasks
                  if List.isEmpty plan.tasks then
                    p [ class "text-sm text-slate-400 italic text-center py-4" ] [ text "Sem tarefas adicionadas a este plano. Adicione tarefas para iniciar a sequência!" ]

                  else
                    ol [ class "divide-y divide-slate-100 border border-slate-100 rounded-lg overflow-hidden bg-slate-50/20" ]
                        (List.indexedMap (viewPlanTaskItem plan.id) plan.tasks)
                ]

          else
            text ""
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
        , button
            [ type_ "button"
            , onClick (DeletePlanTask planId pt.id)
            , class "text-slate-400 hover:text-rose-600 p-1 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
            , title "Excluir Passo"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "delete" ] ]
        ]
