function comprobar_modelo_P(modelo)
% Comprobar conexiones, entradas y lazos antes de simular.
limite = get_param([modelo '/Limite_I'],'PortHandles');
estado = get_param([modelo '/Dinamica_corriente'],'PortHandles');
linea = get_param(limite.Outport,'Line');
destinos = get_param(linea,'DstPortHandle');
assert(numel(destinos)==1 && destinos==estado.Inport, ...
    'Limite_I solo debe alimentar Dinamica_corriente.');
assert(strcmp(get_param([modelo '/Dinamica_corriente'],'D'),'0'), ...
    'El estado de corriente debe tener D=0.');
if strcmp(modelo,'peltier_lazo_P')
    entrada = get_param([modelo '/I_A'],'PortHandles');
    linea_entrada = get_param(entrada.Inport,'Line');
    assert(get_param(linea_entrada,'SrcPortHandle')==estado.Outport, ...
        'La red fisica debe recibir la salida del estado de corriente.');
else
    entrada = get_param([modelo '/delta_I'],'PortHandles');
    linea_entrada = get_param(entrada.Inport,'Line');
    assert(get_param(linea_entrada,'SrcPortHandle')==estado.Outport, ...
        'La planta lineal debe recibir la corriente del mismo estado.');
end
entradas = find_system(modelo,'BlockType','FromWorkspace');
for n = 1:length(entradas)
    assert(strcmp(get_param(entradas{n},'OutputAfterFinalValue'), ...
        'Holding final value'),'Revisar el valor final de From Workspace.');
end
set_param(modelo,'AlgebraicLoopMsg','warning');
set_param(modelo,'SimulationCommand','update');
lazos = Simulink.BlockDiagram.getAlgebraicLoops(modelo);
fprintf('%s: %d lazos algebraicos.\n',modelo,numel(lazos));
for n = 1:numel(lazos)
    disp(getfullname(lazos(n).BlockHandles));
end
assert(isempty(lazos),'Quedan lazos algebraicos: revise los bloques indicados.');
% Las simulaciones siguientes deben detenerse si reaparece un lazo.
set_param(modelo,'AlgebraicLoopMsg','error');
end
