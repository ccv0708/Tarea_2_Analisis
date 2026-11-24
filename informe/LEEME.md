# Informe Tarea 2 (GR09)

Documento principal: `informe_tarea2.tex` (formato IEEE, mismo título/autores de la Tarea 1).
Compilar ese archivo desde esta carpeta (o en Overleaf con la misma estructura).

## Secciones (`secciones/`)

| Archivo | Contenido | Responsable | Estado |
|---|---|---|---|
| 01_introduccion.tex | Introducción | Integrante 3 | Pendiente |
| 02_sistema_modelo.tex | Sistema y modelo (resumen Tarea 1, imagen Simscape) | Integrante 3 | Pendiente |
| 03_lazo_cerrado.tex | Referencia, convención de signo, diagrama del lazo P | Integrante 1 | Listo (saturación ya en 0-2 A) |
| 04_control_P.tex | Análisis P, lugar de las raíces, perturbaciones, límite de 2 A | Integrantes 1 y 2 | Listo |
| 05_desempeno_P.tex | Pruebas, métricas, comprobación auxiliar | Integrante 1 | Falta repetir con Imax = 2 A y poner figuras Simscape |
| 06_especificaciones.tex | Tabla de especificaciones E1-E8 | Integrante 2 | Listo |
| 07_seleccion.tex | Selección del PI y anti-windup | Integrante 2 | Listo |
| 08_diseno.tex | Diseño del PI y verificación | Integrante 2 | Listo |
| 09_resultados.tex | Simulación del sistema compensado | Integrante 3 | Pendiente |
| 10_comparacion.tex | Tabla P vs compensado (columna de especificación lista) | Integrante 3 | Pendiente |
| 11_discusion.tex | Sensibilidad (I1) y compromisos de diseño (I2) | Integrantes 1 y 2 | Faltan resultados de sensibilidad |
| 12_conclusiones.tex | Conclusiones | Todos | Parcial |
| referencias.tex | Bibliografía (las de la Tarea 1 sin citar están comentadas) | Todos | - |

## Convenciones (pedidas por el profesor)

- Referencias en el texto: `Figura~\ref{}`, `Tabla~\ref{}`, `ecuación~\eqref{}`, `ecuaciones~\eqref{} y \eqref{}`.
- Figuras y diagramas sin colores, con "Fuente: ..." al final del caption.
- Cuadros de parámetros de componentes con su fuente (`\cite{}`).
- Cada figura justo después del párrafo que la menciona.
- `\pendiente{...}` marca lo que falta; no debe quedar ninguno al entregar.

## Figuras

`\graphicspath` busca en `../matlab/figuras_diseno/` (lo genera `diseno_compensador.m`)
y en `../resultados_matlab/`. En `\includegraphics` se usa solo el nombre del archivo.

`secciones_integrante1.tex` y `avance_integrante1.tex` se reemplazaron por los archivos de `secciones/`
(el contenido del integrante 1 está en 03, 04, 05, 11 y 12).
