% Reconstruir siempre: asi no se simula un SLX de una version anterior.
configurar;
crear_modelos_P;
modelos_preparados = {'peltier_lazo_P_lineal','peltier_lazo_P'};
for n_modelo = 1:length(modelos_preparados)
    modelo_preparado = modelos_preparados{n_modelo};
    load_system(fullfile(carpeta,[modelo_preparado '.slx']));
    comprobar_modelo_P(modelo_preparado);
    save_system(modelo_preparado);
    close_system(modelo_preparado,0);
end
disp('Comprobacion previa de los dos modelos P terminada.');
