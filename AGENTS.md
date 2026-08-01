# Angenda - Instruções e Diretrizes para Desenvolvedores (AGENTS.md)

Este documento descreve a arquitetura, padrões de projeto, convenções de código, regras de negócio e o fluxo de trabalho para o desenvolvimento no repositório **Angenda**. Ele serve como guia para agentes de IA e engenheiros de software trabalhando no projeto.

---

## 🚀 Visão Geral do Projeto

O **Angenda** é um webapp Single-Page Application (SPA) modular para organização pessoal, integrando:
1. **Tarefas avulsas** com agrupamento temporal.
2. **Hábitos e Rotinas recorrentes** (diárias, semanais ou mensais).
3. **Planos de Ação sequenciais** com barras de progresso interativas.

Ele utiliza o compilador **Elm (0.19.2)** para garantir robustez e ausência de erros em tempo de execução, estilização utilitária com **Tailwind CSS**, e persistência de dados local-first robusta com **IndexedDB**.

---

## 📂 Arquitetura e Organização do Código

O código-fonte da aplicação está estruturado sob o diretório `fonte/` e segue uma organização limpa e modular:

- **`fonte/Main.elm`**: O ponto de entrada da aplicação, orquestrando o ciclo de vida SPA via `Browser.application`.
- **`fonte/Route.elm`**: Centraliza o mapeamento de URLs para tipos de rotas da aplicação, gerindo caminhos como `/tarefas`, `/rotinas`, `/planos`, `/planos/novo`, `/arquivo`, etc.
- **`fonte/Ports.elm`**: Declara as portas (Ports) de entrada e saída para comunicação assíncrona bidirecional com o ambiente JavaScript (IndexedDB, hora local, etc.).
- **`fonte/Types.elm`**: Centraliza os tipos globais (`Model`, `Msg`, etc.) compartilhados entre os módulos, reduzindo acoplamentos circulares.
- **`fonte/Data/`**: Contém as definições de modelos de dados, encoders e decoders JSON para garantir a persistência:
  - `Task.elm`: Modelo de tarefas (ID, título, status de conclusão, data, arquivado, histórico, origem).
  - `Routine.elm`: Modelo de rotinas/hábitos (ID, título, recorrência, última data de geração).
  - `Plan.elm`: Modelo de planos sequenciais (ID, título, descrição, lista de IDs de passos das tarefas).
- **`fonte/Pages/`**: Contém os componentes visuais e de interação específicos de cada rota:
  - `Tarefas.elm`: Renderização das tarefas ativas agrupadas cronologicamente.
  - `Rotinas.elm`: Cadastro de hábitos e geração manual de novas tarefas recorrentes.
  - `Planos.elm`: Exibição, criação e gerenciamento interativo de passos de planos de ação.
  - `Arquivo.elm`: Visualização de tarefas arquivadas e botão para sua restauração.

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
3. **Menu Lateral (Lateral Drawer):**
   - A navegação principal fica em um painel lateral responsivo aberto por meio do ícone de menu hambúrguer no cabeçalho.
   - A ordem das opções no menu deve ser estritamente: **Tarefas**, **Planos**, **Rotinas**, e **Arquivo**.
4. **Exibição de Tarefas Ativas:**
   - No painel principal `/tarefas`, as tarefas devem ser categorizadas cronologicamente sob títulos de datas (ex: *Hoje*, *Amanhã*, *Atrasadas*, *Sem data*).
   - Se uma seção de data não possuir tarefas ativas associadas a ela, a seção correspondente deve ser automaticamente oculta da listagem para manter o painel limpo.

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
6. **Decodificação de URL de Rotas:**
   - Para evitar inconsistências ou incompatibilidades com caracteres especiais e espaços em IDs de rotas (como títulos de planos/passos), a aplicação executa o decodamento percentual global de URL em `Route.fromUrl` usando `Url.percentDecode` antes do processamento sintático do parser de rotas.
   - Decodificadores JSON toleram registros legados no IndexedDB provendo valores padrão adequados (como `date` defaultado para `""`, `archived` para `False` e `history` para lista vazia `[]`).

---

## 💾 Persistência Local-First (IndexedDB)

- Os dados persistem diretamente no navegador na base **`angenda_db`** usando três object stores:
  - `tasks`
  - `routines`
  - `plans`
- As atualizações de estado do Elm são transmitidas assincronamente ao JavaScript utilizando portas (ports) mapeadas em `<script>` no arquivo `fonte/index.html`.
- Qualquer nova propriedade nos modelos deve conter tratamentos adequados nos decodificadores Elm (`Data/`) para evitar a corrupção ou quebra de carregamento de registros preexistentes gravados no navegador do usuário.

---

## 🛠️ Fluxo de Trabalho, Compilação e Testes

Siga as instruções a seguir para manter o ambiente estável:

1. **Instalação das Dependências:**
   - Sempre certifique-se de executar `npm install` no diretório raiz antes de iniciar as compilações ou rodar os testes. Isto configurará o compilador Elm 0.19.2 localmente e as ferramentas Playwright necessárias.
2. **Geração de Builds (Não edite artefatos diretamente!):**
   - O diretório final de distribuição do build compilado é **`alvo/`**.
   - **NÃO altere diretamente nenhum arquivo sob `alvo/`** (como `alvo/elm.js` ou `alvo/index.html`), pois eles são artefatos de build gerados automaticamente e serão sobrescritos.
   - Para gerar o build, faça alterações nas fontes contidas em `fonte/` e execute:
     ```bash
     npm run build
     ```
3. **Execução de Testes Automatizados e Capturas de Tela:**
   - O repositório integra testes automatizados ponta a ponta com o **Playwright**.
   - Para rodar a suíte inteira e regenerar todas as capturas de tela das páginas nos modos horizontal e vertical, use:
     ```bash
     npm test
     ```
   - Os arquivos de screenshot de validação são salvos e atualizados sob o caminho versionado `testes/páginas/`. Certifique-se de que os testes passem com sucesso antes de realizar commits.
4. **Deploy de Hospedagem (Cloudflare Pages):**
   - A infraestrutura de deploy do Cloudflare Pages está configurada em `wrangler.json` apontando o diretório de assets para o diretório `./alvo`.
   - A regra de roteamento de Single-Page Application (SPA) está habilitada por meio de `assets.not_found_handling = "single-page-application"` para direcionar adequadamente rotas dinâmicas secundárias de volta ao index de forma transparente.
