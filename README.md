# Automação de Relatório Gerencial — Setor Saúde

Case de automação de relatórios gerenciais para um cliente do setor de saúde com 8+ unidades, reduzindo o tempo de entrega de 5 dias para 1 dia.

## Contexto

O cliente enfrentava um ciclo manual e repetitivo de produção de relatórios gerenciais mensais, consolidando dados de múltiplas unidades. O processo era lento, sujeito a erros humanos e consumia tempo desproporcional da equipe analítica.

## Solução

- Reestruturação do fluxo de coleta e tratamento de dados com Power Query
- Automação de etapas manuais com apoio de Inteligência Artificial Generativa
- Padronização de nomenclaturas e formatos entre as 8+ unidades
- Estruturação de um modelo replicável, reduzindo dependência de retrabalho manual mês a mês

## Resultado

Redução de 80% no tempo de entrega, de 5 dias para 1 dia, mantendo a qualidade e a consistência analítica do relatório final.

## Tecnologias

- Power BI
- Power Query
- IA Generativa
- SQL

## Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| `dados_relatorio_gerencial_saude.xlsx` | Base de apoio: amostras do formato bruto recebido de cada unidade (antes da padronização), a base já padronizada (8 unidades x 12 meses) e um painel de indicadores calculado por fórmulas |
| `script_consolidacao_relatorio_gerencial.sql` | Script SQL (staging, dimensões, tabela fato e view) que reproduz a mesma padronização em nível de banco de dados |
| `medidas_dax.dax` | Medidas DAX do modelo Power BI: receita, glosa, margem, ocupação, comparativos de período e ranking entre unidades |
| `guia_powerbi_automacao_relatorio_gerencial.docx` | Guia passo a passo: conexão via Excel ou SQL, transformações no Power Query, modelagem em estrela, medidas DAX e o ponto de entrada da IA Generativa |
| `resumo_executivo_analise.docx` | Exemplo do texto gerado pela camada de IA Generativa: leitura dos indicadores, achados por unidade e recomendações |
| `mockup_dashboard_powerbi.svg` | Prévia visual do relatório no Power BI, construída com os números reais da base padronizada |
| `dicionario_dados.md` | Definição de cada tabela e coluna usada no Excel e no modelo SQL/Power BI |
| `diagrama_fluxo_automacao.svg` | Diagrama do fluxo completo, da fonte bruta ao relatório publicado |


## Fluxo da solução

Fontes brutas (8+ unidades, formatos divergentes) → Padronização (Power Query e/ou SQL) → Modelo Power BI (esquema estrela) → Medidas DAX → IA Generativa (resumo executivo) → Relatório publicado.

> Os dados usados nos arquivos de apoio são fictícios, gerados para fins ilustrativos de portfólio, e não representam nenhum cliente real.

## Autora

**Nathália Paccelly** — Especialista Sênior em Inteligência de Mercado, BI & Comunicação Estratégica
LinkedIn · Portfólio <!-- adicione aqui os links -->
