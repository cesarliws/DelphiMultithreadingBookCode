# Delphi Multithreading: Threads, Concorrência, Paralelismo e Assincronismo - Código-Fonte Oficial

> **English Edition Repository**
>
> [https://github.com/cesarliws/DelphiMultithreadingBookCodeEnglishEdition](https://github.com/cesarliws/>DelphiMultithreadingBookCodeEnglishEdition)

Este repositório contém todo o código-fonte dos exemplos práticos do livro **"Delphi Multithreading: Threads, Concorrência, Paralelismo e Assincronismo"**, escrito por Cesar Romero.

## 📖 Sobre o Livro

A interface travada durante uma operação demorada é o inimigo silencioso de qualquer aplicação moderna. Este livro é o mapa definitivo para dominar a programação concorrente em Delphi, guiando o leitor desde os fundamentos da `TThread` clássica até a maestria da moderna *Parallel Programming Library* (PPL).

Baseado em 30 anos de experiência em arquitetura de software, esta obra foi projetada para ser um curso de formação completo, tanto para o programador que está dando seus primeiros passos em *threads* quanto para o arquiteto que busca otimizar a performance em cenários de alta demanda. Ao final desta jornada, você terá a confiança e a visão arquitetural para projetar e construir aplicações Delphi que não apenas funcionam, mas que encantam o usuário com sua performance e responsividade.

![Delphi Multithreading - Book Cover](./cover.jpg)

## 🛒 Onde Comprar

O livro está disponível em formato impresso em diversas lojas ao redor do mundo.

**Principal Loja para o Brasil (Impressão Nacional):**

  * **[Clique aqui para comprar no Clube de Autores](https://clubedeautores.com.br/livro/delphi-multithreading)**

| Loja | Link |
| :--- | :--- |
| **🇧🇷 Clube de Autores (Brasil)** | **[https://clubedeautores.com.br/livro/delphi-multithreading](https://clubedeautores.com.br/livro/delphi-multithreading)** |
| 🇺🇸 Amazon.com (USA) | [https://www.amazon.com/dp/6501752515](https://www.amazon.com/dp/6501752515) |
| 🇨🇦 Amazon.ca (Canadá) | [https://www.amazon.ca/dp/6501752515](https://www.amazon.ca/dp/6501752515) |
| 🇬🇧 Amazon.co.uk (Reino Unido) | [https://www.amazon.co.uk/dp/6501752515](https://www.amazon.co.uk/dp/6501752515) |
| 🇩🇪 Amazon.de (Alemanha) | [https://www.amazon.de/dp/6501752515](https://www.amazon.de/dp/6501752515) |
| 🇫🇷 Amazon.fr (França) | [https://www.amazon.fr/dp/6501752515](https://www.amazon.fr/dp/6501752515) |
| 🇪🇸 Amazon.es (Espanha) | [https://www.amazon.es/dp/6501752515](https://www.amazon.es/dp/6501752515) |
| 🇮🇹 Amazon.it (Itália) | [https://www.amazon.it/dp/6501752515](https://www.amazon.it/dp/6501752515) |
| 🇳🇱 Amazon.nl (Holanda) | [https://www.amazon.nl/dp/6501752515](https://www.amazon.nl/dp/6501752515) |
| 🇵🇱 Amazon.pl (Polônia) | [https://www.amazon.pl/dp/6501752515](https://www.amazon.pl/dp/6501752515) |
| 🇧🇪 Amazon.com.be (Bélgica) | [https://www.amazon.com.be/dp/6501752515](https://www.amazon.com.be/dp/6501752515) |
| 🇮🇪 Amazon.ie (Irlanda) | [https://www.amazon.ie/dp/6501752515](https://www.amazon.ie/dp/6501752515) |
| 🇦🇺 Amazon.com.au (Austrália) | [https://www.amazon.com.au/dp/6501752515](https://www.amazon.com.au/dp/6501752515) |

O livro também é distribuído pelo Clube de Autores para: **Equador, México, Nova Zelândia e Portugal**.

-----

## 🚀 Sobre os Projetos

Este repositório está organizado em pastas por capítulo, correspondendo à estrutura do livro. Cada projeto de exemplo foi cuidadosamente criado para demonstrar um conceito específico de concorrência de forma prática e isolada.

  * **Capítulo 1: Introdução ao Processamento Concorrente e Assíncrono**

      * Demonstra o problema do "UI Freeze" e introduz os conceitos teóricos fundamentais.

  * **Capítulo 2: Fundamentos de Threads em Delphi (`TThread` básico)**

      * Exemplos práticos de criação, gerenciamento de ciclo de vida e comunicação segura com a UI usando `Synchronize` e `Queue`.

  * **Capítulo 3: Sincronização de Threads**

      * Projetos que demonstram o uso de cada primitiva de sincronização: `TCriticalSection`, `TMonitor`, `TMutex`, `TSemaphore`, `TEvent`, `TLightweightMREW`, `TCountdownEvent` e `WaitForMultipleObjects`.

  * **Capítulo 4: Gerenciamento e Cancelamento de Threads**

      * Implementação de padrões para pausa, retomada e cancelamento cooperativo (`Terminate`, `TCancellationToken`), além de estratégias de tratamento de exceções e *retry*.

  * **Capítulo 5: Alternativas Assíncronas**

      * Exploração de técnicas de assincronismo que vão além da `TThread`, incluindo comunicação via `PostMessage` e o padrão *Pub/Sub* com `System.Messaging`.

  * **Capítulo 6: Parallel Programming Library (PPL)**

      * Demonstrações do poder da PPL com `TTask`, `IFuture<T>`, `TParallel.For` e a coordenação de múltiplas tarefas.

  * **Capítulo 7: Tópicos Avançados em Threads**

      * Projetos que exploram a construção de um *pool* de *threads* personalizado, o uso de `TInterlocked` para performance extrema e o gerenciamento avançado da PPL.

  * **Capítulo 8: Melhores Práticas e Depuração**

      * Exemplos que consolidam as melhores práticas de arquitetura, como o desacoplamento de *threads*, o uso de `threadvar` e a prevenção de *deadlocks*.

  * **Capítulo 9: Threads em Aplicações Mobile (Android e iOS)**

      * Projetos FMX que resolvem desafios do mundo real, como requisições REST paralelas e o processamento de imagens da galeria sem travar a UI.

  * **Capítulo 10: Exemplos Úteis com PPL**

      * Implementação de padrões de arquitetura complexos, como processamento de arquivos em lote, consumo de APIs paginadas e *pipelines* com máquina de estado.

  * **Capítulo 11: Aplicações Práticas de Banco de Dados**

      * A culminação do livro: um projeto completo que demonstra uma arquitetura concorrente de nível sênior para acesso a banco de dados, usando PPL, Repository, Factory e Injeção de Dependência.

## 📚 Conteúdo Completo do Livro

Aqui está o sumário detalhado da obra.

#### 1: Introdução ao Processamento Concorrente e Assíncrono

  * 1.1 - O Problema do Congelamento da Interface (UI Freeze)
  * 1.2 - O que é Processamento Concorrente e Assíncrono?
  * 1.3 - Uma Breve História da Concorrência: Da TThread à PPL
  * 1.4 - Os Verdadeiros Objetivos da Concorrência
  * 1.5 - O Conceito de Thread
  * 1.6 - Quando NÃO usar Threads (e buscar alternativas)

#### 2: Fundamentos de Threads em Delphi (TThread básico)

  * 2.1 - Criando e Gerenciando Threads Simples
  * 2.2 - Comunicando com a Thread Principal (Synchronize e Queue)
  * 2.3 - Lidando com Múltiplas Threads e Dados Compartilhados
  * 2.4 - Threads Anônimas (TThread.CreateAnonymousThread)

#### 3: Sincronização de Threads

  * 3.1 - TCriticalSection - Aprofundando na Exclusão Mútua Simples
  * 3.2 - TMonitor - Sincronização de Múltiplas Threads
  * 3.3 - TMutex - Sincronização entre Processos
  * 3.4 - TSemaphore - Controle de Acesso a Recursos Limitados
  * 3.5 - TEvent - Sinalização entre Threads
  * 3.6 - Otimizando Acesso Concorrente: O Padrão Leitores-Escritores
  * 3.7 - TCountdownEvent - Sincronizando a Conclusão de Múltiplas Tarefas
  * 3.8 - WaitForMultipleObjects: Espera Coordenada

#### 4: Gerenciamento e Cancelamento de Threads

  * 4.1 - Início e Pausa Controlada de Threads
  * 4.2 - Cancelamento Gentil de Threads (Terminate e WaitFor)
  * 4.3 - Cancelamento Cooperativo com TCancellationToken
  * 4.4 - Gerenciando a Prioridade de Execução (TThread.Priority)
  * 4.5 - Tratamento de Exceções em Threads
  * 4.6 - Estratégias de Reprocessamento e Retry em Threads

#### 5: Alternativas Assíncronas

  * 5.1 - PostMessage e SendMessage
  * 5.2 - I/O Assíncrono (Visão Geral)
  * 5.3 - Integração de I/O Assíncrono com Threads
  * 5.4 - Padrão de Execução Assíncrona na Main Thread
  * 5.5 - Comunicação via System.Messaging

#### 6: Parallel Programming Library (PPL)

  * 6.1 - Introdução à PPL
  * 6.2 - O Coração da PPL: ITask para Ações e IFuture\<T\> para Resultados
  * 6.3 - TParallel.For - Paralelizando Loops
  * 6.4 - Coordenação de Tarefas (WaitForAll, WaitForAny)
  * 6.5 - Cancelamento de Tarefas PPL
  * 6.6 - Outros Recursos da PPL: TParallelArray

#### 7: Tópicos Avançados em Threads

  * 7.1 - Criando um Thread Pool Personalizado
  * 7.2 - TInterlocked - Operações Atômicas
  * 7.3 - Gerenciamento de Memória e Multithreading
  * 7.4 - Gerenciamento Avançado da PPL
  * 7.5 - Sincronização Condicional: TConditionVariableCS

#### 8: Melhores Práticas e Depuração

  * 8.1 - Organização do Código
  * 8.2 - Evitando Concorrência com threadvar
  * 8.3 - Coleções Thread-Safe
  * 8.4 - Prevenção de Deadlocks e Race Conditions
  * 8.5 - Técnicas para Minimizar Trocas de Contexto
  * 8.6 - Depuração de Aplicações Multithreaded
  * 8.7 - Problemas Comuns e Como Resolvê-los
  * 8.8 - Recomendações Finais

#### 9: Threads em Aplicações Mobile (Android e iOS)

  * 9.1 - Introdução à Concorrência em Mobile
  * 9.2 - Prevenção de ANRs no Android
  * 9.3 - Concorrência no iOS: Regras e APIs
  * 9.4 - Cuidados Específicos de Cada Plataforma
  * 9.5 - Evolução dos Recursos para Threads Mobile
  * 9.6 - Requisições REST Paralelas
  * 9.7 - Lendo e Processando Imagens da Galeria
  * 9.8 - Processamento em Lote para Máxima Velocidade
  * 9.9 - Recomendações Finais para Mobile

#### 10: Exemplos Úteis com PPL

  * 10.1 - Processamento Paralelo de Múltiplos Arquivos
  * 10.2 - Requisições de Rede Assíncronas com Paginação
  * 10.3 - Simulações e Cálculos Intensivos
  * 10.4 - Orquestração de Fluxos de Trabalho Complexos
  * 10.5 - Pipeline de Tarefas com Máquina de Estado

#### 11: Aplicações Práticas de Banco de Dados

  * 11.1 - Os Princípios Inegociáveis (A Doutrina)
  * 11.2 - Exemplo Essencial: TDataModule em uma TThread
  * 11.3 - Otimização com Connection Pooling do FireDAC
  * 11.4 - Alternativa Sem Threads: Execução Assíncrona (amAsync)
  * 11.5 - Arquitetura Concorrente Completa com PPL
  * 11.6 - Considerações Específicas para DBExpress

#### Apêndice

  * Apêndice A: Guia Rápido das Primitivas de Sincronização

## 🐞 Feedback e Contribuições

Este livro e seu código-fonte são feitos para a comunidade. Seu feedback é fundamental\!

  * **Para Problemas no Código-Fonte:** Se encontrar um bug, uma dificuldade para compilar, ou tiver uma sugestão de melhoria nos exemplos, por favor, **abra uma Issue** neste repositório.
  * **Para Erros no Texto do Livro:** Se encontrar um erro de digitação, uma explicação que não ficou clara, ou uma imprecisão técnica no conteúdo do livro, por favor, envie um e-mail para **delphimultithreadingbook@gmail.com**.

## 👨‍💻 Sobre o Autor

**Cesar Romero** é Arquiteto de Software, Embarcadero MVP e um veterano com quase 30 anos de experiência na plataforma Delphi. Palestrante e instrutor, é especialista em projetar sistemas de alta performance para Desktop, Cloud e Mobile, compartilhando ativamente seu conhecimento com a comunidade de desenvolvedores.
