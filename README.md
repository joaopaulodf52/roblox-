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

## Próximos passos sugeridos

- Adicionar testes automatizados para módulos críticos.
- Criar pipelines de build e publicação contínua.
- Expandir o conjunto de itens, missões e habilidades.

