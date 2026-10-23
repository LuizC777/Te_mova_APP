# te-mova

**Gestão preditiva de vegetação em rodovias concessionadas.**

O te-mova prevê quando a vegetação de um trecho vai atingir o limite regulatório, mostra ao gestor onde podar e despacha a ordem para a equipe de campo, que conclui o serviço com comprovação fotográfica.

Este repositório contém o **aplicativo da equipe de campo** e serve como documento-âncora do projeto, reunindo a proposta de solução, a stack, os links de entrega, o plano de negócio e o resumo das sprints.

Projeto desenvolvido para o Challenge Motiva — FIAP, Ciência da Computação, turma 2CCPO, Grupo 35.

---

## Sumário

- [O problema](#o-problema)
- [A solução](#a-solução)
- [Entregas e links](#entregas-e-links)
- [O aplicativo](#o-aplicativo)
- [Stack utilizada](#stack-utilizada)
- [Como rodar](#como-rodar)
- [Integração com o dashboard](#integração-com-o-dashboard)
- [Plano de negócio](#plano-de-negócio)
- [Entregas por sprint](#entregas-por-sprint)
- [Convenções de código](#convenções-de-código)
- [Limitações e próximos passos](#limitações-e-próximos-passos)
- [Equipe](#equipe)

---

## O problema

A Motiva decide hoje o corte da vegetação na faixa de domínio por inspeção visual: alguém precisa percorrer o trecho para descobrir que a vegetação já passou do limite. O método é subjetivo, periódico e reativo.

As consequências são conhecidas: deslocamento caro para inspecionar trechos que não precisavam de intervenção, poda feita cedo demais ou tarde demais, exposição da equipe à via durante as inspeções, e dificuldade de comprovar conformidade quando a fiscalização pede histórico.

Os órgãos reguladores definem gatilhos objetivos de altura. O material da Motiva cita ARTESP (Anexo 6) e ANTT (PER), com 30 cm na faixa de 4 metros e no canteiro central, e 10 cm no entorno de instalações operacionais. O te-mova adota **10 cm como limite de poda** e cria um degrau antes dele, o **alerta preventivo de 9 cm**, para que a equipe chegue antes do limite, e não depois.

## A solução

Três camadas, em três repositórios.

```
  APIs de clima          Modelo 1 (v1.3.0)         Dashboard web          App de campo
  observado + previsto   janela de 20 dias         mapa de trechos        chamado, rota,
  séries históricas  →   prevê altura em cm   →    alertas e despacho  →  execução e foto
  sazonalidade           por trecho                seleção de equipe           │
       ▲                                                                       │
       └───────────────── cada poda registrada vira dado de treino ────────────┘
```

**Mede.** Sem instalar equipamento na rodovia. O modelo consome APIs de clima observado e previsto, séries históricas por região e a sazonalidade das estações, cruzadas com o histórico de podas da própria malha.

**Prevê.** O Modelo 1 (v1.3.0) usa uma janela de 20 dias e devolve a altura da vegetação prevista em centímetros, por trecho, classificada em quatro níveis de alerta.

**Opera.** O dashboard mostra ao gestor o mapa dos trechos com os alertas e permite selecionar trecho, equipe e informações adicionais, despachando a ordem para o app. A equipe recebe o chamado, é guiada até o local, executa e conclui com foto e altura final. Cada poda concluída volta como rótulo real para o retreino do modelo.

### Níveis de alerta

| Nível | Situação | Ação |
| --- | --- | --- |
| Verde | Vegetação longe dos limites | Nenhuma |
| Amarelo | Aproximando-se do alerta preventivo | Acompanhar a tendência |
| Laranja | Altura prevista ≥ 9 cm | Antecipar a poda: gestor escolhe trecho e equipe |
| Vermelho | Altura prevista ≥ 10 cm | Ordem de poda enviada ao app da equipe |

---

## Entregas e links

| Item | Onde |
| --- | --- |
| **APK do aplicativo** | [Releases deste repositório](../../releases) |
| **Vídeo final** | https://youtu.be/nJIH66aQvEw |
| **Plano de negócio** | [PDF completo](docs/te-mova-plano-de-negocio.pdf) · [resumo neste documento](#plano-de-negócio) | |
| Repositório do dashboard | https://github.com/Senador2006/temova-dashboard |
| Repositório do modelo preditivo | https://github.com/Senador2006/temova-modelo-1 |
| Protótipo no Figma (Sprint 1) | [Abrir protótipo](https://www.figma.com/proto/DnZ2DDJSj2KItkNOfpQXNP/Sem-t%C3%ADtulo?node-id=45-44&t=PADFZAE2H7RRAnNQ-1) |

O histórico completo das entregas anteriores está em [Entregas por sprint](#entregas-por-sprint).

---

## O aplicativo

Aplicativo Flutter usado pela equipe de roçada em campo. Recebe chamados do dashboard, conduz a equipe até o trecho designado, acompanha a execução e registra o resultado com comprovação fotográfica.

### Telas

**Home.** Lista os chamados enviados pelo dashboard, cada um com horário da solicitação, altura da vegetação medida contra o limite de 10 cm, urgência, quilômetro e equipe designada. A barra de altura muda para amarelo ao ultrapassar 80% do limite. Chamados recém-chegados recebem a etiqueta **NOVO**. Uma faixa no topo indica o estado da sincronização com o dashboard. Conforme o chamado avança, a mesma aba passa a mostrar a navegação ou a execução.

**Rota.** Instrução de manobra no topo, mapa com o traçado e o veículo em deslocamento, e painel com distância, tempo restante e horário previsto de chegada.

**Execução.** Cronômetro contínuo, mapa focado no trecho designado com a faixa de acostamento destacada, e as opções de interromper ou concluir. A conclusão exige foto e registro da altura final.

**Equipe.** Operadores da equipe, com destaque para o encarregado, além do modelo e placa do veículo.

**Histórico.** Registros agrupados por mês e por dia, em cards compactos com horário, duração, altura final, equipe e quilômetro. Serviços em andamento aparecem no topo com borda colorida.

### Fluxo do serviço

O chamado percorre quatro estados, definidos em `StatusPoda`. Cada transição é reportada ao dashboard.

| Estado | Status na API | Cor no histórico | Como se chega |
| --- | --- | --- | --- |
| Em deslocamento | `confirmada` | Amarelo | Operador aceita o chamado |
| Em progresso | `em_andamento` | Amarelo | Equipe confirma chegada ao local |
| Interrompida | `interrompida` | Vermelho | Cancelamento em qualquer ponto |
| Concluída | `concluida` | Verde | Poda finalizada com foto |

Um chamado interrompido volta para a lista de disponíveis e pode ser retomado. Cada aceite gera um registro próprio no histórico — tentativas anteriores não são sobrescritas, para preservar o rastro de auditoria.

### Modo de demonstração

O app consome os chamados do dashboard por sincronização. Para permitir avaliar o aplicativo isoladamente, sem subir o dashboard e a API, existe um gerador local de chamados.

Há dois caminhos para acioná-lo:

- O botão **Gerar chamado de demonstração**, exibido na tela inicial quando não há nenhum chamado disponível.
- Toque longo sobre o nome **te-mova**, na barra superior, a partir de qualquer aba.

O chamado gerado tem rodovia, quilômetro, altura e urgência sorteados, e se identifica no próprio card como chamado de demonstração. A partir dele o fluxo completo funciona normalmente: aceitar, navegar, executar e concluir com foto.

Internamente, esses chamados recebem um identificador com o prefixo `demo-`. Isso faz com que a sincronização os preserve ao atualizar a lista e impede que o app reporte o status deles a um chamado que o servidor não conhece. A faixa de sincronização continua indicando o estado real da conexão.

### Arquitetura

**Estado compartilhado.** `EstadoChamado` é um `ChangeNotifier` global, consumido por `ListenableBuilder` na Home e no Histórico. Concentra a máquina de estados do chamado, o cronômetro e a sincronização. É suficiente para um atendimento por vez.

**Sincronização por polling.** O app consulta `/ops/inbox` a cada 2 segundos e compara uma assinatura do conteúdo antes de reconstruir a lista, evitando repintura desnecessária. Falha de rede não derruba o estado local: o `catch` apenas marca a conexão como ausente e preserva o que já estava em memória.

**Dados geográficos reais.** `PontoGeo` guarda latitude e longitude de verdade, e a distância entre pontos usa a fórmula de Haversine. Os mapas são desenhados com `CustomPainter`; as coordenadas não são fictícias.

**Serviço de rotas por interface.** `ServicoRota` define o contrato — `calcularRota` retorna um `Future<Rota>`, `acompanhar` retorna um `Stream<PosicaoNavegacao>`. `ServicoRotaMock` implementa a versão simulada. A tela recebe o serviço por parâmetro, então trocar a implementação não exige mudança de interface.

**Cronômetro por diferença de horário.** O tempo decorrido é calculado com `DateTime.difference`, não por contagem de ticks, para permanecer correto quando o sistema operacional suspende o app com a tela desligada.

### Estrutura

```
lib/
├── main.dart                      Tema, casca de navegação e atalho de demonstração
├── models.dart                    Solicitação, equipe, operador, poda, formatação pt-BR
├── config/
│   └── api.dart                   Endereços da API e do dashboard, overrides de build
├── models/
│   └── rota.dart                  Geolocalização, rota, navegação
├── estado/
│   └── estado_chamado.dart        Máquina de estados, sincronização e histórico
├── servicos/
│   ├── servico_sync.dart          Cliente HTTP do dashboard (/ops)
│   └── servico_rota.dart          Interface de rotas e implementação simulada
├── widgets/
│   ├── mapa_mock.dart             Mapa de deslocamento
│   └── mapa_area.dart             Mapa do trecho a roçar
└── pages/
    ├── home_page.dart             Lista de chamados, rota ou execução
    ├── rota_page.dart             Navegação até o local
    ├── execucao_page.dart         Cronômetro e conclusão do serviço
    ├── equipe_page.dart           Operadores e veículo
    └── historico_page.dart        Registros agrupados por dia e mês
```

### O que é real e o que é simulado

| Componente | Estado | Onde |
| --- | --- | --- |
| Integração com o dashboard | **Real** | `servicos/servico_sync.dart` |
| Máquina de estados e histórico | **Real** | `estado/estado_chamado.dart` |
| Dados geográficos e distâncias | **Real** | `models/rota.dart` |
| Cálculo e acompanhamento de rota | Simulado | `servicos/servico_rota.dart` → API de rotas e `geolocator` |
| Mapa de deslocamento | Simulado | `widgets/mapa_mock.dart` → `google_maps_flutter` com Polyline |
| Mapa do trecho | Simulado | `widgets/mapa_area.dart` → `google_maps_flutter` com Polygon |
| Captura de foto | Simulado | `execucao_page.dart`, método `_tirarFoto` → `image_picker` |
| Equipe e histórico anterior | Simulado | `models.dart` → backend |

Os mapas exibem o selo "MAPA SIMULADO", que deve ser removido junto com a substituição.

---

## Stack utilizada

### Aplicativo de campo (este repositório)

| Item | Escolha | Por quê |
| --- | --- | --- |
| Framework | Flutter (Dart SDK `^3.12.2`) | Binário Android gerado localmente, sem serviço de build em nuvem |
| Interface | Material 3, tema escuro derivado de `#5E22F3` | Legibilidade a céu aberto e identidade da marca |
| Estado | `ChangeNotifier` + `ListenableBuilder` | Suficiente para um atendimento por vez, sem dependência externa |
| Rede | `http` `^1.2.2` | Única dependência externa do projeto |
| Mapas | `CustomPainter` | Desenho próprio enquanto a integração com mapas reais não entra |
| Lint | `flutter_lints` `^6.0.0` | Padrão da comunidade |
| Distribuição web | Docker multi-stage + nginx | Deploy no Render, consumido pelo dashboard |

### Dashboard gerencial

Aplicação web em Vite, servida em `http://127.0.0.1:5173`, com proxy `/api` apontando para a API do modelo. Marca te-mova, cores `#ffffff` e `#6047ec`. Repositório: [temova-dashboard](https://github.com/Senador2006/temova-dashboard).

Organizado em quatro áreas: dados de clima e monitoramento, designação de tarefas às equipes, mapa de previsão por trecho, e o teste de campo REAL001.

### Modelo preditivo

API servida em `http://127.0.0.1:8000`, compartilhada entre o dashboard e o app sob o prefixo `/ops`. Repositório: [temova-modelo-1](https://github.com/Senador2006/temova-modelo-1).

O Modelo 1 (v1.3.0) recebe uma janela de 20 dias por trecho, com altura recente, variáveis de clima e sazonalidade, e devolve a altura prevista em centímetros para o fim da janela.

### Por que Flutter, se a Sprint 2 foi em React Native

A Sprint 2 foi entregue em React Native com Expo, conforme a stack definida na Sprint 1. Na Sprint 3 o projeto migrou para Flutter. Três motivos sustentaram a decisão:

**Distribuição.** A entrega precisa de um APK instalável direto pelo avaliador. No fluxo gerenciado do Expo, gerar um binário próprio depende de serviço de build em nuvem e de configuração adicional. Em Flutter, `flutter build apk --release` produz o arquivo localmente, em um comando.

**Interface desenhada à mão.** As telas de mapa são desenhadas ponto a ponto, com projeção de coordenadas reais. Flutter renderiza com motor próprio, o que dá resultado idêntico em qualquer aparelho e eliminou o ajuste por plataforma que esse tipo de desenho costuma exigir.

**Superfície de dependências.** O app hoje tem uma única dependência externa — `http`. Menos pacotes significa menos pontos de quebra na semana da entrega e menos tempo gasto com instalação por quem for avaliar.

---

## Como rodar

### Apenas o aplicativo

```bash
flutter pub get
flutter run
```

Um clone novo **sempre** precisa do `flutter pub get` antes de abrir no editor. Sem ele, os pacotes não estão resolvidos e o analisador acusa erro em praticamente todas as linhas.

Sem o dashboard no ar, use o botão **Gerar chamado de demonstração** na tela inicial para percorrer o fluxo completo.

Para prototipar só a interface, sem emulador:

```bash
flutter run -d chrome --web-port=5050
```

A porta `5050` importa: é onde o dashboard procura o app.

### Gerar o APK

```bash
flutter build apk --release
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`.

### O conjunto completo

Três serviços, cada um em um terminal:

```bash
# 1. API do Modelo 1 — repositório temova-modelo-1
#    sobe em http://127.0.0.1:8000

# 2. Dashboard — repositório temova-dashboard
cd dashboard
npm install
npm run dev
#    sobe em http://127.0.0.1:5173

# 3. App de campo — este repositório
flutter run -d chrome --web-port=5050
```

Com os três no ar, o dashboard despacha um trecho para a equipe e o chamado aparece no app em até 2 segundos.

### Requisitos

- Flutter SDK com Dart `^3.12.2`
- Android SDK, via Android Studio, para gerar o APK
- Node.js, para o dashboard
- Modo desenvolvedor do Windows ativado, se for rodar como app de desktop

O aviso de Visual Studio ausente no `flutter doctor` não impede nada: ele só é necessário para compilar o app como programa de Windows.

---

## Integração com o dashboard

O app conversa com a API do modelo sob o prefixo `/ops`.

| Método | Rota | Uso |
| --- | --- | --- |
| `GET` | `/ops/inbox` (ou `/ops/state`) | Busca o snapshot de chamados a cada 2 segundos |
| `POST` | `/ops/presence` | Anuncia que o app está no ar, com a URL e a equipe |
| `PATCH` | `/ops/dispatches/{id}` | Reporta mudança de status, altura final e foto |

O snapshot traz `version` e a lista `dispatches`. Cada item é convertido em `ChamadoRemoto` por `ChamadoRemoto.fromJson`, que mapeia `crescimentoCm` para a altura, `limitePodaCm` para o limite e `nivelAlerta` para a urgência exibida.

### Endereços

Definidos em `lib/config/api.dart`:

| Constante | Valor padrão | O que é |
| --- | --- | --- |
| `appPort` / `appBase` | `5050` / `http://127.0.0.1:5050` | Onde o dashboard procura o app |
| `dashBase` | `http://127.0.0.1:5173` | Dashboard gerencial |
| `apiBase` | `http://127.0.0.1:8000` | API do Modelo 1 |

Para apontar o app a outro endereço, use `--dart-define` no build ou no run:

```bash
flutter run --dart-define=API_BASE=http://192.168.0.10:8000
```

Em emulador Android, `127.0.0.1` se refere ao próprio emulador, então `resolveApiBase()` troca automaticamente para `10.0.2.2`. Se nenhum endereço funcionar, `apiBasesCandidatas()` tenta uma lista de alternativas até encontrar o `/ops` correto.

---

## Plano de negócio

### Proposta de valor

O te-mova vende a decisão de poda no momento certo, com prova — sem exigir obra, instalação ou equipamento na faixa de domínio.

| Dor da Motiva hoje | O que o te-mova entrega |
| --- | --- |
| Inspeção visual periódica para saber o estado de cada trecho | Previsão com 20 dias de antecedência, em mapa com os trechos em risco destacados |
| Poda antecipada (desperdício) ou atrasada (risco e multa) | Alerta preventivo em 9 cm e ordem de poda em 10 cm, alinhados ao limite regulatório |
| Despacho manual, sem rastreio do que foi feito | Ordem enviada do dashboard ao app, com status ao vivo |
| Comprovação frágil em auditoria | Conclusão com foto, altura final, km, data e hora |
| Soluções de monitoramento exigem investimento e obra na via | Operação apenas em software: cobertura da malha sem CAPEX |

### Público-alvo

**Cliente âncora:** Motiva, com obrigação de roçada definida no PER/ANTT e em contratos ARTESP.
**Mercado próximo:** demais concessionárias rodoviárias sujeitas às mesmas exigências.
**Mercado adjacente:** ferrovias, metrôs e aeroportos — setores em que a própria Motiva atua — e prefeituras, para poda urbana.

Os usuários diários são o gestor de conservação, no dashboard, e o líder da equipe de poda, no app. A área de compliance usa o histórico como evidência para fiscalização.

### Modelo de receita

SaaS puro, com núcleo em assinatura recorrente. Sem hardware, não há equipamento a vender nem parque a manter: a concessionária entra sem investimento de capital e paga pela malha efetivamente coberta.

| Linha | Formato | Referência | Natureza |
| --- | --- | --- | --- |
| Onboarding | Cadastro dos trechos, carga do histórico, calibração regional, integração e treinamento | R$ 15.000 a R$ 25.000 por contrato | Única |
| Assinatura te-mova | Por quilômetro monitorado/mês. Inclui dashboard, app, modelo, retreino e suporte | R$ 60 a R$ 90 por km/mês | Recorrente mensal |
| Módulos adicionais | Integração com o sistema de O&M, relatórios regulatórios, API de dados | Negociado por contrato | Projeto + recorrente |
| Licença white-label | Operadores de outros modais com marca própria | Licença anual + valor por km | Recorrente anual |

### Custos estimados de operação

Cenário de piloto com 100 km monitorados. Como a solução é inteiramente em software, não há hardware, instalação nem manutenção de campo.

| Item | Estimativa mensal |
| --- | --- |
| Equipe técnica (alocação parcial) | R$ 18.000 |
| Comercial e administrativo | R$ 3.500 |
| Nuvem e hospedagem | R$ 1.800 |
| APIs de clima e dados históricos | R$ 1.200 |
| **Total** | **≈ R$ 24.500/mês** |

A 100 km e R$ 75 por km/mês, a receita do piloto fica em torno de R$ 7.500/mês, abaixo do custo. Isso é esperado: o custo é quase todo fixo e se dilui com a escala. O equilíbrio fica por volta de **330 km monitorados** no mesmo preço, patamar compatível com a malha de uma única concessionária.

A diferença em relação a uma solução com sensores é que a expansão não custa nada aos dois lados. Ampliar de 100 para 500 km não exige comprar equipamento nem fazer visita técnica — exige cadastrar os trechos. Isso torna realista propor um piloto curto seguido de expansão rápida, em vez de implantação por lotes limitada pelo orçamento de investimento.

### Diferenciais competitivos

| Alternativa | Limite dela |
| --- | --- |
| Inspeção visual | Subjetiva e cara em deslocamento; só detecta o problema depois de instalado |
| Roçada por cronograma fixo | Corta trechos que não precisavam e deixa passar os que cresceram mais rápido |
| Satélite / índice NDVI | Cobertura de nuvens, baixa resolução temporal, não entrega altura em centímetros |
| Drone de varredura | Autonomia, custo operacional e exigências da ANAC |
| Sensores IoT na faixa de domínio | Investimento por ponto, instalação, manutenção, energia, furto e vandalismo |

Os diferenciais estruturais são o **ciclo fechado de dados** — cada poda registrada retreina o modelo por região e por estação, e esse histórico é a verdadeira barreira de entrada do negócio —, a **ancoragem regulatória** do gatilho, o **CAPEX zero** e a entrega de uma **operação completa**, e não de um relatório.

### Principais riscos

| Risco | Mitigação |
| --- | --- |
| Validação de campo ainda limitada a um ensaio | Piloto com metas de acurácia por região e retreino contínuo |
| O modelo infere sem observar o trecho diretamente | A altura registrada em cada poda corrige o modelo; alerta preventivo dá margem |
| Partida a frio em região sem histórico | Calibração com séries históricas e margem conservadora até acumular podas |
| Dependência de APIs externas de clima | Múltiplas fontes em paralelo e séries armazenadas localmente |
| Baixa barreira técnica de entrada | Defesa no histórico acumulado e na integração com a operação da concessionária |
| Dependência de um cliente âncora único | Replicação para outras concessionárias e modais adjacentes |

### Impacto esperado

**Para a Motiva:** redução do deslocamento de inspeção e do corte desnecessário; menos inspetores expostos na via; histórico datado e georreferenciado pronto para auditoria; adoção sem investimento de capital, por ser decisão de custeio.

**Para as rodovias e a sociedade:** faixa de domínio com visibilidade preservada, menor risco de incêndio em vegetação seca, poda apenas quando necessária e um padrão replicável de manutenção preditiva para outros modais.

> A versão completa, com personas detalhadas, análise de riscos e indicadores propostos para o piloto, está em [docs/te-mova-plano-de-negocio.pdf](docs/te-mova-plano-de-negocio.pdf).

---

## Entregas por sprint

| Sprint | Foco | Entregas |
| --- | --- | --- |
| 1 | Descoberta e protótipo | Levantamento de requisitos, persona, stack e protótipo navegável |
| 2 | App funcional com mocks | Aplicativo React Native/Expo, mocks e primeiro vídeo |
| 3 | Todos os fluxos implementados | Migração para Flutter, fluxo completo e vídeo de demonstração |
| 4 | Integração e entrega final | Dashboard, modelo preditivo, APK, plano de negócio e vídeo final |

### Sprint 1 — Descoberta e protótipo

Compreensão do fluxo operacional de conservação de rodovias da Motiva: o papel das frentes de conservação, as exigências regulatórias da ARTESP e da ANTT, e os atores envolvidos — operadores de campo, supervisores e gestores.

A partir daí, definição da persona principal e do problema específico a resolver, levantamento dos requisitos funcionais e não funcionais, escolha justificada da stack e tradução dos requisitos em um protótipo navegável de alta fidelidade.

- Repositório: https://github.com/LucasFortes013/challenge-sprint
- Protótipo: [Figma](https://www.figma.com/proto/DnZ2DDJSj2KItkNOfpQXNP/Sem-t%C3%ADtulo?node-id=45-44&t=PADFZAE2H7RRAnNQ-1)

### Sprint 2 — Aplicativo funcional com dados simulados

Desenvolvimento do app em React Native com Expo, com navegação implementada e módulo de mocks representando os cenários principais: lista de ocorrências, trechos da rodovia, status de vegetação e registros de inspeção. Pelo menos um fluxo completo funcional, em que a ação do usuário atualiza o estado da interface de forma coerente.

- Repositório: https://github.com/PNoronhaS/motiva-app
- Vídeo: https://youtu.be/mmm1DhQ1v28

### Sprint 3 — Todos os fluxos implementados

Aplicação com todos os fluxos funcionando. Nesta sprint o projeto migrou de React Native para Flutter, pelos motivos descritos em [Por que Flutter](#por-que-flutter-se-a-sprint-2-foi-em-react-native).

Foram implementados o ciclo completo do chamado — aceite, deslocamento, execução e conclusão com foto —, a máquina de estados com registro de tentativas para auditoria, os mapas desenhados sobre coordenadas reais e o histórico agrupado por dia e mês.

- Repositório: https://github.com/LuizC777/Te_mova_APP_sprint3
- Vídeo: https://youtu.be/HpAbXtI7Gqk

### Sprint 4 — Integração e entrega final

Substituição dos dados simulados pela integração real entre as três camadas do projeto. O dashboard passou a despachar chamados para o app, o app a reportar cada mudança de status de volta, e o modelo preditivo a alimentar os alertas por trecho.

Entregas desta sprint:

- Integração do app com a API do Modelo 1 por sincronização contínua (`/ops`)
- Dashboard gerencial com mapa de trechos, alertas e designação de equipes
- Modo de demonstração no app, para avaliação sem depender do dashboard no ar
- APK de release, publicado nas [Releases deste repositório](../../releases)
- Plano de negócio, consolidado [neste documento](#plano-de-negócio)
- Vídeo final: https://youtu.be/nJIH66aQvEw

---

## Convenções de código

**Identificadores sem acento.** Dart aceita apenas ASCII em identificadores. Nomes de variáveis, funções e classes vão sem acentuação (`duracaoSimulada`, `posicaoAtual`); texto exibido na interface pode ter acentuação normalmente, dentro de strings.

**Cor da marca.** `#5E22F3`. O tema deriva dela via `ColorScheme.fromSeed`, que clareia a cor no modo escuro. Onde o roxo exato importa, ele é aplicado diretamente.

**`Color.withValues()`.** O código usa a API que substituiu `withOpacity()` a partir do Flutter 3.27. Em SDK anterior, trocar as chamadas por `withOpacity()` resolve.

---

## Limitações e próximos passos

### O que ainda não está resolvido

- Localização e mapas são simulados; a posição do veículo não vem de GPS real
- A captura de foto não usa a câmera do dispositivo
- Não há persistência local: uma poda concluída sem sinal se perde ao fechar o app
- Não há autenticação nem vínculo entre operador e equipe
- O estado suporta um atendimento por vez

### Evolução prevista

**Localização e mapas.** Integrar `geolocator` para a posição real e substituir `MapaMock` e `MapaArea` por `google_maps_flutter`. Tratar perda de sinal durante o deslocamento com política de reconexão e última posição conhecida — trecho de acostamento tem cobertura irregular e esse caso vai ocorrer com frequência.

**Captura e envio de fotos.** Integrar `image_picker`, definir o armazenamento das imagens e criar fila de envio para fotos tiradas sem conectividade.

**Operação offline.** Persistência local dos registros e sincronização quando a conexão voltar.

**Escalabilidade do estado.** Migrar `EstadoChamado` para `provider` ou `riverpod` quando houver login, múltiplos chamados simultâneos ou sincronização bidirecional. Introduzir `go_router` se cada aba passar a precisar de pilha de navegação própria.

**Qualidade.** Testes unitários para os cálculos de `PontoGeo` e para as transições de `EstadoChamado`. São funções puras, e um erro nelas manda equipe ao quilômetro errado. Validar contraste e tamanho de toque para uso a céu aberto, com luz solar direta e o operador de luvas.

---

## Equipe

Grupo 35 — Ciência da Computação, turma 2CCPO.

| Integrante | RM |
| --- | --- |
| Gabriel Nacarelli Pinheiro | 565298 |
| Lucas Franco de Godoy Fortes | 561723 |
| Luiz Claro Lima | 563014 |
| Pedro Mitsuo Risardi Nisiaymamoto | 561710 |
| Pedro Noronha dos Santos | 564572 |
| Rafael Silva Oliveira Nascimento | 565415 |
| Thiago Ono Sakai | 563448 |
