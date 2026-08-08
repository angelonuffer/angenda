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
            
            # Navegador Chromium nativo do NixOS para o Playwright
            chromium
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            
            # Configura o Playwright para usar o Chromium nativo do NixOS, 
            # ignorando o download e os problemas de versão do `playwright-driver`
            export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
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
