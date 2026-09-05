[
  {
    "cenário" = "Criar tarefa";
    "navegação" = [
      {
        "descrição" = ''
          Este cenário consiste em acessar a página de criação de nova tarefa,
          preencher o título desejado e aguardar a tarefa aparecer na listagem.
          Isso garante que os dados foram submetidos e persistidos corretamente
          no IndexedDB.
        '';
      }
      {
        "navegar para" = "/tarefas/nova";
      }
      {
        "enviar formulário" = {
          "new-task-title" = "Comprar mantimentos para a semana";
        };
      }
      {
        "esperar aparecer" = "Comprar mantimentos para a semana";
      }
      {
        "capturar tela" = "tarefa-criada.png";
        "hash esperado" = "b29d375abf2b1435";
      }
    ];
  }
  {
    "cenário" = "Editar tarefa";
    "navegação" = [
      {
        "descrição" = ''
          Este cenário consiste em criar uma tarefa, acessar o formulário de
          edição da mesma, atualizar seu título e aguardar a exibição do novo
          título na listagem. Isso garante que a edição foi submetida e
          persistida corretamente no IndexedDB.
        '';
      }
      {
        "navegar para" = "/tarefas/nova";
      }
      {
        "enviar formulário" = {
          "new-task-title" = "Comprar mantimentos para a semana";
        };
      }
      {
        "esperar aparecer" = "Comprar mantimentos para a semana";
      }
      {
        "clicar em" = "Editar Tarefa";
      }
      {
        "esperar aparecer" = "Editar Tarefa";
      }
      {
        "enviar formulário" = {
          "new-task-title" = "Comprar mantimentos para a semana inteira";
        };
      }
      {
        "esperar aparecer" = "Comprar mantimentos para a semana inteira";
      }
      {
        "capturar tela" = "tarefa-editada.png";
        "hash esperado" = "68015bee01e1241a";
      }
    ];
  }
]
