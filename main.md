PRUEBA TÉCNICA – ANALISTA SENIOR DE GOBIERNO DE DATOS
(Gobierno de Datos + KPIs + Calidad + SQL)
HDI Seguros Colombia | Gerencia de Datos y Analítica
Documento para candidato (versión pública)

1) Contexto del Caso (por qué existe esta prueba)
La compañía está acelerando tres iniciativas: (1) Sunset: migración y decommission del DWH legado hacia Redshift, (2) Foundation: fortalecimiento del gobierno de datos (glosario, catálogo, calidad, linaje, clasificación de información, PII y controles), y (3) Clarity: estructuración, estandarización y trazabilidad de KPIs para decisiones. El objetivo de esta prueba es evaluar tu capacidad para comprender el negocio a través de la definición de KPIs, pero con foco prioritario en calidad de datos: identificar riesgos, proponer reglas de control accionables, materializarlas en SQL y mostrar cómo asegurar trazabilidad y confianza en el dato a lo largo del proceso.
2) Instrucciones Generales
Tiempo total máximo: 60 minutos.
Puedes asumir reglas/filtros cuando falte información, pero debes documentar tus supuestos.
No uses datos personales reales. Todo lo que entregues debe ser reproducible.
Prioriza claridad, correctitud y enfoque a negocio sobre “hacer de todo”.
Entrega un paquete reproducible con tus respuestas técnicas y de análisis.
Contenido mínimo de entrega: consultas.sql + respuestas_gobierno.pdf (o .docx) + diagrama simple de linaje incluido en el mismo documento o como imagen exportada.
3) Datos de referencia (modelo simplificado)
Asume que existen estas tablas (no necesitas crear la BD; solo escribe consultas/transformaciones):
polizas (id_poliza, fecha_emision, canal, producto, prima_neta, id_cliente, id_intermediario)
clientes (id_cliente, tipo_doc, nro_doc_hash, ciudad, segmento)
intermediarios (id_intermediario, nombre_intermediario, tipo_intermediario)
siniestros (id_siniestro, id_poliza, fecha_fnol, fecha_aprobacion, fecha_pago, valor_pagado, estado_siniestro)
pagos (id_pago, id_siniestro, fecha_pago, valor_pago, medio_pago, banco)
kpi_definiciones (nombre_kpi, definicion_negocio, formula, granularidad, fuente_autorizada, owner, steward, clasificacion_dato)
Notas:
nro_doc_hash representa un identificador anonimizado (hash) para evitar PII.
fechas están en formato fecha (YYYY-MM-DD).
La “fuente autorizada” esperada para KPIs debe ser la plataforma analítica objetivo (por ejemplo, Redshift), con definición aprobada, trazabilidad de transformación y controles de calidad asociados.
Nota de enfoque: más que cubrir muchos ejercicios, nos interesa ver tu criterio para identificar qué puede romper la confiabilidad del KPI, cómo lo controlarías con SQL y cómo priorizarías los problemas de calidad con mayor impacto en negocio.
4) SECCIÓN A - SQL + KPI + Calidad de Datos | 55 puntos | 35 minutos
A1. KPI candidato: % Siniestros pagados en ≤ 1 día
Escribe una consulta que calcule para el mes calendario más reciente disponible: (1) total de siniestros pagados, (2) siniestros pagados en ≤ 1 día desde fecha_fnol hasta fecha_pago, y (3) el porcentaje correspondiente. La consulta debe permitir segmentar por canal o producto. Documenta brevemente tus supuestos mínimos: qué entiendes por “pagado” y qué exclusiones aplicarías si detectas registros atípicos.
A2. Conciliación base del KPI
Escribe una consulta que devuelva por id_siniestro: valor_pagado, suma_valor_pago, diferencia y estado de conciliación: Exacta, Exceso o Sin pagos. Incluye manejo de nulos.
A3. Reglas de calidad de datos con SQL: define y escribe en SQL al menos 4 reglas de calidad prioritarias para este modelo. Debes cubrir, como mínimo, completitud, unicidad o duplicidad, validez temporal y conciliación. Para cada regla indica en una línea: qué busca controlar, por qué impacta el KPI, qué evidencia produciría el control y cuál priorizarías primero si solo pudieras remediar una.
5) SECCIÓN B — Gobierno de Datos, Normativas y Trazabilidad | 35 puntos | 20 minutos
Responde de forma breve y ejecutiva:
B1. Ficha del KPI: define brevemente “Siniestro”, “FNOL” y “SLA 1 día”, y construye una ficha corta del KPI “% Siniestros pagados en ≤ 1 día” con: objetivo, definición, fórmula, fuente autorizada, owner, steward y 2 supuestos críticos de calidad o interpretación que podrían cambiar el resultado del indicador.
B2. Protección de datos y clasificación: identifica los campos que podrían considerarse datos personales o sensibles, indica cómo los clasificarías y menciona la normativa colombiana principal aplicable. Agrega 3 recomendaciones concretas de almacenamiento o acceso seguro.
B3. Linaje y AWS: dibuja un flujo simple del dato para el KPI desde la fuente hasta el dashboard y señala dónde pondrías controles de calidad, trazabilidad y 4 controles mínimos de gobernanza en AWS para un datalake. Marca explícitamente en qué paso se genera evidencia del control y cómo asegurarías auditabilidad.
8) Criterios de Calificación (cómo te evaluamos)
Calidad de datos y entendimiento del negocio: capacidad para conectar la confiabilidad del KPI con reglas de control relevantes, supuestos claros, priorización por impacto y criterio sobre qué revisar primero.
Correctitud técnica en SQL y controles: consultas coherentes, buen manejo de joins, agregaciones y nulos, además de capacidad para traducir reglas de calidad en validaciones SQL útiles y observables.
Gobierno, normativas y trazabilidad: criterio para clasificar información, reconocer regulación aplicable, proponer almacenamiento seguro y representar linaje con controles mínimos de gobernanza.

