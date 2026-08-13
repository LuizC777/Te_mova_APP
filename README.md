# te-mova

Aplicativo Flutter para orientação de equipes de roçada em acostamento de rodovias.

O app recebe chamados de manutenção, conduz a equipe até o trecho designado, acompanha a execução do serviço e registra o resultado com comprovação fotográfica.

## Estado atual

Protótipo funcional com dados simulados. Toda a navegação, o fluxo de estados e as telas estão implementados; o que ainda não existe é a integração com backend, GPS e câmera.

Não há dependências externas — apenas o SDK do Flutter.

## Requisitos

- Flutter SDK 3.27 ou superior
- Android SDK (via Android Studio)
- Modo desenvolvedor do Windows ativado, se for o caso

A versão mínima do Flutter importa: o código usa `Color.withValues()`, que substituiu o `withOpacity()` a partir da 3.27. Em SDK anterior, trocar as chamadas por `withOpacity()` resolve.

## Como rodar

```bash
flutter pub get
flutter run
```

Para prototipar apenas a interface, sem emulador:

```bash
flutter run -d chrome
```

## Estrutura

```
lib/
├── main.dart                      Tema e casca de navegação
├── models.dart                    Solicitação, equipe, operador, poda
├── models/
│   └── rota.dart                  Geolocalização, rota, navegação
├── estado/
│   └── estado_chamado.dart        Máquina de estados do chamado
├── servicos/
│   └── servico_rota.dart          Interface de rotas e implementação mockada
├── widgets/
│   ├── mapa_mock.dart             Mapa de deslocamento (simulado)
│   └── mapa_area.dart             Mapa do trecho a roçar (simulado)
└── pages/
    ├── home_page.dart             Alterna entre chamado, rota e execução
    ├── rota_page.dart             Navegação até o local
    ├── execucao_page.dart         Cronômetro e conclusão do serviço
    ├── equipe_page.dart           Operadores e veículo
    └── historico_page.dart        Registros agrupados por dia e mês
```

## Fluxo do serviço

O chamado percorre quatro estados, definidos em `StatusPoda`:

| Estado          | Cor no histórico | Como se chega                    |
| --------------- | ---------------- | -------------------------------- |
| Em deslocamento | Amarelo          | Operador aceita o chamado        |
| Em progresso    | Amarelo          | Equipe confirma chegada ao local |
| Interrompida    | Vermelho         | Cancelamento em qualquer ponto   |
| Concluída       | Verde            | Poda finalizada com foto         |

Um chamado interrompido volta para a lista de disponíveis e pode ser retomado. Cada aceite gera um registro próprio no histórico — tentativas anteriores não são sobrescritas, para preservar o rastro de auditoria.

## Telas

**Home.** Exibe o chamado disponível com horário da solicitação, altura da grama medida contra o limite de 10 cm, urgência e quilômetro da rodovia. A barra de altura muda para amarelo ao ultrapassar 80% do limite. Conforme o estado do chamado, a mesma aba passa a mostrar a navegação ou a execução.

**Rota.** Instrução de manobra no topo, mapa com o traçado e o veículo em deslocamento, e painel com distância, tempo restante e horário previsto de chegada. O percurso simulado leva 90 segundos.

**Execução.** Cronômetro contínuo, mapa focado no trecho designado com a faixa de acostamento destacada, e as opções de interromper ou concluir. A conclusão exige foto e registro da altura final.

**Equipe.** Operadores da equipe DELTA, com destaque para o encarregado, além do modelo e placa do veículo.

**Histórico.** Registros agrupados por mês e por dia, em cards compactos com horário, duração, altura final, equipe e quilômetro. Serviços em andamento aparecem no topo com borda colorida.

## Arquitetura

**Estado compartilhado.** `EstadoChamado` é um `ChangeNotifier` global consumido por `ListenableBuilder` na Home e no Histórico. É suficiente para um chamado por vez.

**Dados geográficos reais.** `PontoGeo` guarda latitude e longitude de verdade, e a distância entre pontos usa a fórmula de Haversine. Os mapas são simulados; as coordenadas não são.

**Serviço de rotas por interface.** `ServicoRota` define o contrato — `calcularRota` retorna um `Future<Rota>`, `acompanhar` retorna um `Stream<PosicaoNavegacao>`. `ServicoRotaMock` implementa a versão simulada. A tela recebe o serviço por parâmetro, então trocar a implementação não exige mudança de interface.

**Cronômetro por diferença de horário.** O tempo decorrido é calculado com `DateTime.difference`, não por contagem de ticks, para permanecer correto quando o sistema operacional suspende o app com a tela desligada.

## O que está simulado

| Componente                       | Onde                                      | Substituir por                          |
| -------------------------------- | ----------------------------------------- | --------------------------------------- |
| Cálculo e acompanhamento de rota | `servicos/servico_rota.dart`              | API de rotas e `geolocator`             |
| Mapa de deslocamento             | `widgets/mapa_mock.dart`                  | `google_maps_flutter` com Polyline      |
| Mapa do trecho                   | `widgets/mapa_area.dart`                  | `google_maps_flutter` com Polygon       |
| Captura de foto                  | `execucao_page.dart`, método `_tirarFoto` | `image_picker` com `ImageSource.camera` |
| Solicitação, equipe e histórico  | `models.dart`                             | Backend                                 |

Os dois mapas exibem o selo "MAPA SIMULADO" no canto superior, que deve ser removido junto com a substituição.

## Convenções

Identificadores em Dart aceitam apenas ASCII. Nomes de variáveis, funções e classes vão sem acento (`duracaoSimulada`, `posicaoAtual`); texto exibido na interface pode ter acentuação normalmente, dentro de strings.

Cor da marca: `#5E22F3`. O tema deriva dela via `ColorScheme.fromSeed`, que clareia a cor no modo escuro. Onde o roxo exato importa, ele é aplicado diretamente.

## Próximos passos

**Integração com o backend**

- Definir o contrato da API de chamados e implementar `ServicoRotaApi implements ServicoRota`
- Substituir os dados de `models.dart` por consumo de API
- Autenticação e vínculo do operador com sua equipe

**Localização e mapas**

- Integrar `geolocator` para a posição real do veículo
- Substituir `MapaMock` e `MapaArea` por `google_maps_flutter`
- Tratar perda de sinal durante o deslocamento: política de reconexão e estado de última posição conhecida. Trecho de acostamento tem cobertura irregular e esse caso vai ocorrer com frequência

**Captura e envio de fotos**

- Integrar `image_picker` e definir armazenamento das imagens
- Fila de envio para fotos tiradas sem conectividade

**Operação offline**

- Persistência local dos registros, para que uma poda concluída sem sinal não se perca
- Sincronização quando a conexão voltar

**Escalabilidade do estado**

- Migrar `EstadoChamado` para `provider` ou `riverpod` quando houver login, múltiplos chamados simultâneos ou sincronização com servidor
- Introduzir `go_router` se cada aba passar a precisar de pilha de navegação própria

**Qualidade**

- Testes unitários para os cálculos de `PontoGeo` e para as transições de `EstadoChamado`. São funções puras e um erro nelas manda equipe ao quilômetro errado
- Validar contraste e tamanho de toque para uso a céu aberto, com luz solar direta e o operador de luvas
