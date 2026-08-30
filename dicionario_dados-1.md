# Dicionário de Dados

Documentação das tabelas e colunas usadas no case, tanto na base de apoio em Excel (`dados_relatorio_gerencial_saude.xlsx`) quanto no modelo em banco de dados (`script_consolidacao_relatorio_gerencial.sql`), com o mesmo schema de destino usado no Power BI.

## Tabela fato — indicadores mensais por unidade

Origem: aba `Base_Padronizada` no Excel, ou view `vw_relatorio_gerencial_powerbi` no SQL. Granularidade: uma linha por unidade e por mês.

| Coluna (Excel) | Coluna (SQL / Power BI) | Tipo | Descrição | Regra / observação |
|---|---|---|---|---|
| Unidade | Unidade | Texto | Nome padronizado da unidade (`Unidade 01` a `Unidade 08`) | Chave de junção com a dimensão Unidade |
| Competência | Competencia | Data | Primeiro dia do mês de referência | Sempre normalizada para o dia 01, independentemente do formato de origem |
| Ano | Ano | Número inteiro | Ano da competência | Derivado da Competência |
| Mês | Mes | Texto | Nome do mês em português | Derivado da Competência |
| — | Trimestre | Número inteiro (1 a 4) | Trimestre da competência | Só existe na camada SQL/Power BI, calculado na dimensão calendário |
| Atendimentos Realizados | Atendimentos | Número inteiro | Volume de atendimentos no mês | — |
| Receita Bruta (R$) | ReceitaBruta | Decimal (2 casas) | Faturamento bruto do mês, antes de glosas | — |
| Glosas (R$) | Glosas | Decimal (2 casas) | Valor glosado pelos convênios/pagadores no mês | — |
| Custo Operacional (R$) | CustoOperacional | Decimal (2 casas) | Custo operacional da unidade no mês | — |
| Taxa de Ocupação (%) | TaxaOcupacao | Percentual / decimal fracionário | Ocupação média da agenda no mês | Sempre armazenada como fração (0,75 = 75%); a camada SQL normaliza valores recebidos em escala 0–100 |
| Tempo Médio de Atendimento (min) | TempoMedioAtendimento | Decimal (1 casa) | Tempo médio de atendimento no mês, em minutos | — |
| — | ReceitaLiquida | Decimal (2 casas) | Receita Bruta − Glosas | Coluna calculada, existe apenas na view SQL |
| — | Margem | Decimal (2 casas) | Receita Bruta − Custo Operacional | Coluna calculada, existe apenas na view SQL |
| — | PercentualGlosa | Percentual / decimal fracionário | Glosas ÷ Receita Bruta | Coluna calculada, existe apenas na view SQL |

## Dimensão Unidade

Origem: valores distintos da coluna Unidade no Excel, ou tabela `dim_unidade` no SQL.

| Coluna | Tipo | Descrição |
|---|---|---|
| nome_unidade | Texto | Nome padronizado usado em todo o modelo (`Unidade 01` a `Unidade 08`) |
| nome_origem_ref | Texto | Nome mais comum recebido da fonte original antes da padronização, mantido para rastreabilidade (ex.: `UNIDADE 01 - CENTRO`) |

## Dimensão Calendário

Origem: coluna Competência no Excel, ou tabela `dim_calendario` no SQL (marcada como tabela de datas no modelo do Power BI).

| Coluna | Tipo | Descrição |
|---|---|---|
| competencia | Data | Primeiro dia de cada mês do ano de referência (chave) |
| ano | Número inteiro | Ano da competência |
| mes_numero | Número inteiro (1–12) | Número do mês |
| mes_nome | Texto | Nome do mês por extenso |
| trimestre | Número inteiro (1–4) | Trimestre correspondente ao mês |

## Camada de staging (`stg_relatorio_unidade`, apenas SQL)

Recebe os dados exatamente como chegam de cada unidade, antes de qualquer padronização. Existe para preservar o dado bruto e permitir auditoria.

| Coluna | Tipo | Descrição |
|---|---|---|
| unidade_origem | Texto | Nome da unidade como recebido da fonte, sem padronização |
| competencia_bruta | Texto | Data em formato livre (`jan/25`, `01/2025`, `dd/mm/aaaa`, entre outros) |
| atendimentos_bruto | Número inteiro, aceita nulo | Nem toda unidade envia este indicador em todo formato |
| receita_bruta_valor | Decimal, aceita nulo | — |
| glosas_valor | Decimal, aceita nulo | Ausente nas unidades que não reportam glosa separadamente |
| custo_valor | Decimal, aceita nulo | Ausente nas unidades que não reportam custo |
| ocupacao_valor | Decimal, aceita nulo | Pode chegar como fração (0,75) ou como percentual (75); a padronização normaliza |
| tempo_medio_valor | Decimal, aceita nulo | Ausente nas unidades que não reportam tempo médio |
| arquivo_origem | Texto | Nome do arquivo de onde a linha foi carregada, para rastreabilidade |
| carregado_em | Data e hora | Timestamp da carga na staging |

## Convenções gerais

- Valores monetários sempre em reais (R$), com 2 casas decimais.
- Percentuais sempre armazenados como fração (0,058 = 5,8%), nunca como número inteiro.
- Datas de competência sempre representam o primeiro dia do mês, independentemente do formato de origem.
- Nomes de unidade padronizados como `Unidade 01` a `Unidade 08` em toda a camada de destino; o nome original da fonte é preservado apenas na staging e na dimensão Unidade, para rastreabilidade.
