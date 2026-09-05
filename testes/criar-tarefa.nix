[
  {
    "cenário" = "Criação de Tarefa";
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
        "hash esperado" = "9000458676475008";
      }
    ];
  }
]
