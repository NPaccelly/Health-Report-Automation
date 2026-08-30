/* =====================================================================
   AUTOMAÇÃO DE RELATÓRIO GERENCIAL — SETOR SAÚDE
   Script de consolidação e padronização (camada de banco de dados)
   ---------------------------------------------------------------------
   Contexto: cliente com 8+ unidades enviando extrações mensais em
   formatos e nomenclaturas diferentes. Este script cobre o mesmo
   processo demonstrado em Base_Padronizada.xlsx, para o cenário em
   que a fonte é um banco relacional (ex.: sistema de gestão da rede)
   em vez de planilhas soltas.

   Dialeto: T-SQL (SQL Server). Comentários indicam os pontos de ajuste
   para PostgreSQL/MySQL quando a sintaxe diverge.

   Dados fictícios — script ilustrativo para portfólio.
   ===================================================================== */

-- =====================================================================
-- 1) CAMADA DE STAGING (landing zone)
--    Cada unidade carrega aqui exatamente como chega da fonte, sem
--    normalizar nada ainda. Colunas nullable de propósito: nem toda
--    unidade envia todos os indicadores.
-- =====================================================================

IF OBJECT_ID('stg_relatorio_unidade', 'U') IS NOT NULL DROP TABLE stg_relatorio_unidade;
CREATE TABLE stg_relatorio_unidade (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    unidade_origem      VARCHAR(100)    NOT NULL,   -- nome como veio da fonte (não padronizado)
    competencia_bruta   VARCHAR(20)     NOT NULL,   -- texto: "jan/25", "01/2025", "2025-01-01" etc.
    atendimentos_bruto  INT             NULL,
    receita_bruta_valor DECIMAL(14,2)   NULL,
    glosas_valor        DECIMAL(14,2)   NULL,
    custo_valor         DECIMAL(14,2)   NULL,
    ocupacao_valor      DECIMAL(6,4)    NULL,       -- pode vir como fração (0.75) ou percentual (75)
    tempo_medio_valor   DECIMAL(6,2)    NULL,
    arquivo_origem      VARCHAR(200)    NULL,
    carregado_em        DATETIME        NOT NULL DEFAULT GETDATE()
);

-- Exemplo de carga (uma linha por unidade/mês recebida na extração).
-- Em produção, isto é feito por um processo de importação/ETL, não manualmente.
-- INSERT INTO stg_relatorio_unidade (unidade_origem, competencia_bruta, atendimentos_bruto,
--     receita_bruta_valor, glosas_valor, custo_valor, ocupacao_valor, tempo_medio_valor, arquivo_origem)
-- VALUES ('UNIDADE 01 - CENTRO', 'jan/25', 2712, 731450.10, 42875.30, NULL, NULL, NULL, 'unidade01_jan25.xlsx');

-- =====================================================================
-- 2) DIMENSÕES
-- =====================================================================

IF OBJECT_ID('dim_unidade', 'U') IS NOT NULL DROP TABLE dim_unidade;
CREATE TABLE dim_unidade (
    id_unidade      INT IDENTITY(1,1) PRIMARY KEY,
    nome_unidade    VARCHAR(50)  NOT NULL UNIQUE,     -- nome padronizado ("Unidade 01" ... "Unidade 08")
    nome_origem_ref VARCHAR(100) NULL                 -- nome original mais comum recebido da fonte, para rastreabilidade
);

INSERT INTO dim_unidade (nome_unidade, nome_origem_ref) VALUES
    ('Unidade 01', 'UNIDADE 01 - CENTRO'),
    ('Unidade 02', 'UNIDADE 02'),
    ('Unidade 03', 'UNIDADE 03'),
    ('Unidade 04', 'UNIDADE 04'),
    ('Unidade 05', 'UNIDADE 05'),
    ('Unidade 06', 'UNIDADE 06'),
    ('Unidade 07', 'UNIDADE 07'),
    ('Unidade 08', 'UNIDADE 08');

-- Dimensão calendário simples (12 meses de 2025). Em bases maiores,
-- gerar por script/procedure em vez de INSERT manual.
IF OBJECT_ID('dim_calendario', 'U') IS NOT NULL DROP TABLE dim_calendario;
CREATE TABLE dim_calendario (
    competencia   DATE PRIMARY KEY,   -- sempre dia 01 do mês
    ano           INT NOT NULL,
    mes_numero    INT NOT NULL,
    mes_nome      VARCHAR(15) NOT NULL,
    trimestre     INT NOT NULL
);

;WITH meses AS (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
INSERT INTO dim_calendario (competencia, ano, mes_numero, mes_nome, trimestre)
SELECT
    DATEFROMPARTS(2025, n, 1),
    2025,
    n,
    DATENAME(MONTH, DATEFROMPARTS(2025, n, 1)),
    ((n - 1) / 3) + 1
FROM meses;

-- =====================================================================
-- 3) PADRONIZAÇÃO (staging bruto -> schema único)
--    Aqui entram as regras que resolvem as divergências entre unidades:
--    nome da unidade, formato de data, escala de ocupação (fração x %).
-- =====================================================================

IF OBJECT_ID('fn_padroniza_competencia', 'FN') IS NOT NULL DROP FUNCTION fn_padroniza_competencia;
GO
CREATE FUNCTION fn_padroniza_competencia (@texto VARCHAR(20))
RETURNS DATE
AS
BEGIN
    DECLARE @resultado DATE;

    -- formato "jan/25", "fev/25" ...
    IF @texto LIKE '[a-z][a-z][a-z]/[0-9][0-9]'
        SET @resultado = TRY_CONVERT(DATE, '01 ' + LEFT(@texto, 3) + ' 20' + RIGHT(@texto, 2), 106);

    -- formato "01/2025"
    IF @resultado IS NULL AND @texto LIKE '[0-9][0-9]/[0-9][0-9][0-9][0-9]'
        SET @resultado = DATEFROMPARTS(CAST(RIGHT(@texto, 4) AS INT), CAST(LEFT(@texto, 2) AS INT), 1);

    -- formato "dd/mm/aaaa" ou ISO "aaaa-mm-dd"
    IF @resultado IS NULL
        SET @resultado = TRY_CONVERT(DATE, @texto, 103);
    IF @resultado IS NULL
        SET @resultado = TRY_CONVERT(DATE, @texto, 23);

    RETURN DATEFROMPARTS(YEAR(@resultado), MONTH(@resultado), 1);
END
GO

IF OBJECT_ID('fact_relatorio_gerencial', 'U') IS NOT NULL DROP TABLE fact_relatorio_gerencial;
CREATE TABLE fact_relatorio_gerencial (
    id_unidade              INT           NOT NULL REFERENCES dim_unidade(id_unidade),
    competencia             DATE          NOT NULL REFERENCES dim_calendario(competencia),
    atendimentos            INT           NULL,
    receita_bruta           DECIMAL(14,2) NULL,
    glosas                  DECIMAL(14,2) NULL,
    custo_operacional       DECIMAL(14,2) NULL,
    taxa_ocupacao           DECIMAL(6,4)  NULL,   -- sempre em fração (0.75 = 75%)
    tempo_medio_atendimento DECIMAL(6,2)  NULL,
    CONSTRAINT pk_fact_relatorio PRIMARY KEY (id_unidade, competencia)
);

INSERT INTO fact_relatorio_gerencial
    (id_unidade, competencia, atendimentos, receita_bruta, glosas, custo_operacional,
     taxa_ocupacao, tempo_medio_atendimento)
SELECT
    du.id_unidade,
    dbo.fn_padroniza_competencia(s.competencia_bruta)      AS competencia,
    s.atendimentos_bruto,
    s.receita_bruta_valor,
    s.glosas_valor,
    s.custo_valor,
    -- normaliza ocupação: se veio maior que 1, assume que é percentual (75 -> 0.75)
    CASE WHEN s.ocupacao_valor > 1 THEN s.ocupacao_valor / 100.0 ELSE s.ocupacao_valor END,
    s.tempo_medio_valor
FROM stg_relatorio_unidade s
INNER JOIN dim_unidade du
    -- padroniza nome da unidade (remove sufixos como " - CENTRO", uppercase/trim)
    ON UPPER(LTRIM(RTRIM(LEFT(s.unidade_origem, 10)))) = UPPER(du.nome_unidade)
    OR s.unidade_origem = du.nome_origem_ref;

-- =====================================================================
-- 4) VIEW PARA CONSUMO NO POWER BI
--    É esta view que deve ser usada em "Obter Dados > SQL Server" no
--    Power BI (ver guia em docx). Já entrega nomes de coluna amigáveis
--    e as métricas derivadas mais usadas no relatório.
-- =====================================================================

IF OBJECT_ID('vw_relatorio_gerencial_powerbi', 'V') IS NOT NULL DROP VIEW vw_relatorio_gerencial_powerbi;
GO
CREATE VIEW vw_relatorio_gerencial_powerbi AS
SELECT
    du.nome_unidade                                            AS Unidade,
    f.competencia                                              AS Competencia,
    dc.ano                                                      AS Ano,
    dc.mes_nome                                                 AS Mes,
    dc.trimestre                                                AS Trimestre,
    f.atendimentos                                              AS Atendimentos,
    f.receita_bruta                                             AS ReceitaBruta,
    f.glosas                                                    AS Glosas,
    f.custo_operacional                                         AS CustoOperacional,
    f.taxa_ocupacao                                             AS TaxaOcupacao,
    f.tempo_medio_atendimento                                   AS TempoMedioAtendimento,
    (f.receita_bruta - f.glosas)                                AS ReceitaLiquida,
    (f.receita_bruta - f.custo_operacional)                     AS Margem,
    CASE WHEN f.receita_bruta > 0
         THEN f.glosas / f.receita_bruta ELSE NULL END          AS PercentualGlosa
FROM fact_relatorio_gerencial f
INNER JOIN dim_unidade du     ON du.id_unidade = f.id_unidade
INNER JOIN dim_calendario dc  ON dc.competencia = f.competencia;
GO

-- =====================================================================
-- 5) CONSULTA DE CONFERÊNCIA (equivalente à aba Indicadores_Consolidados
--    do Excel) — útil para validar a carga antes de publicar no Power BI.
-- =====================================================================

SELECT
    Unidade,
    SUM(Atendimentos)                                  AS TotalAtendimentos,
    SUM(ReceitaBruta)                                  AS ReceitaBrutaTotal,
    SUM(Glosas)                                        AS GlosasTotal,
    CASE WHEN SUM(ReceitaBruta) > 0
         THEN SUM(Glosas) / SUM(ReceitaBruta) ELSE NULL END   AS PercentualGlosaMedio,
    SUM(CustoOperacional)                              AS CustoTotal,
    SUM(ReceitaBruta) - SUM(CustoOperacional)          AS MargemTotal,
    AVG(TaxaOcupacao)                                  AS OcupacaoMedia,
    AVG(TempoMedioAtendimento)                         AS TempoMedioMinutos
FROM vw_relatorio_gerencial_powerbi
GROUP BY Unidade
ORDER BY Unidade;

/* ---------------------------------------------------------------------
   Observação sobre a etapa de IA Generativa citada no case:
   ela atua depois desta camada (na geração do texto de análise/resumo
   executivo a partir dos números já consolidados aqui), não dentro do
   SQL. Ver a seção correspondente no guia em docx.
   --------------------------------------------------------------------- */
