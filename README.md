# Roblox RPG Project Structure

Este repositório contém os scripts principais para um jogo estilo RPG no Roblox. O projeto está organizado para separar responsabilidades do servidor, cliente e recursos compartilhados, além de manter um processo formal de migrations para qualquer alteração no armazenamento de dados.

## Estrutura de pastas

- `ServerScriptService/`: scripts e módulos executados no servidor.
  - `Modules/`: módulos reutilizáveis que tratam de dados, progressão do personagem, combate e missões.
- `ReplicatedStorage/`: módulos e recursos compartilhados entre servidor e cliente (configuração de itens, eventos remotos e constantes).
- `StarterPlayer/`: scripts do cliente relacionados aos jogadores.
- `StarterGui/`: scripts que constroem e mantêm as interfaces gráficas (HUD, inventário e missões).
- `Assets/`: local reservado para modelos, mapas e outros recursos estáticos.

## Convenções de código e organização

- Utilize `PascalCase` para nomes de módulos e classes (`CharacterStats`, `QuestManager`).
- Utilize `camelCase` para funções e variáveis internas.
- Centralize constantes compartilhadas em `ReplicatedStorage/`.
- Cada módulo deve expor apenas as funções necessárias e manter estado encapsulado.
- Scripts de interface devem ser colocados em `StarterGui/` e criar os elementos em tempo de execução para fácil manutenção no controle de versão.

## Migrations de dados

- Todas as alterações de schema e estrutura de dados persistidos devem ser implementadas por meio de migrations registradas no `DataStoreManager`.
- Antes de aplicar uma migration, o sistema verifica o estado atual do banco e garante que todas as dependências tenham sido executadas.
- Nunca faça commit de arquivos com extensão `.db` ou qualquer dump de banco de dados.
- Documente migrations complexas adicionando comentários e atualizando esta documentação quando necessário.

## Fluxo de desenvolvimento

1. Crie ou atualize módulos no servidor (`ServerScriptService/Modules`).
2. Atualize configurações e eventos compartilhados em `ReplicatedStorage/`.
3. Ajuste interfaces no cliente utilizando scripts em `StarterGui/`.
4. Sempre que houver alteração em dados persistentes, adicione uma nova migration.
5. Teste as alterações localmente no Roblox Studio antes de publicar.

## Eventos do Ato e Arena dos Campeões

- A arena de desafios está disponível através do mapa `champion_arena`, definido em `ReplicatedStorage/MapConfig.lua` e exportado como `Assets/Maps/ChampionArena.model.json`.
- Os jogadores devem cumprir o requisito mínimo de nível 25 para viajar para o vestiário e nível 30 para iniciar combates no ponto `arena_central`.
- O PvP da arena exige que ambos os jogadores estejam com a missão `arena_campeoes` ativa e posicionados no spawn `arena_central`.
- Utilize `MapManager:SpawnPlayer(player, "champion_arena", "vestiario")` ou envie um `Remotes.MapTravelRequest` correspondente para carregar o mapa durante eventos especiais do ato.
- Interfaces de missão podem ler o campo `recommendedMap` das definições em `QuestConfig` para orientar os jogadores sobre quando se deslocar para a arena.

## Testes automatizados

- O pacote `TestEZ` está disponível em `ReplicatedStorage/TestEZ` e é utilizado para executar as suites localizadas em `tests/server`.
- O script `tests/TestBootstrap.server.lua` pode ser colocado em `ServerScriptService` (via Rojo ou Roblox Studio) para rodar todos os testes.
- Para execução via linha de comando com o `roblox-cli`, utilize um lugar exportado/sincronizado e rode:

  ```sh
  roblox-cli run --load-place <caminho/do/lugar.rbxlx> --script tests/TestBootstrap.server.lua
  ```

  (ajuste o caminho do lugar de acordo com o ambiente de desenvolvimento).

## Próximos passos sugeridos

- Criar pipelines de build e publicação contínua.
- Expandir o conjunto de itens, missões e habilidades.

