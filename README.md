# Prueba Técnica — Analista Senior de Gobierno de Datos

**HDI Seguros Colombia** | Gerencia de Datos y Analítica

> Gobierno de Datos + KPIs + Calidad + SQL

---

## Contexto

La compañía acelera tres iniciativas simultáneas:

| Iniciativa | Descripción |
|---|---|
| **Sunset** | Migración y decommission del DWH legado hacia **Amazon Redshift** |
| **Foundation** | Fortalecimiento del gobierno de datos (glosario, catálogo, calidad, linaje, clasificación, PII y controles) |
| **Clarity** | Estructuración, estandarización y trazabilidad de KPIs para la toma de decisiones |

El objetivo de esta prueba es evaluar la capacidad para comprender el negocio a través de la definición de KPIs, con foco prioritario en **calidad de datos**: identificar riesgos, proponer reglas de control accionables, materializarlas en SQL y asegurar trazabilidad y confianza en el dato.

---

## Estructura del repositorio

```
.
├── main.md                          # Enunciado original de la prueba técnica
├── consultas.sql                    # Sección A: SQL + KPI + Calidad (Amazon Redshift)
├── respuestas_gobierno.md           # Sección B: Gobierno, normativas y trazabilidad
├── respuestas_gobierno.pdf          # Versión PDF del documento de gobierno
└── respuestas_gobierno.docx         # Versión DOCX del documento de gobierno
```

---

## Modelo de datos de referencia

```sql
polizas          (id_poliza, fecha_emision, canal, producto, prima_neta, id_cliente, id_intermediario)
clientes         (id_cliente, tipo_doc, nro_doc_hash, ciudad, segmento)
intermediarios   (id_intermediario, nombre_intermediario, tipo_intermediario)
siniestros       (id_siniestro, id_poliza, fecha_fnol, fecha_aprobacion, fecha_pago, valor_pagado, estado_siniestro)
pagos            (id_pago, id_siniestro, fecha_pago, valor_pago, medio_pago, banco)
kpi_definiciones (nombre_kpi, definicion_negocio, formula, granularidad, fuente_autorizada, owner, steward, clasificacion_dato)
```

Notas del modelo:
- `nro_doc_hash` es un identificador anonimizado (hash) para evitar PII.
- Fechas en formato `YYYY-MM-DD`.
- La fuente autorizada para KPIs es **Amazon Redshift**.

---

## Contenido de los entregables

### Sección A — SQL + KPI + Calidad de Datos (55 pts)

#### A1. KPI: % Siniestros pagados en ≤ 1 día

Calcula para el mes calendario más reciente disponible:
1. Total de siniestros pagados
2. Siniestros pagados en ≤ 1 día (desde FNOL hasta fecha de pago)
3. Porcentaje correspondiente

Segmentable por **canal** y **producto**. Incluye supuestos documentados sobre qué significa "pagado" y las exclusiones aplicadas (nulos, fechas invertidas, valores atípicos).

#### A2. Conciliación base del KPI

Por cada `id_siniestro` compara `valor_pagado` (tabla `siniestros`) contra la suma de `valor_pago` (tabla `pagos`), clasificando en:
- **Exacta** — los montos coinciden
- **Exceso** — existe diferencia
- **Sin pagos** — no hay registros en la tabla `pagos`

#### A3. Reglas de calidad de datos (5 reglas)

| # | Regla | Busca |
|---|---|---|
| 1 | **Completitud** | NULLs en campos críticos (`fecha_fnol`, `fecha_pago`, `valor_pagado`, `estado_siniestro`) |
| 2 | **Unicidad** | Duplicados en `id_siniestro` |
| 3 | **Validez temporal** | `fecha_fnol` posterior a `fecha_pago` |
| 4 | **Conciliación** | Discrepancia entre `valor_pagado` y suma de `valor_pago` |
| 5 | **Integridad referencial** | Siniestros huérfanos sin póliza asociada |

Cada regla incluye: qué controla, por qué impacta el KPI, qué evidencia produce y su prioridad de remediación.

### Sección B — Gobierno de Datos, Normativas y Trazabilidad (35 pts)

#### B1. Ficha del KPI

Define **Siniestro**, **FNOL**, **SLA 1 día** y presenta la ficha técnica del KPI con: objetivo, definición, fórmula, fuente autorizada, owner, steward y 2 supuestos críticos de calidad.

#### B2. Protección de datos y clasificación

Identifica 6 campos con datos personales/sensibles, clasificación, normativa colombiana aplicable (Ley 1581/2012, Decreto 1377/2013, Ley 1266/2008, Circular 002/2022 SFC) y 3 recomendaciones de almacenamiento seguro (KMS, tokenización progresiva, Lake Formation).

#### B3. Linaje y AWS

Diagrama de linaje (Mermaid) que cubre desde sistemas fuente hasta dashboard, con:
- 3 puntos de control de calidad (QC1-QC3)
- Tabla de evidencia por control
- 4 controles mínimos de gobernanza en AWS (Lake Formation, KMS, Glue Catalog + DataZone, CloudTrail + Config + EventBridge)

---

## Plataforma objetivo

| Componente | Tecnología |
|---|---|
| Base de datos analítica | Amazon Redshift |
| Lenguaje de consultas | SQL ANSI + funciones Redshift (`DATE_TRUNC`, `DATEADD`, `DATEDIFF`) |
| ETL / Transformación | AWS Glue, dbt |
| Calidad de datos | AWS Deequ, AWS Glue DataBrew |
| Catalogación | AWS Glue Catalog, Amazon DataZone |
| Consumo / BI | Amazon QuickSight |
| Auditoría | AWS CloudTrail, AWS Config |

---

## Criterios de evaluación cubiertos

1. **Calidad de datos y entendimiento del negocio**: Reglas de control relevantes, supuestos claros, priorización por impacto.
2. **Correctitud técnica en SQL**: Joins, agregaciones, manejo de nulos, validaciones accionables.
3. **Gobierno, normativas y trazabilidad**: Clasificación de información, regulación aplicable, almacenamiento seguro, linaje con controles.
s