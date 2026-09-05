# Angenda - Instruções e Diretrizes para Desenvolvedores (AGENTS.md)

Este documento descreve a arquitetura, padrões de projeto, convenções de código, regras de negócio e o fluxo de trabalho para o desenvolvimento no repositório **Angenda**. Ele serve como guia para agentes de IA e engenheiros de software trabalhando no projeto.

> **Importante para Agentes de IA:** Sempre que você implementar novas funcionalidades, rotas, modelos de dados ou modificar regras de negócio, **proponha e realize atualizações proativamente neste arquivo (`AGENTS.md`)** para manter as diretrizes rigorosamente alinhadas com o estado atual do repositório.

---

## 🚀 Visão Geral do Projeto

O **Angenda** é um webapp Single-Page Application (SPA) modular para organização pessoal, integrando:
1. **Tarefas avulsas** com agrupamento temporal.
2. **Hábitos e Rotinas recorrentes** (diárias, semanais ou mensais).
3. **Planos de Ação sequenciais** com barras de progresso interativas.
4. **Sincronização P2P** via MQTT e criptografia E2EE (End-to-End Encryption).

Ele utiliza o compilador **Elm (0.19.2)** para garantir robustez e ausência de erros em tempo de execução, estilização utilitária com **Tailwind CSS**, e persistência de dados local-first robusta com **IndexedDB**.

---

## 📂 Arquitetura e Organização do Código

O código-fonte da aplicação está estruturado sob o diretório `fonte/` e segue uma organização limpa e modular:

- **`fonte/Main.elm`**: O ponto de entrada da aplicação, orquestrando o ciclo de vida SPA via `Browser.application`.
- **`fonte/Route.elm`**: Centraliza o mapeamento de URLs para tipos de rotas da aplicação, gerindo caminhos como `/tarefas`, `/rotinas`, `/planos`, `/arquivo`, `/sincronizar`, etc.
- **`fonte/Ports.elm`**: Declara as portas (Ports) de entrada e saída para comunicação assíncrona bidirecional com o ambiente JavaScript (IndexedDB, hora local, MQTT, criptografia, etc.).
- **`fonte/Types.elm`**: Centraliza os tipos globais (`Model`, `Msg`, etc.) compartilhados entre os módulos, reduzindo acoplamentos circulares.
- **`fonte/Data/`**: Contém as definições de modelos de dados, encoders e decoders JSON para garantir a persistência:
  - `Task.elm`: Modelo de tarefas (ID, título, status de conclusão, data, arquivado, histórico, origem, updatedAt).
  - `Routine.elm`: Modelo de rotinas/hábitos (ID, título, recorrência, dias selecionados, período de início/fim, updatedAt).
  - `Plan.elm`: Modelo de planos sequenciais (ID, título, descrição, lista de IDs de passos das tarefas).
- **`fonte/Pages/`**: Contém os componentes visuais e de interação específicos de cada rota:
  - `Tarefas.elm`: Renderização das tarefas ativas agrupadas cronologicamente e injeção de previsão de rotinas dinâmicas.
  - `Rotinas.elm`: Cadastro de hábitos com suporte a recorrências (diária, semanal com seleção de dias, mensal) e controle de vigência.
  - `Planos.elm`: Exibição, criação e gerenciamento interativo de passos de planos de ação.
  - `Arquivo.elm`: Visualização de tarefas arquivadas e botão para sua restauração.
  - `Sincronizar.elm`: Interface para configuração e status do pareamento MQTT para sincronização E2EE.
  - `NovaTarefa.elm`: Interface isolada para inclusão ou edição de tarefas e seus atributos.

---

## 🎨 Diretrizes de UI e Convenções de Design

Ao expandir a interface do usuário, siga estritamente estas regras de design:

1. **Paleta de Cores (Tema Visual):**
   - O tema mimetiza um "caderno clássico de capa vermelha e fita marca-página amarela".
   - Use uma paleta baseada em **Red** (capa) como cor primária e **Amber/Yellow** (fita) como cor de destaque secundária.
2. **Biblioteca de Ícones:**
   - O projeto utiliza a fonte **Material Symbols Outlined** do Google Fonts, carregada em `fonte/index.html`.
   - Elementos de ícone devem ser declarados em Elm usando a classe `material-symbols-outlined` e os nomes de ligadura padrão como texto interno, por exemplo:
     - `playlist_add_check` (ícone de planos)
     - `repeat` (ícone de rotinas)
     - `schema` (ícone de passos/fluxo)
     - `push_pin` (ícone de fixar)
     - `delete` (ícone de lixeira / arquivar)
     - `task_alt` (ícone de conclusão de tarefas)
     - `edit` (ícone de editar)
     - `archive` (ícone de arquivar)
     - `unarchive` (ícone de restaurar)
     - `menu` (ícone de menu hambúrguer)
     - `close` (ícone de fechar)
     - `settings_remote` / `network_check` (ícones de sincronização via rede)
     - `event_upcoming` (ícone de tarefas previstas originadas de rotina)
3. **Menu Lateral (Lateral Drawer):**
   - A navegação principal fica em um painel lateral responsivo aberto por meio do ícone de menu hambúrguer no cabeçalho.
   - A ordem das opções no menu deve ser estritamente: **Tarefas**, **Planos**, **Rotinas**, **Arquivo** e **Sincronizar**.
4. **Exibição de Tarefas Ativas:**
   - No painel principal `/tarefas`, as tarefas devem ser categorizadas cronologicamente sob títulos de datas (ex: *Atrasadas*, *Hoje*, *Amanhã*, *Esta semana*, *Semana que vem*, *Sem data*).
   - Além das tarefas ativas do banco, a listagem injeta **tarefas previstas** (`previsto:rotina:...`) calculadas em tempo real com base nos próximos N dias, ajudando a organizar os dias futuros sem sobrecarregar o storage.
   - Se uma seção de data não possuir tarefas (reais ou previstas) associadas a ela, a seção correspondente deve ser automaticamente oculta da listagem para manter o painel limpo.

---

## 🧠 Regras de Negócio e Comportamentos Específicos

Preste extrema atenção às seguintes lógicas de negócio integradas:

1. **Substituição de Exclusão por Arquivamento:**
   - Não há opção de exclusão permanente de tarefas na interface do usuário. Todas as tarefas deletadas são marcadas como `archived = True`.
   - Tarefas arquivadas desaparecem da lista ativa `/tarefas` e aparecem em `/arquivo`, onde podem ser restauradas (`archived = False`) de volta ao painel principal.
2. **Arquivamento Automático de Tarefas Concluídas Vencidas:**
   - Tarefas que foram marcadas como concluídas (`completed = True`) e cuja data associada seja anterior à data local atual (`today`) devem ser arquivadas de forma automática (`archived = True`).
   - Esta sincronização e auto-arquivamento ocorrem automaticamente ao:
     - Carregar o banco de dados IndexedDB na inicialização do app.
     - Alternar o estado de conclusão de qualquer tarefa.
     - Completar passos de tarefas associadas a planos.
     - Salvar alterações após editar os campos de uma tarefa.
3. **Data Atual e Ciclo de Vida do App:**
   - A data local do dia (formato `YYYY-MM-DD`) é calculada em JavaScript no carregamento da página e enviada ao Elm via Flags de inicialização, populando o campo `today` no `Model`.
4. **Histórico de Alterações de Título:**
   - O modelo `Task` contém uma lista de histórico (`history : List String`).
   - Ao atualizar ou editar uma tarefa, o título anterior é anexado a esse histórico **somente se** o título atual tiver sido alterado em relação ao anterior.
5. **Redirecionamento ao Editar Tarefas Vinculadas a Planos:**
   - Tarefas que fazem parte de um plano de ação possuem um ID principal prefixado por `task_` correspondente ao passo do plano e seu campo `origin` configurado com o formato `plano:<id_do_plano>:<id_da_task_do_plano>`.
   - Ao editar qualquer tarefa com origem `plano:`, as ações de salvar ou cancelar o formulário de edição devem redirecionar dinamicamente o usuário de volta para a rota `/planos` (em vez do comportamento padrão de retornar para `/tarefas`).
6. **Decodificação de URL de Rotas e Persistência de Defaults:**
   - Para evitar inconsistências ou incompatibilidades com caracteres especiais e espaços em IDs de rotas (como títulos de planos/passos), a aplicação executa o decodamento percentual global de URL em `Route.fromUrl` usando `Url.percentDecode` antes do processamento sintático do parser de rotas.
   - Decodificadores JSON toleram registros legados no IndexedDB provendo valores padrão adequados (como `date` defaultado para `""`, `archived` para `False`, `history` para lista vazia `[]`, e `updatedAt` para `0`).
7. **Resolução de Conflitos na Sincronização:**
   - Cada entidade persistida deve possuir a propriedade `updatedAt : Int` (timestamp em milissegundos). A reconciliação das mensagens no cliente recebedor aplica a estratégia LWW (Last-Write-Wins), atualizando os registros locais somente quando a entidade recebida via rede tiver um `updatedAt` superior ou no caso do registro não existir localmente.

---

## 💾 Persistência Local-First (IndexedDB) e Sincronização

- Os dados persistem diretamente no navegador na base **`angenda_db`** usando três object stores:
  - `tasks`
  - `routines`
  - `plans`
- As atualizações de estado do Elm são transmitidas assincronamente ao JavaScript utilizando portas (ports) mapeadas em `<script>` no arquivo `fonte/index.html`.
- Além do IndexedDB, os dados podem ser propagados via WebSocket num Broker **MQTT**, codificados num payload e cifrados ponta a ponta com **AES-256-GCM** gerenciado por Web Crypto API no JavaScript. O app do Elm é responsável por despachar as ordens de sincronia e receber os pacotes decifrados.
- Qualquer nova propriedade nos modelos deve conter tratamentos adequados nos decodificadores Elm (`Data/`) para evitar a corrupção ou quebra de carregamento de registros preexistentes gravados no navegador do usuário, devendo ter garantias de defaults como `updatedAt = 0`.

---

## 🛠️ Fluxo de Trabalho, Compilação e Testes

Siga as instruções a seguir para manter o ambiente estável:

1. **Instalação das Dependências:**
   - Sempre certifique-se de executar `nix develop --command npm install` no diretório raiz antes de iniciar as compilações ou rodar os testes. Isto configurará o compilador Elm 0.19.2 localmente e as ferramentas Playwright necessárias dentro do ambiente isolado.
2. **Geração de Builds (Não edite artefatos diretamente!):**
   - O diretório final de distribuição do build compilado é **`alvo/`**.
   - **NÃO altere diretamente nenhum arquivo sob `alvo/`** (como `alvo/elm.js` ou `alvo/index.html`), pois eles são artefatos de build gerados automaticamente e serão sobrescritos.
   - Para gerar o build, faça alterações nas fontes contidas em `fonte/` e execute:
     ```bash
     nix develop --command npm run build
     ```
3. **Execução de Testes Automatizados e Capturas de Tela:**
   - O repositório integra testes automatizados ponta a ponta com o **Playwright**.
   - Para rodar a suíte inteira e regenerar todas as capturas de tela das páginas nos modos horizontal e vertical, use:
     ```bash
     nix develop --command npm test
     ```
   - Os arquivos de screenshot de validação são salvos e atualizados sob o caminho versionado `testes/páginas/`. Certifique-se de que os testes passem com sucesso antes de realizar commits.
   - Além disso, cenários declarativos de teste de caixa-preta baseados em Nix são definidos sob `testes/` (ex: `testes/tarefa.nix` contendo cenários de criação e edição de tarefas, e `testes/criar-plano.nix`). Esses testes são executados e validados com `testes-caixa-preta`:
     ```bash
     nix run github:angelonuffer/testes-caixa-preta
     ```
     As capturas de tela de validação desses cenários ficam em `testes/telas/`.
4. **Deploy de Hospedagem (Cloudflare Pages):**
   - A infraestrutura de deploy do Cloudflare Pages está configurada em `wrangler.json` apontando o diretório de assets para o diretório `./alvo`.
   - A regra de roteamento de Single-Page Application (SPA) está habilitada por meio de `assets.not_found_handling = "single-page-application"` para direcionar adequadamente rotas dinâmicas secundárias de volta ao index de forma transparente.

