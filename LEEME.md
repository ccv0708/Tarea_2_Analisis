# Integrante 1 - Tarea 2, GR09

Este paquete prepara el lazo P, los ensayos, las métricas, el análisis y la sensibilidad del integrante 1. El código nuevo usa scripts, arreglos, ciclos `for` y bloques normales de Simulink. Las explicaciones extensas están en `guias/`, fuera del código.

**Estado:** los cálculos y las ecuaciones se comprobaron de forma independiente en Python. Los scripts nuevos y los modelos que construyen todavía requieren ejecución en MATLAB/Simulink R2025a. Este ZIP es un paquete de trabajo del integrante 1, no el ZIP final para entregar en tecDigital.

## Empezar

1. Descomprimir TODO en una carpeta nueva. No trabajar dentro del ZIP.
2. Abrir MATLAB R2025a y seleccionar esta carpeta como Current Folder.
3. Leer primero `guias/01_empezar.md` y `guias/02_entender_control.md`.
4. Ejecutar `ejecutar_integrante1` desde la ventana de comandos.
5. Si aparece un error, conservar el mensaje completo. No saltarse las verificaciones para obtener una tabla.
6. Revisar `resultados_matlab/metricas_P.csv` y las figuras. Después ejecutar `sensibilidad_P`.

Se necesitan MATLAB, Simulink y Simscape. Solo `revisar_compensador` y la conversión de un controlador guardado como objeto `C(s)` necesitan Control System Toolbox; los ensayos P y su análisis de polos no lo necesitan.

## Qué contiene

| Carpeta o archivo | Para qué sirve |
|---|---|
| `ejecutar_integrante1.m` | Orden de ejecución de la parte P. |
| `matlab/` | Código nuevo y parámetros. |
| `matlab/base_tarea1/peltier_validacion.slx` | Red original que se reutiliza; no se altera. |
| `guias/` | Explicaciones y pasos manuales para entender y revisar. |
| `informe/` | Aporte redactado en LaTeX y documento IEEE para compilar e integrar. |
| `comprobacion_independiente/` | Resultados auxiliares de las ecuaciones en Python; NO son Simscape. |
| `resultados_matlab/` | Destino exclusivo de los resultados que generará MATLAB. |

`crear_modelos_P.m` genera `matlab/peltier_lazo_P.slx` y `matlab/peltier_lazo_P_lineal.slx` al ejecutarlo en MATLAB. No se incluyen como modelos nuevos ya validados. El script vuelve a crear esos dos archivos: respaldar primero cualquier cambio manual hecho en ellos.

## Acuerdos usados

- Error del controlador: `e = Tb_medida - referencia`.
- Corriente: `I = saturar(I0 + Kp*e, 0, 6.4)`.
- Temperaturas internas de la planta en K; gráficas y referencia en grados C.
- Tiempo de cada ensayo: 1200 s. Escalón de referencia en 20 s; carga o ruido en 300 s.
- Comparación: Kp = 0.2, 1 y 5 A/K. Sensibilidad: P fijo de 1 A/K, configurable.
- La carga térmica de 2 W y el ruido de 0.05 K RMS se prueban por separado.
- Las ganancias y el anti-windup del compensador no se inventan: los proporciona el integrante 2.

## Dos hallazgos para revisar con el grupo

1. El modelo lineal es estable con las tres ganancias, pero eso no garantiza un buen arranque en la planta no lineal. La comprobación auxiliar predice fallo del arranque con Kp = 1 y 5 A/K al mantenerse una corriente alta; debe contrastarse en Simscape.
2. Según el modelo, la mínima temperatura de equilibrio estable es aproximadamente 6.71 grados C con 200 LFM y 20.15 grados C en convección natural. No se puede exigir regulación a 5 grados C en esos casos mediante un cambio de controlador solamente.

Los números de la comprobación independiente deben quedar identificados como auxiliares hasta contrastarlos con la ejecución requerida. El código está preparado para estudiar y modificar; entenderlo y revisar sus hipótesis sigue siendo parte del trabajo.
