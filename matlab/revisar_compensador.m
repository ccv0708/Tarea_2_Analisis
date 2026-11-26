% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: comprobacion independiente del controlador del Integrante 2.
% Entrada: parametros_control.mat; ver guias/04_cierre_del_grupo.md.
% Salida: polos, ceros y margenes LINEALES. Requiere Control System Toolbox.
configurar;
archivo_control = fullfile(carpeta,'parametros_control.mat');
if ~isfile(archivo_control)
    error('Falta parametros_control.mat del Integrante 2. No hay ganancias inventadas.');
end
control = load(archivo_control);  % evita confundir C(s) con la matriz C de la planta
if control.I_max_ctrl~=Imax || control.I_min_ctrl~=Imin
    error('Los limites del P y del PI no coinciden. Deben ser 0 y 2 A.');
end
if isfield(control,'numC') && isfield(control,'denC')
    Ccontrol = tf(control.numC,control.denC);
elseif isfield(control,'C')
    Ccontrol = tf(control.C);
else
    error('Se espera numC y denC, o una funcion de transferencia C.');
end
G = tf(numG,denG);
% El controlador se aplica a e=Tb-ref. Ccontrol NO incluye otro cambio de signo.
H = tf(1,[tau_corriente 1]);
L = -Ccontrol*H*G;
Tcerrado = feedback(L,1);
[GM,PM,Wcg,Wcp] = margin(L);
polos_control = pole(Ccontrol);
ceros_control = zero(Ccontrol);
polos_lazo = pole(Tcerrado);
disp('Polos del controlador:'); disp(polos_control);
disp('Ceros del controlador:'); disp(ceros_control);
disp('Polos del lazo cerrado:'); disp(polos_lazo);
disp('Margen ganancia [factor], fase [grados], Wcg y Wcp [rad/s]:');
disp([GM PM Wcg Wcp]);
disp('Estabilidad lineal de la transferencia cerrada:'); disp(isstable(Tcerrado));
save(fullfile(salida,'revision_compensador.mat'), ...
    'Ccontrol','L','Tcerrado','polos_control','ceros_control','polos_lazo','GM','PM','Wcg','Wcp');
figure; margin(L); grid on;
title('Comprobacion independiente del lazo compensado');
exportgraphics(gcf,fullfile(salida,'margenes_compensador.pdf'),'ContentType','vector');
disp('Esto no verifica saturacion, anti-windup ni estabilidad global no lineal.');
