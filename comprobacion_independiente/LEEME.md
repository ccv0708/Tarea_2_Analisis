# Comprobación independiente: ecuaciones, no Simscape

Los CSV y figuras de esta carpeta se obtuvieron en Python mediante integración RK45 de las ecuaciones no lineales de Tarea 1 y de su espacio de estados linealizado. Se usaron los parámetros originales de `parametros.mat`, saturación de 0 a 6.4 A, ganancia proporcional con sesgo I0, horizonte de 1200 s y malla de registro de 0.2 s.

Las discontinuidades de referencia, carga y muestras de ruido se trataron por tramos. La integración usó tolerancia relativa 1e-8, absoluta 1e-9 y paso máximo 1 s; cada muestra de ruido se mantuvo durante un segundo. NumPy y MATLAB generan distintas secuencias concretas aunque ambos se inicialicen con 9. Las métricas siguen las definiciones de la guía 04.

Se comprobaron el residuo del equilibrio nominal, la igualdad entre polos por matriz y por polinomio, el error DC del escalón lineal y respuestas conocidas para la definición de métricas. Véase `VERIFICACION_REALIZADA.txt`.

**No se ejecutó MATLAB ni Simulink en esta comprobación.** Las curvas no prueban que los modelos nuevos compilen ni que Simscape entregue las mismas señales. Son referencias auxiliares para detectar discrepancias durante la ejecución requerida.

Las temperaturas extremas en arranques de alta ganancia o disipación insuficiente son extrapolaciones del modelo de coeficientes constantes. No representan una temperatura de operación admisible ni una predicción precisa de daño. Usarlas para identificar que el ensayo falla, no como valores físicos garantizados.

Para reproducir la comprobación se incluye `verificar_referencia.py`. Es apoyo opcional fuera del código MATLAB del proyecto; requiere Python, NumPy, SciPy, pandas y Matplotlib.
