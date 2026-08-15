module Pages.Tarefas exposing (viewTarefas, viewDateBadge)

import Data.Routine exposing (Routine)
import Data.Task exposing (Task)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


-- DATE HELPER TYPES & FUNCTIONS

type alias DateRecord =
    { year : Int, month : Int, day : Int }


parseDate : String -> Maybe DateRecord
parseDate str =
    case String.split "-" (String.trim str) of
        [ yStr, mStr, dStr ] ->
            Maybe.map3 DateRecord
                (String.toInt yStr)
                (String.toInt mStr)
                (String.toInt dStr)

        _ ->
            Nothing


toAbsoluteDays : DateRecord -> Int
toAbsoluteDays date =
    let
        ( y, m ) =
            if date.month <= 2 then
                ( date.year - 1, date.month + 12 )

            else
                ( date.year, date.month )
    in
    365 * y + (y // 4) - (y // 100) + (y // 400) + (153 * (m + 1) // 5) + date.day


weekdayIndex : DateRecord -> Int
weekdayIndex date =
    let
        rem =
            toAbsoluteDays date |> modBy 7
    in
    -- rem: 0 = Sat, 1 = Sun, 2 = Mon, 3 = Tue, 4 = Wed, 5 = Thu, 6 = Fri
    -- We map to Mon = 0, Tue = 1, Wed = 2, Thu = 3, Fri = 4, Sat = 5, Sun = 6
    case rem of
        2 ->
            0

        3 ->
            1

        4 ->
            2

        5 ->
            3

        6 ->
            4

        0 ->
            5

        1 ->
            6

        _ ->
            0


isNextMonth : DateRecord -> DateRecord -> Bool
isNextMonth todayD taskD =
    if todayD.month == 12 then
        taskD.year == todayD.year + 1 && taskD.month == 1

    else
        taskD.year == todayD.year && taskD.month == todayD.month + 1


-- TASK GROUPING TYPES & FUNCTIONS

type TaskGroup
    = SemData
    | Atrasadas
    | Hoje
    | Amanha
    | EstaSemana
    | SemanaQueVem
    | EsteMes
    | MesQueVem
    | EsteAno
    | AnoQueVem
    | PorAno Int


groupOrder : TaskGroup -> Int
groupOrder g =
    case g of
        SemData ->
            1

        Atrasadas ->
            2

        Hoje ->
            3

        Amanha ->
            4

        EstaSemana ->
            5

        SemanaQueVem ->
            6

        EsteMes ->
            7

        MesQueVem ->
            8

        EsteAno ->
            9

        AnoQueVem ->
            10

        PorAno yr ->
            11 + yr


groupTitle : TaskGroup -> String
groupTitle g =
    case g of
        SemData ->
            "Sem data"

        Atrasadas ->
            "Atrasadas"

        Hoje ->
            "Hoje"

        Amanha ->
            "Amanhã"

        EstaSemana ->
            "Esta semana"

        SemanaQueVem ->
            "Semana que vem"

        EsteMes ->
            "Este mês"

        MesQueVem ->
            "Mês que vem"

        EsteAno ->
            "Este ano"

        AnoQueVem ->
            "Ano que vem"

        PorAno yr ->
            String.fromInt yr


classifyTask : DateRecord -> Task -> TaskGroup
classifyTask todayDate task =
    case parseDate task.date of
        Nothing ->
            SemData

        Just taskDate ->
            let
                todayAbs =
                    toAbsoluteDays todayDate

                taskAbs =
                    toAbsoluteDays taskDate

                daysDiff =
                    taskAbs - todayAbs

                todayWeekdayIdx =
                    weekdayIndex todayDate

                thisMonday =
                    todayAbs - todayWeekdayIdx
            in
            if not task.completed && daysDiff < 0 then
                Atrasadas

            else if daysDiff == 0 then
                Hoje

            else if daysDiff == 1 then
                Amanha

            else if taskAbs >= thisMonday && taskAbs <= thisMonday + 6 then
                EstaSemana

            else if taskAbs >= thisMonday + 7 && taskAbs <= thisMonday + 13 then
                SemanaQueVem

            else if taskDate.year == todayDate.year && taskDate.month == todayDate.month then
                EsteMes

            else if isNextMonth todayDate taskDate then
                MesQueVem

            else if taskDate.year == todayDate.year then
                EsteAno

            else if taskDate.year == todayDate.year + 1 then
                AnoQueVem

            else if taskDate.year > todayDate.year + 1 then
                PorAno taskDate.year

            else
                Atrasadas


groupTasks : DateRecord -> List Task -> List ( TaskGroup, List Task )
groupTasks todayDate tasks =
    let
        insertTask : Task -> Dict Int ( TaskGroup, List Task ) -> Dict Int ( TaskGroup, List Task )
        insertTask task acc =
            let
                g =
                    classifyTask todayDate task

                key =
                    groupOrder g
            in
            case Dict.get key acc of
                Just ( _, list ) ->
                    Dict.insert key ( g, list ++ [ task ] ) acc

                Nothing ->
                    Dict.insert key ( g, [ task ] ) acc

        groupedDict =
            List.foldl insertTask Dict.empty tasks
    in
    Dict.values groupedDict
        |> List.map
            (\( group, list ) ->
                ( group
                , List.sortWith
                    (\a b ->
                        case compare a.date b.date of
                            EQ ->
                                compare (String.toLower a.title) (String.toLower b.title)

                            other ->
                                other
                    )
                    list
                )
            )


daysInMonth : Int -> Int -> Int
daysInMonth year month =
    case month of
        2 -> if modBy 4 year == 0 && (modBy 100 year /= 0 || modBy 400 year == 0) then 29 else 28
        4 -> 30
        6 -> 30
        9 -> 30
        11 -> 30
        _ -> 31


addOneDay : DateRecord -> DateRecord
addOneDay date =
    let
        dim = daysInMonth date.year date.month
    in
    if date.day < dim then
        { date | day = date.day + 1 }
    else if date.month < 12 then
        { year = date.year, month = date.month + 1, day = 1 }
    else
        { year = date.year + 1, month = 1, day = 1 }


generateNextNDays : Int -> DateRecord -> List DateRecord
generateNextNDays n start =
    if n <= 0 then
        []
    else
        let
            next = addOneDay start
        in
        next :: generateNextNDays (n - 1) next


weekdayToString : Int -> String
weekdayToString idx =
    case idx of
        0 -> "Seg"
        1 -> "Ter"
        2 -> "Qua"
        3 -> "Qui"
        4 -> "Sex"
        5 -> "Sáb"
        6 -> "Dom"
        _ -> ""


dateToString : DateRecord -> String
dateToString d =
    String.fromInt d.year ++ "-" ++ String.padLeft 2 '0' (String.fromInt d.month) ++ "-" ++ String.padLeft 2 '0' (String.fromInt d.day)


createPredictedTasks : DateRecord -> Routine -> List Task
createPredictedTasks date routine =
    let
        wDayStr = weekdayToString (weekdayIndex date)
        shouldGenerate =
            if routine.recurrence == "Diária" then
                True
            else if routine.recurrence == "Semanal" then
                List.member wDayStr routine.selectedDays
            else
                False
    in
    if shouldGenerate then
        [ { id = "previsto_" ++ routine.id ++ "_" ++ dateToString date
          , title = routine.title
          , completed = False
          , origin = "previsto:rotina:" ++ routine.title
          , createdAt = "Previsto"
          , history = []
          , archived = False
          , date = dateToString date
          , updatedAt = 0
          }
        ]
    else
        []


-- VIEWS

viewTarefas : Model -> Html Msg
viewTarefas model =
    let
        maybeToday =
            parseDate model.today

        activeRoutines =
            List.filter (\r -> not r.archived) model.routines

        predictedTasks =
            case maybeToday of
                Just todayDate ->
                    let
                        futureDates = generateNextNDays model.predictDaysAhead todayDate
                    in
                    List.concatMap
                        (\d ->
                            List.concatMap (createPredictedTasks d) activeRoutines
                        )
                        futureDates

                Nothing ->
                    []

        activeTasks =
            List.filter (\t -> not t.archived) model.tasks ++ predictedTasks
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
        , -- Tasks List
          if List.isEmpty activeTasks then
            div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
                [ div [ class "p-12 text-center space-y-3" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "task_alt" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma tarefa encontrada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Crie tarefas avulsas no botão acima ou gere tarefas a partir de suas rotinas ou planos!" ]
                    ]
                ]

          else
            case maybeToday of
                Just todayDate ->
                    div [ class "space-y-6" ]
                        (List.map viewGroupSection (groupTasks todayDate activeTasks))

                Nothing ->
                    div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
                        [ ul [ class "divide-y divide-slate-100" ]
                            (List.map viewTaskItem activeTasks)
                        ]
        ]


viewGroupSection : ( TaskGroup, List Task ) -> Html Msg
viewGroupSection ( g, tasks ) =
    div [ class "space-y-2" ]
        [ h3 [ class "text-sm font-bold text-slate-500 uppercase tracking-wider px-1" ]
            [ text (groupTitle g)
            , span [ class "ml-2 text-xs font-semibold bg-slate-200 text-slate-600 px-2 py-0.5 rounded-full" ]
                [ text (String.fromInt (List.length tasks)) ]
            ]
        , div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
            [ ul [ class "divide-y divide-slate-100" ]
                (List.map viewTaskItem tasks)
            ]
        ]


viewTaskItem : Task -> Html Msg
viewTaskItem task =
    let
        isPredicted = String.startsWith "previsto:" task.origin
    in
    li [ class <| "p-4 flex items-center justify-between gap-4 transition-colors " ++ (if isPredicted then "opacity-80 bg-slate-50/50" else "hover:bg-slate-50") ++ (if task.completed then " opacity-75" else "") ]
        [ div [ class "flex items-start gap-3 flex-1" ]
            [ button
                [ type_ "button"
                , onClick (ToggleTask task.id)
                , disabled isPredicted
                , class <|
                    "mt-0.5 w-6 h-6 rounded-full border flex items-center justify-center transition-all "
                        ++ (if task.completed then
                                "bg-amber-500 border-amber-500 text-white"
                            else if isPredicted then
                                "border-slate-200 text-transparent bg-slate-100 cursor-not-allowed"
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
                                else if isPredicted then
                                    "text-slate-500"
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
        , if isPredicted then
            text ""
          else
            div [ class "flex items-center gap-1" ]
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
        -- Format "plano:planId:planTaskId" -> we can just display "Plano"
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "schema" ]
            , text "Plano"
            ]

    else if String.startsWith "previsto:rotina:" origin then
        let
            routineTitle =
                String.dropLeft (String.length "previsto:rotina:") origin
        in
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-indigo-50 text-indigo-700 border border-indigo-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "event_upcoming" ]
            , text <| "Previsto: " ++ routineTitle
            ]

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ text origin ]
