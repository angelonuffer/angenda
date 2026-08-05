{
  description = "Angenda - Gerenciador de Tarefas";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            elmPackages.elm
            elmPackages.elm-format
            elmPackages.elm-review
            elmPackages.elm-test
            
            # Dependências úteis para testes e-2-e com Playwright no NixOS
            playwright-driver.browsers
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            
            # Configura o Playwright para usar os navegadores baixados via Nix, 
            # evitando falhas ao tentar baixar binários pré-compilados em NixOS.
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

            export PS1="\[\e[1;31m\][angenda]\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] $ "

            echo "==========================================="
            echo " Ambiente de desenvolvimento Angenda ativo!"
            echo " Node.js: $(node --version)"
            echo " Elm:     $(elm --version)"
            echo "==========================================="
          '';
        };
      }
    );
}
