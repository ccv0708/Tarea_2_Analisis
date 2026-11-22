% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: ejecutar el analisis y los ensayos del controlador P.
% Entrada: parametros.mat y parametros_ensayos.mat. Salida: resultados_matlab/.
clear; clc; close all;
raiz = fileparts(mfilename('fullpath'));
addpath(fullfile(raiz,'matlab'));
configurar;
analisis_P;
factibilidad_termica;
comprobar_metricas;
crear_modelos_P;
simular_P;
graficar_P;
disp('Ensayos P terminados. Revise los CSV y PDF en resultados_matlab.');
disp('Para sensibilidad: ejecute sensibilidad_P.');
