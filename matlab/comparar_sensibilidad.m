% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: unir las tablas P y compensada con las MISMAS pruebas.
% Entrada: sensibilidad_P.csv y sensibilidad_compensado.csv del grupo.
% Salida: tabla comparativa CSV. No genera datos compensados ausentes.
configurar;
archivo_comp = fullfile(salida,'sensibilidad_compensado.csv');
if ~isfile(archivo_comp)
    error('Falta sensibilidad_compensado.csv. Vea guia 05 para producirla.');
end
P = readtable(fullfile(salida,'sensibilidad_P.csv'));
Comp = readtable(archivo_comp);
% Cada tabla debe tener una fila por caso y los nombres de columna acordados.
if height(Comp)~=height(P) || ~isequal(string(P.caso),string(Comp.caso))
    error('Los casos o su orden no coinciden. No comparar pruebas diferentes.');
end
comparacion = table(string(P.caso),P.ess_abs_K,Comp.ess_abs_K, ...
    P.ts_ref_s,Comp.ts_ref_s,P.Imax_A,Comp.Imax_A, ...
    P.t_saturacion_s,Comp.t_saturacion_s, ...
    'VariableNames',{'caso','ess_P_K','ess_comp_K','ts_P_s','ts_comp_s', ...
    'Imax_P_A','Imax_comp_A','tsat_P_s','tsat_comp_s'});
writetable(comparacion,fullfile(salida,'comparacion_sensibilidad.csv'));
disp(comparacion);
