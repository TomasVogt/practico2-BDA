# Informe de Integración de Datos: Data Mart Ventas BMW

**Integrantes:** Santino Vazquez de Novoa, Enzo Parra, Santiago Dhers, Tomas Vogt

## 1. Calidad de Datos Aplicada
El proceso de Extracción, Transformación y Carga (ETL) fue ejecutado en Python utilizando Pandas, aplicando las siguientes reglas de estandarización y limpieza basadas en metodologías analíticas formales:
- **Desduplicación Lógica:** Se aplicó la remoción de registros redundantes a nivel transaccional para evitar la contabilización doble de ventas[cite: 17].
- **Estandarización de Texto:** Las columnas categóricas (`Model`, `Region`, `Fuel_Type`, `Color`) fueron procesadas eliminando espacios en blanco sobrantes y aplicando formato de título para garantizar la unicidad en las tablas de dimensiones[cite: 17].
- **Conversión y Consistencia Numérica:** Se forzó la conversión de los campos numéricos de medida (`Sales_Volume`, `Price_USD`). Se descartaron filas con valores nulos resultantes y se aplicó una regla de negocio estricta para eliminar montos atípicos o negativos (volumen > 0 y precio >= 0)[cite: 18]. 

## 2. Verificación de la Carga
La verificación matemática ejecutada post-transformación arrojó resultados que certifican la integridad referencial y agregacional del modelo:
- **Reducción por Agrupamiento (Granularidad):** De un total de 50.000 registros transaccionales originales válidos, la tabla de hechos `Hecho_Ventas` quedó conformada por 20.886 filas[cite: 31]. Esta compresión es el resultado correcto del agrupamiento dimensional (Año, Modelo, Región, Combustible, Color) definido en la etapa de modelado.
- **Validación de la Medida Base:** El cálculo de comprobación confirmó que el volumen de ventas total previo a la carga (253.375.734) es matemáticamente idéntico al volumen agregado total insertado en la base de datos[cite: 31]. No hubo pérdida ni duplicación de datos durante la transformación 1:N del esquema estrella.

## 3. Políticas de Actualización
Dado que el proceso de negocio analizado se consolida por año calendario, el Data Warehouse debe regirse por la siguiente política de actualización:
- **Periodicidad:** Actualización por lotes (Batch) de forma anual, a ejecutarse al cierre de cada ciclo comercial.
- **Carga de Dimensiones (`Dim_*`):** Metodología incremental. Se insertarán nuevos registros únicamente si BMW incorpora una nueva región comercial, lanza un modelo inédito o introduce una nueva categoría de combustible/color. Los registros históricos son inmutables.
- **Carga de Hechos (`Hecho_Ventas`):** Carga puramente incremental (Append) de los datos agregados correspondientes al nuevo `id_tiempo`. Las ventas de los años anteriores no se sobrescriben ni recalculan, manteniendo la base histórica intacta para la medición de variaciones interanuales.