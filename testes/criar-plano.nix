[
  {
    "cenário" = "Criação de Plano";
    "navegação" = [
      {
        "descrição" = ''
          Este cenário consiste em acessar a página de criação de novo plano,
          preencher o título e a descrição desejados e aguardar o plano
          aparecer na listagem. Isso garante que os dados foram submetidos e
          persistidos corretamente no IndexedDB.
        '';
      }
      {
        "navegar para" = "/planos/novo";
      }
      {
        "esperar aparecer" = "Criar Novo Plano";
      }
      {
        "enviar formulário" = {
          "new-plan-title" = "Lançar novo website pessoal";
          "new-plan-desc" = "Passos necessários para colocar o site no ar de forma profissional.";
        };
      }
      {
        "esperar aparecer" = "Lançar novo website pessoal";
      }
      {
        "capturar tela" = "plano-criado.png";
        "hash esperado" = "63cd639544bc9a9";
      }
    ];
  }
]
