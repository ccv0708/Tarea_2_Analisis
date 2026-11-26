% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: ejecutar el analisis y los ensayos del controlador P.
% Entrada: parametros.mat y parametros_ensayos.mat. Salida: resultados_matlab/.
clear; clc; close all;
raiz = fileparts(mfilename('fullpath'));
cd(raiz);
addpath(fullfile(raiz,'matlab'),'-begin');
diary(fullfile(raiz,'registro_ejecucion.txt'));
disp('GR09 - carpeta consolidada: modelos P con estado de corriente.');
disp(raiz);
disp('Archivo de sensibilidad utilizado:');
disp(which('sensibilidad_P'));
try
    configurar;
    analisis_P;
    factibilidad_termica;
    comprobar_metricas;
    simular_P;
    graficar_P;
    sensibilidad_P;
    disp('Ensayos P y sensibilidad terminados. Revise resultados_matlab.');
catch error_ejecucion
    disp(getReport(error_ejecucion,'extended','hyperlinks','off'));
    diary off;
    rethrow(error_ejecucion);
end
diary off;
