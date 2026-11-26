% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: cargar la planta y los valores comunes de los ensayos.
% Entrada: dos archivos MAT. Salida: variables en el Workspace.
carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
salida = fullfile(raiz,'resultados_matlab');
if ~isfolder(salida)
    mkdir(salida);
end
load(fullfile(carpeta,'parametros.mat'));
load(fullfile(carpeta,'parametros_ensayos.mat'));
if Imin~=0 || Imax~=2
    error('Los ensayos del grupo deben usar Imin=0 A e Imax=2 A. Ejecute editar_ensayos.');
end
if ~exist('tau_corriente','var') || ~isscalar(tau_corriente) || ...
        ~isfinite(tau_corriente) || tau_corriente<=0
    error('Falta una tau_corriente positiva. Use el MAT incluido en esta carpeta.');
end
if I0<Imin || I0>Imax
    error('La corriente inicial I0 debe estar entre 0 y 2 A.');
end
p_nom = p;
I0_nom = I0;
Tc0_nom = Tc0;
Th0_nom = Th0;
case_RHA = p.RHA;
Tc_init = Tc0;
Th_init = Th0;
Kp = Kp_base;
r_antes = Tc0-273.15;
r_despues = r_antes-1;
instante_ref = t_ref;
t = (0:dt_salida:t_final)';
tiempo_ruido = (0:Ts_ruido:t_final)';
rng(semilla);
ruido_comun = sigma_ruido*randn(size(tiempo_ruido));
ruido_comun(tiempo_ruido<t_pert) = 0;
senal_ruido = [tiempo_ruido, zeros(size(tiempo_ruido))];
senal_carga = [0 0; t_pert 0; t_final 0];
senal_ambiente = [0 0; t_final 0];
addpath(carpeta);
