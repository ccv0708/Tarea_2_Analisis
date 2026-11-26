% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: verificar metricas con senales cuyo resultado se conoce.
% Entrada: metricas_lazo.m. Salida: errores si hay una discrepancia.
tt = (0:0.01:100)';
rr = 4*ones(size(tt));
ii = ones(size(tt));
yy = 4+exp(-tt/5);
m = metricas_lazo(tt,rr,yy,ii,0,0.02,0,2.0);
assert(abs(m.tr_s-5*log(9))<0.03);
assert(abs(m.ts_ref_s-5*log(50))<0.03);
assert(m.ess_abs_K<1e-6);
assert(m.sobrepaso_pct==0);
% Se estabiliza en 4.2 C: no alcanza una banda de 0.02 K sobre 4 C.
yy = 4.2+0.8*exp(-tt/5);
m = metricas_lazo(tt,rr,yy,ii,0,0.02,0,2.0);
assert(abs(m.ess_abs_K-0.2)<1e-6);
assert(isnan(m.ts_ref_s));
assert(isfinite(m.ts_final_s));
% Saturacion constante durante 100 s.
ii = 2.0*ones(size(tt));
m = metricas_lazo(tt,rr,yy,ii,0,0.02,0,2.0);
assert(abs(m.t_saturacion_s-100)<1e-9);
disp('Pruebas conocidas de metricas: correctas.');
