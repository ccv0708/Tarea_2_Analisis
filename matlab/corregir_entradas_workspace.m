% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: corregir la salida final de las entradas From Workspace.
% Entrada: modelos ya generados. Salida: modelos guardados con retencion final.
carpeta = fileparts(mfilename('fullpath'));
modelos = {'peltier_lazo_P','peltier_lazo_P_lineal','peltier_lazo_comp'};
for k = 1:length(modelos)
    modelo = modelos{k};
    archivo = fullfile(carpeta,[modelo '.slx']);
    if isfile(archivo)
        load_system(archivo);
        bloques = find_system(modelo,'BlockType','FromWorkspace');
        for j = 1:length(bloques)
            set_param(bloques{j},'Interpolate','off', ...
                'OutputAfterFinalValue','Holding final value');
        end
        save_system(modelo);
        fprintf('Entradas corregidas: %s\n',modelo);
    end
end
