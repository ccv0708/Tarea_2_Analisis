# Aporte al informe

`secciones_integrante1.tex` contiene las secciones para integrar al informe del grupo: implementación, referencia, análisis P, métricas, sensibilidad y conclusiones parciales.

`avance_integrante1.tex` es un documento IEEE independiente que incluye esas secciones. Para compilar, subir los dos TEX y `IEEEtran.cls` a Overleaf y seleccionar `avance_integrante1.tex` como documento principal. También puede compilarse con una instalación completa de LaTeX que tenga babel en español y TikZ.

Este entorno no dispone del conjunto de paquetes LaTeX necesario para compilar el avance; no se incluye un PDF IEEE validado. Las guías sí se entregan como PDF revisado. La revisión de compilación del TEX permanece pendiente, igual que la integración con las secciones del resto del grupo.

El aporte está identificado como avance. Incluye cálculos analíticos y una tabla auxiliar de las ecuaciones, claramente diferenciada de resultados Simscape. Después de ejecutar MATLAB hay que incorporar las cifras reales, interpretar las curvas, contrastarlas con las predicciones y cerrar las conclusiones. No convertir la redacción pendiente en una afirmación de validación sin hacer la prueba.

Si existe `../resultados_matlab/simscape_escalon.pdf`, el TEX intenta incluirlo. Si no existe, muestra el aviso de resultado pendiente. Al compilar en Overleaf se puede conservar esa estructura de carpetas o ajustar la ruta a la figura que el grupo haya generado.
