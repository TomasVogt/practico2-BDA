# Informe de Integración de Datos: Data Mart Ventas BMW

**Integrantes:** Santino Vazquez de Novoa, Enzo Parra, Santiago Dhers, Tomas Vogt

## 0. Scripts y orden de ejecución

| Orden | Archivo | Qué hace |
|---|---|---|
| 1 | `entrega_modelo_logico.sql` | Crea la base `dw_bmw_ventas` y las tablas del modelo estrella (5 dimensiones + `Hecho_Ventas`). |
| 2 | `etl_bmw.ipynb` | Extrae el CSV, lo vuelca en una tabla intermedia (`stg_bmw_sales`), aplica calidad de datos, genera las dimensiones y los hechos, los carga en MySQL y verifica la carga. |
| 3 | `graficos.ipynb` | Ejecuta las consultas del dashboard sobre el modelo estrella y genera los gráficos (ver `dashboard/dashboard.md`). |

## 1. Carga intermedia (staging)

El CSV original (`dataset/BMW sales data (2010-2024).csv`, 50.000 filas × 11 columnas) se vuelca sin modificar en la tabla `stg_bmw_sales` de MySQL. Desde ahí se pueden revisar y limpiar los datos antes de pasar a las tablas finales del modelo. Las dimensiones y la tabla de hechos se construyen a partir de los datos ya limpios.

## 2. Calidad de Datos: chequeos realizados y resultados

El ETL se ejecutó en Python (Pandas). Se aplicaron los siguientes chequeos y esto fue lo que se encontró:

| Chequeo | Regla aplicada | Resultado encontrado | Resolución |
|---|---|---|---|
| Nulos en columnas clave | Conteo de nulos en las 11 columnas; `dropna` sobre `Year`, `Model`, `Region`, `Fuel_Type`, `Color`, `Sales_Volume`, `Price_USD` | 0 nulos | No hubo que descartar ni completar filas |
| Duplicados | `drop_duplicates()` sobre filas exactamente iguales | 0 duplicados (50.000 → 50.000) | Sin acción |
| Conversión numérica | `pd.to_numeric(..., errors='coerce')` sobre `Sales_Volume` y `Price_USD` | Ningún valor no convertible (0 nulos posteriores a la conversión) | Sin acción |
| Valores fuera de rango | Regla de negocio: `Sales_Volume > 0` y `Price_USD >= 0` | 0 filas fuera de rango (volumen mín. 100, precio mín. 30.000) | Sin acción |
| Consistencia de texto | `strip()` + `title()` en `Model`, `Region`, `Fuel_Type`, `Color` | Sin variantes de escritura (el número de valores únicos no cambió, ver Paso 2) | Se estandarizó igualmente el formato; efecto cosmético: `i3` e `i8` quedan como `I3` e `I8` en las dimensiones |

**Filas descartadas en total: 0.** Las 50.000 filas del archivo pasaron los controles. Volumen total de ventas validado: **253.375.734** unidades.

## 3. Verificación de la Carga

**Conteo de filas por tabla:**

| Tabla | Filas |
|---|---|
| `stg_bmw_sales` (CSV crudo) | 50.000 |
| `Dim_Tiempo` | 15 |
| `Dim_Producto` | 11 |
| `Dim_Region` | 6 |
| `Dim_Combustible` | 4 |
| `Dim_Color` | 6 |
| `Hecho_Ventas` | 20.886 |

- **Reducción por agrupamiento (granularidad):** las 50.000 filas del archivo se agrupan por (Año, Modelo, Región, Combustible, Color), la granularidad definida en el Paso 2, y dan 20.886 filas en `Hecho_Ventas`. La compresión es esperada y no implica pérdida de datos.
- **Comparación de un total agregado:** el volumen de ventas total calculado sobre el archivo original se comparó con el volumen total consultado en la base (`SELECT SUM(volumen_ventas) FROM Hecho_Ventas`):

| Origen | Volumen total de ventas |
|---|---|
| Archivo original (`SUM(Sales_Volume)`) | 253.375.734 |
| Data Mart en MySQL (`SUM(volumen_ventas)`) | 253.375.734 |

Si ambos valores coinciden, no hubo pérdida ni duplicación de datos al pasar al esquema estrella.

- **Nota sobre `precio_usd`:** en la tabla de hechos este campo guarda el precio promedio de las filas agrupadas en cada combinación de dimensiones. Los promedios que se calculan después en el dashboard (preguntas 2 y 5) son promedios de esos promedios, sin ponderar por volumen. Es una consecuencia de la granularidad elegida.

## 4. Políticas de Actualización

Dado que el proceso de negocio analizado se consolida por año calendario, el Data Warehouse se actualiza así:

- **Periodicidad:** actualización por lotes (Batch), una vez por año, al cierre de cada ciclo comercial.
- **Tabla intermedia (`stg_bmw_sales`):** se recarga completa en cada ejecución con el archivo recibido (`if_exists='replace'`); no conserva historia.
- **Dimensiones (`Dim_*`):** carga incremental. Se insertan registros nuevos solamente si BMW incorpora una región, un modelo, un combustible o un color que todavía no existe. Los registros existentes no se modifican.
- **Hechos (`Hecho_Ventas`):** carga incremental (append) de los datos agregados del nuevo año (`id_tiempo`). Los años anteriores no se sobrescriben ni se recalculan, lo que mantiene intacta la base histórica para medir variaciones interanuales.
- **Después de cada carga:** se repite la verificación de la sección 3 (conteos y comparación de totales) y se vuelven a ejecutar las consultas del dashboard.