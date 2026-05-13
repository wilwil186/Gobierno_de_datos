-- ============================================================================
-- PRUEBA TÉCNICA – ANALISTA SENIOR DE GOBIERNO DE DATOS
-- HDI Seguros Colombia | Gerencia de Datos y Analítica
-- Sección A: SQL + KPI + Calidad de Datos
-- Plataforma objetivo: Amazon Redshift
-- ============================================================================

-- ============================================================================
-- A1. KPI candidato: % Siniestros pagados en <= 1 dia
-- ============================================================================
-- Supuestos documentados:
--   1. "Pagado" = estado_siniestro = 'Pagado' con fecha_pago no nula
--   2. Exclusiones: fecha_fnol/fecha_pago nulos, fecha_pago < fecha_fnol,
--      valor_pagado <= 0, fechas futuras
--   3. DATEDIFF(day, fecha_fnol, fecha_pago) <= 1 incluye mismo dia (0)
--      y dia siguiente (1)
--   4. Mes calendario mas reciente = ultimo mes completo con datos de pago
--   5. Se asume que la tabla polizas contiene canal y producto validos

WITH siniestros_validos AS (
    SELECT
        s.id_siniestro,
        s.fecha_fnol,
        s.fecha_pago,
        p.canal,
        p.producto
    FROM siniestros s
    INNER JOIN polizas p ON s.id_poliza = p.id_poliza
    WHERE s.estado_siniestro = 'Pagado'
      AND s.fecha_fnol IS NOT NULL
      AND s.fecha_pago IS NOT NULL
      AND s.fecha_pago >= s.fecha_fnol
      AND s.valor_pagado > 0
      AND s.fecha_pago <= CURRENT_DATE
),
ultimo_mes AS (
    SELECT
        DATE_TRUNC('month', MAX(fecha_pago)) AS mes_inicio,
        DATEADD(month, 1, DATE_TRUNC('month', MAX(fecha_pago))) AS mes_fin
    FROM siniestros_validos
)
SELECT
    COALESCE(canal, 'No especificado') AS canal,
    COALESCE(producto, 'No especificado') AS producto,
    COUNT(*) AS total_siniestros_pagados,
    SUM(CASE WHEN DATEDIFF(day, fecha_fnol, fecha_pago) <= 1 THEN 1 ELSE 0 END)
        AS siniestros_pagados_1d,
    ROUND(
        100.0 * SUM(CASE WHEN DATEDIFF(day, fecha_fnol, fecha_pago) <= 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_pagados_1d
FROM siniestros_validos, ultimo_mes
WHERE fecha_pago >= ultimo_mes.mes_inicio
  AND fecha_pago < ultimo_mes.mes_fin
GROUP BY canal, producto
ORDER BY canal, producto;

-- ============================================================================
-- A2. Conciliacion base del KPI
-- ============================================================================
-- Compara valor_pagado (siniestros) vs suma de valor_pago (pagos).
-- Estados: Exacta (coincide), Exceso (diferencia), Sin pagos (sin registros).

SELECT
    s.id_siniestro,
    COALESCE(s.valor_pagado, 0) AS valor_pagado,
    COALESCE(SUM(p.valor_pago), 0) AS suma_valor_pago,
    COALESCE(s.valor_pagado, 0) - COALESCE(SUM(p.valor_pago), 0) AS diferencia,
    CASE
        WHEN COUNT(p.id_pago) = 0 THEN 'Sin pagos'
        WHEN COALESCE(s.valor_pagado, 0) = COALESCE(SUM(p.valor_pago), 0) THEN 'Exacta'
        ELSE 'Exceso'
    END AS estado_conciliacion
FROM siniestros s
LEFT JOIN pagos p ON s.id_siniestro = p.id_siniestro
GROUP BY s.id_siniestro, s.valor_pagado
ORDER BY estado_conciliacion, ABS(diferencia) DESC;

-- ============================================================================
-- A3. Reglas de calidad de datos (4 reglas minimas + 1 adicional)
-- ============================================================================

------------------------------------------------------------------------------
-- Regla 1 - COMPLETITUD
-- Busca:     Identificar registros con NULLs en campos criticos (fecha_fnol,
--            fecha_pago, valor_pagado, estado_siniestro)
-- Impacto:   NULLs en fechas impiden el calculo del KPI; NULLs en valor o
--            estado excluyen el siniestro del indicador
-- Evidencia: Proporcion de registros incompletos sobre el total
-- Prioridad: #1 - Sin estos campos completos NO se puede calcular el KPI
------------------------------------------------------------------------------
SELECT 'Completitud' AS regla,
       'NULLs en campos criticos de siniestros' AS descripcion,
       COUNT(*) AS total_registros,
       SUM(CASE WHEN fecha_fnol IS NULL THEN 1 ELSE 0 END) AS fnol_nulo,
       SUM(CASE WHEN fecha_pago IS NULL THEN 1 ELSE 0 END) AS fecha_pago_nula,
       SUM(CASE WHEN valor_pagado IS NULL THEN 1 ELSE 0 END) AS valor_pagado_nulo,
       SUM(CASE WHEN estado_siniestro IS NULL THEN 1 ELSE 0 END) AS estado_siniestro_nulo,
       ROUND(
           100.0 * SUM(CASE WHEN fecha_fnol IS NULL OR fecha_pago IS NULL
                                 OR valor_pagado IS NULL OR estado_siniestro IS NULL
                            THEN 1 ELSE 0 END)
           / NULLIF(COUNT(*), 0), 2
       ) AS pct_incompletos
FROM siniestros;

------------------------------------------------------------------------------
-- Regla 2 - UNICIDAD / DUPLICIDAD
-- Busca:     Detectar duplicados en siniestros por id_siniestro
-- Impacto:   Duplicados inflan artificialmente el denominador del KPI y
--            pueden sesgar el porcentaje
-- Evidencia: Lista de id_siniestro con >1 ocurrencia y su frecuencia
-- Prioridad: #2 - Duplicados sesgan directamente el resultado del KPI
------------------------------------------------------------------------------
SELECT 'Unicidad' AS regla,
       'Duplicados en tabla siniestros' AS descripcion,
       id_siniestro,
       COUNT(*) AS ocurrencias,
       COUNT(*) - 1 AS exceso_registros
FROM siniestros
GROUP BY id_siniestro
HAVING COUNT(*) > 1
ORDER BY ocurrencias DESC;

------------------------------------------------------------------------------
-- Regla 3 - VALIDEZ TEMPORAL
-- Busca:     Identificar registros donde fecha_fnol > fecha_pago
--            (inconsistencia temporal)
-- Impacto:   Fechas invertidas generan diferencias de tiempo negativas,
--            distorsionando el calculo del SLA
-- Evidencia: Cantidad de registros con inversion temporal
-- Prioridad: #3 - Afecta directamente la exactitud del calculo del KPI
------------------------------------------------------------------------------
SELECT 'Validez Temporal' AS regla,
       'fecha_fnol posterior a fecha_pago' AS descripcion,
       COUNT(*) AS registros_invalidos,
       MIN(fecha_fnol) AS fnol_min,
       MAX(fecha_pago) AS pago_max
FROM siniestros
WHERE fecha_fnol IS NOT NULL
  AND fecha_pago IS NOT NULL
  AND fecha_fnol > fecha_pago;

------------------------------------------------------------------------------
-- Regla 4 - CONCILIACION
-- Busca:     Verificar que valor_pagado (siniestros) coincida con la suma
--            de valor_pago (pagos)
-- Impacto:   Discrepancias financieras indican mala calidad en el registro
--            y afectan la confianza en el dato fuente del KPI
-- Evidencia: Distribucion de estados de conciliacion (Exacta, Exceso,
--            Sin pagos)
-- Prioridad: #4 - Impacta la integridad financiera del indicador
------------------------------------------------------------------------------
SELECT 'Conciliacion' AS regla,
       'Discrepancia valor_pagado vs suma pagos' AS descripcion,
       COUNT(*) AS total_siniestros,
       SUM(CASE WHEN ec.estado = 'Exacta' THEN 1 ELSE 0 END) AS exactos,
       SUM(CASE WHEN ec.estado = 'Exceso' THEN 1 ELSE 0 END) AS excesos,
       SUM(CASE WHEN ec.estado = 'Sin pagos' THEN 1 ELSE 0 END) AS sin_pagos,
       ROUND(100.0 * SUM(CASE WHEN ec.estado = 'Exacta' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*), 0), 2) AS pct_conciliados
FROM (
    SELECT s.id_siniestro,
           CASE
               WHEN COUNT(p.id_pago) = 0 THEN 'Sin pagos'
               WHEN COALESCE(s.valor_pagado, 0) = COALESCE(SUM(p.valor_pago), 0) THEN 'Exacta'
               ELSE 'Exceso'
           END AS estado
    FROM siniestros s
    LEFT JOIN pagos p ON s.id_siniestro = p.id_siniestro
    GROUP BY s.id_siniestro, s.valor_pagado
) ec;

------------------------------------------------------------------------------
-- Regla 5 (adicional) - INTEGRIDAD REFERENCIAL
-- Busca:     Identificar siniestros sin poliza asociada (huerfanos)
-- Impacto:   Siniestros huerfanos no pueden segmentarse por canal o producto,
--            reduciendo la cobertura del analisis (no afecta el KPI base
--            pero si la granularidad)
-- Evidencia: Cantidad de siniestros huerfanos y su proporcion
-- Prioridad: #5 - Afecta la segmentabilidad, no el calculo base del KPI
------------------------------------------------------------------------------
SELECT 'Integridad Referencial' AS regla,
       'Siniestros sin poliza asociada' AS descripcion,
       COUNT(*) AS siniestros_huerfanos,
       ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM siniestros), 0), 2)
           AS pct_huerfanos
FROM siniestros s
LEFT JOIN polizas p ON s.id_poliza = p.id_poliza
WHERE p.id_poliza IS NULL;
