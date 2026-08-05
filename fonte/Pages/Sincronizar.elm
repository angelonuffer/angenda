module Pages.Sincronizar exposing (viewSincronizar)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (Model, Msg(..))


viewSincronizar : Model -> Html Msg
viewSincronizar model =
    let
        activeTasksCount =
            List.filter (\t -> not t.archived) model.tasks |> List.length

        activeRoutinesCount =
            List.filter (\r -> not r.archived) model.routines |> List.length

        activePlansCount =
            List.filter (\p -> not p.archived) model.plans |> List.length

        archivedCount =
            (List.filter .archived model.tasks |> List.length)
                + (List.filter .archived model.routines |> List.length)
                + (List.filter .archived model.plans |> List.length)
    in
    div [ class "space-y-6" ]
        [ -- Page Header
          div [ class "flex flex-col sm:flex-row sm:items-center justify-between gap-4" ]
            [ div []
                [ div [ class "flex items-center gap-3" ]
                    [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Sincronização" ]
                    , span [ class "px-2.5 py-1 text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-full flex items-center gap-1.5" ]
                        [ span [ class "w-2 h-2 rounded-full bg-emerald-500 animate-pulse" ] []
                        , text "MQTT + Criptografia E2EE"
                        ]
                    ]
                , p [ class "text-slate-600 text-sm mt-1" ]
                    [ text "Sincronize com segurança seus dados entre múltiplos dispositivos enviando pacotes cifrados via rede MQTT." ]
                ]
            ]
        , -- Grid with MQTT Config & Connection Status
          div [ class "grid grid-cols-1 lg:grid-cols-3 gap-6" ]
            [ -- MQTT Settings Form Card (Takes 2 Columns)
              div [ class "lg:col-span-2 bg-white rounded-xl border border-slate-200 shadow-sm p-6 space-y-5" ]
                [ div [ class "flex items-center gap-2 border-b border-slate-100 pb-3" ]
                    [ span [ class "material-symbols-outlined text-red-700" ] [ text "settings_remote" ]
                    , h3 [ class "font-bold text-slate-800 text-lg" ] [ text "Configuração de Pareamento MQTT" ]
                    ]
                , div [ class "space-y-4" ]
                    [ -- Device Name Field
                      div []
                        [ label [ class "block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5" ]
                            [ text "Nome do Dispositivo" ]
                        , input
                            [ type_ "text"
                            , id "mqtt-device-name-input"
                            , value model.mqttDeviceName
                            , onInput InputMqttDeviceName
                            , placeholder "Ex: Meu Celular"
                            , class "w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none text-slate-800 transition-all"
                            ] []
                        , p [ class "text-xs text-slate-500 mt-1" ]
                            [ text "Identifique este dispositivo na rede." ]
                        ]
                    , -- Broker URL Field
                      div []
                        [ label [ class "block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5" ]
                            [ text "Servidor Broker MQTT (WebSocket)" ]
                        , input
                            [ type_ "text"
                            , id "mqtt-broker-input"
                            , value model.mqttBrokerUrl
                            , onInput InputMqttBrokerUrl
                            , placeholder "wss://broker.hivemq.com:8884/mqtt"
                            , class "w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none text-slate-800 transition-all"
                            ] []
                        , p [ class "text-xs text-slate-500 mt-1" ]
                            [ text "Endereço WebSocket com suporte a TLS/SSL do seu broker MQTT." ]
                        ]
                    , -- Sync Topic Field
                      div []
                        [ label [ class "block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5" ]
                            [ text "Código / Tópico de Sincronização" ]
                        , div [ class "flex gap-2" ]
                            [ input
                                [ type_ "text"
                                , id "mqtt-topic-input"
                                , value model.mqttTopic
                                , onInput InputMqttTopic
                                , class "flex-1 px-3.5 py-2.5 text-sm font-mono bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none text-slate-800 transition-all"
                                ] []
                            , button
                                [ onClick GenerateMqttTopic
                                , type_ "button"
                                , class "px-3 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium text-xs rounded-lg transition-colors flex items-center gap-1 shrink-0 border border-slate-300"
                                ]
                                [ span [ class "material-symbols-outlined", style "font-size" "16px" ] [ text "autorenew" ]
                                , text "Gerar"
                                ]
                            ]
                        , p [ class "text-xs text-slate-500 mt-1" ]
                            [ text "Use este mesmo código em seus outros dispositivos para pareá-los." ]
                        ]
                    , -- Encryption Key Field
                      div []
                        [ label [ class "block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5" ]
                            [ text "Chave de Criptografia (Senha Secreta)" ]
                        , input
                            [ type_ "password"
                            , id "mqtt-key-input"
                            , value model.mqttEncryptionKey
                            , onInput InputMqttEncryptionKey
                            , placeholder ""
                            , class "w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none text-slate-800 transition-all"
                            ] []
                        , p [ class "text-xs text-slate-500 mt-1" ]
                            [ text "Sua senha pessoal para decifrar os dados. Nunca é enviada ao broker." ]
                        ]
                    ]
                ]
            , -- Status Card (Takes 1 Column)
              div [ class "bg-white rounded-xl border border-slate-200 shadow-sm p-6 space-y-4 flex flex-col justify-between" ]
                [ div [ class "space-y-4" ]
                    [ div [ class "flex items-center gap-2 border-b border-slate-100 pb-3" ]
                        [ span [ class "material-symbols-outlined text-amber-500" ] [ text "network_check" ]
                        , h3 [ class "font-bold text-slate-800 text-lg" ] [ text "Status da Conexão" ]
                        ]
                    , div [ class "space-y-3 text-sm" ]
                        [ div [ class "flex justify-between items-center py-1.5 border-b border-slate-50" ]
                            [ span [ class "text-slate-500" ] [ text "Estado:" ]
                            , span [ class "font-semibold text-emerald-600 flex items-center gap-1.5" ]
                                [ span [ class "w-2 h-2 rounded-full bg-emerald-500" ] []
                                , text model.mqttStatus
                                ]
                            ]
                        , div [ class "flex justify-between items-center py-1.5 border-b border-slate-50" ]
                            [ span [ class "text-slate-500" ] [ text "Protocolo:" ]
                            , span [ class "font-mono font-medium text-slate-700 text-xs bg-slate-100 px-2 py-0.5 rounded" ] [ text "MQTT v3.1.1 (WSS)" ]
                            ]
                        , div [ class "flex justify-between items-center py-1.5 border-b border-slate-50" ]
                            [ span [ class "text-slate-500" ] [ text "Criptografia:" ]
                            , span [ class "font-semibold text-slate-700 text-xs bg-amber-50 text-amber-700 px-2 py-0.5 rounded border border-amber-200" ] [ text "AES-256-GCM" ]
                            ]
                        , div [ class "flex justify-between items-center py-1.5" ]
                            [ span [ class "text-slate-500" ] [ text "Última Sincronia:" ]
                            , span [ class "font-medium text-slate-700 text-xs" ]
                                [ text (Maybe.withDefault "Nenhuma recente" model.lastSyncTimestamp) ]
                            ]
                        ]
                    ]
                , div [ class "bg-slate-50 p-3.5 rounded-lg border border-slate-200 text-xs text-slate-600 flex items-center gap-2.5" ]
                    [ span [ class "material-symbols-outlined text-slate-400 shrink-0", style "font-size" "20px" ] [ text "info" ]
                    , text "Os dados são sincronizados em tempo real sempre que ocorrem alterações no aplicativo."
                    ]
                ]
            ]
        , -- Stats / Data Summary in Sync
          div [ class "space-y-3" ]
            [ h3 [ class "font-bold text-slate-800 text-base flex items-center gap-2" ]
                [ span [ class "material-symbols-outlined text-slate-500", style "font-size" "20px" ] [ text "dataset" ]
                , text "Resumo de Dados para Sincronização"
                ]
            , div [ class "grid grid-cols-2 sm:grid-cols-4 gap-4" ]
                [ viewStatCard "playlist_add_check" "Tarefas Ativas" (String.fromInt activeTasksCount) "bg-red-50 text-red-700"
                , viewStatCard "repeat" "Rotinas Recorrentes" (String.fromInt activeRoutinesCount) "bg-amber-50 text-amber-700"
                , viewStatCard "schema" "Planos de Ação" (String.fromInt activePlansCount) "bg-blue-50 text-blue-700"
                , viewStatCard "archive" "Itens Arquivados" (String.fromInt archivedCount) "bg-slate-100 text-slate-700"
                ]
            ]
        ]


viewStatCard : String -> String -> String -> String -> Html Msg
viewStatCard iconName label textValue colorClasses =
    div [ class "bg-white rounded-xl border border-slate-200 p-4 shadow-sm flex items-center gap-3.5" ]
        [ div [ class <| "w-10 h-10 rounded-lg flex items-center justify-center shrink-0 " ++ colorClasses ]
            [ span [ class "material-symbols-outlined", style "font-size" "22px" ] [ text iconName ] ]
        , div []
            [ p [ class "text-2xl font-bold text-slate-900 leading-none" ] [ text textValue ]
            , p [ class "text-xs font-medium text-slate-500 mt-1" ] [ text label ]
            ]
        ]
