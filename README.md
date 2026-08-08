# Angenda

**Angenda** é um webapp Single-Page Application (SPA) para gerenciamento inteligente de tarefas pessoais, desenvolvido utilizando a linguagem **Elm**, estilizado com **Tailwind CSS** e com persistência de dados local integrada via **IndexedDB**.

O projeto reúne de forma integrada três pilares fundamentais de organização pessoal: tarefas diárias/avulsas, hábitos/rotinas repetitivas, e planos de ação sequenciados (projetos).

---

## 🚀 Funcionalidades Principais

O aplicativo conta com três visualizações principais totalmente integradas:

1. **/tarefas (Lista Integrada de Tarefas)**
   - Exibe em um único local todas as tarefas avulsas criadas pelo usuário, tarefas geradas de forma recorrente por suas **Rotinas** e cada um dos passos programados nos **Planos**.
   - Permite a conclusão imediata de qualquer tarefa com sincronização de progresso automática nos planos correspondentes.
   - Oferece filtros visuais baseados na origem da tarefa (Etiquetas coloridas de identificação: *Avulsa*, *Rotina*, *Plano*).

2. **/rotinas (Gerenciamento de Hábitos e Repetições)**
   - Permite cadastrar tarefas recorrentes com configurações personalizadas de repetição (**Diária**, **Semanal** ou **Mensal**).

3. **/planos (Gerenciamento de Projetos e Objetivos)**
   - Permite organizar sequências estruturadas de tarefas direcionadas a alcançar um objetivo maior.
   - Cada plano exibe uma barra de progresso visual mostrando a porcentagem de passos concluídos.
   - Oferece um editor interativo para adicionar, remover e ordenar novos passos sequenciais, que são sincronizados em tempo real com a tela principal de tarefas.

---

## 💾 Persistência com IndexedDB

Todos os dados criados (tarefas, rotinas e planos) são armazenados localmente no navegador do usuário utilizando a API nativa **IndexedDB**.
- Banco de dados: `angenda_db`
- Lojas de objetos (Object Stores): `tasks`, `routines`, `plans`
- A sincronização entre o estado imutável do Elm e o banco de dados é feita de maneira assíncrona por meio de **Ports** no arquivo `public/app.js`.

---

## 🛠️ Tecnologias Utilizadas

- **Elm (0.19.2):** Linguagem funcional focada em usabilidade, performance e ausência de erros em tempo de execução.
- **Tailwind CSS (Play CDN):** Framework CSS utilitário para design elegante e responsivo.
- **IndexedDB:** Armazenamento local de alta capacidade para funcionamento offline.
- **Playwright:** Suite de testes para validação ponta a ponta e captura automatizada de telas.
- **Cloudflare Pages:** Infraestrutura de deploy estático global com roteamento SPA configurado via `wrangler.json`.

---

## 📦 Como Instalar e Executar Localmente

### Pré-requisitos
Certifique-se de ter instalado em sua máquina:
- [Node.js](https://nodejs.org/) (v18 ou superior)
- [Elm Compiler](https://elm-lang.org/) (v0.19.1 ou v0.19.2)

### Passos para Execução
1. Clone o repositório para o seu ambiente local:
   ```bash
   git clone https://github.com/angelonuffer/angenda.git
   cd angenda
   ```

2. Instale as dependências de desenvolvimento (Playwright):
   ```bash
   npm install
   ```

3. Compile e construa o projeto:
   ```bash
   npm run build
   ```

4. Para abrir o projeto, você pode servir a pasta `dist` usando qualquer servidor estático ou rodar o teste que possui servidor embutido.

---

## 🧪 Testes Automatizados e Capturas de Tela (Playwright)

O projeto inclui um script automatizado de testes localizado em `./testes/telas.js` utilizando **Playwright**.

Este teste realiza as seguintes ações de forma 100% automatizada:
1. Sobe um servidor HTTP local simulando o comportamento de SPA.
2. Abre o navegador Chromium de forma invisível (*headless*).
3. Preenche tarefas, cria rotinas, gera passos em planos e interage com os botões para simular uma experiência real do usuário.
4. Tira capturas de tela (*screenshots*) em formatos **Horizontal** (Desktop: 1280x800) e **Vertical** (Mobile: 375x812) de todas as páginas.
5. Salva os arquivos de imagem organizados por rotas no diretório `./testes/telas/<pagina>/<layout>.png`:
   - `testes/telas/tarefas/horizontal.png`
   - `testes/telas/tarefas/vertical.png`
   - `testes/telas/rotinas/horizontal.png`
   - `testes/telas/rotinas/vertical.png`
   - `testes/telas/planos/horizontal.png`
   - `testes/telas/planos/vertical.png`

Para rodar os testes e gerar novas capturas de tela localmente, utilize:
```bash
npm test
```

---

## ⚙️ Integração Contínua (GitHub Actions)

Toda vez que você realizar um `push` ou abrir um `pull request` em **qualquer branch**, o GitHub Actions rodará o workflow configurado em `.github/workflows/test.yml`.
O pipeline executará os seguintes passos de forma automatizada:
1. Configuração do ambiente Node.js.
2. Instalação do compilador **Elm** no container de testes.
3. Instalação das dependências e navegador Chromium do **Playwright**.
4. Compilação da aplicação estática (`npm run build`).
5. Execução do script de testes e validação de rotas (`npm test`).

---

## ☁️ Deploy no Cloudflare Pages (`wrangler.json`)

O deploy estático para o **Cloudflare Pages** está totalmente configurado no arquivo `wrangler.json`.

O arquivo define:
- O diretório de saída dos builds estáticos como `dist`.
- O parâmetro `assets.not_found_handling` configurado como `"single-page-application"`. Esta diretiva garante que qualquer rota acessada diretamente (como `/planos` ou `/rotinas`) seja internamente redirecionada para `index.html` de forma transparente, permitindo que o roteador de SPA do Elm lide com as rotas sem gerar erros 404.
