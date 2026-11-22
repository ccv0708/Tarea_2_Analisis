function x = equilibrio_peltier(I,p)
% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: resolver los dos balances de calor en equilibrio.
% Entrada: corriente [A], parametros p. Salida: [Tc;Th] en K.
gc = 1/p.RCA+p.K+p.alpha*I;
gh = p.K+1/p.RHA-p.alpha*I;
M = [-gc p.K; p.K -gh];
b = [-p.Tamb/p.RCA-0.5*p.R*I^2; -p.Tamb/p.RHA-0.5*p.R*I^2];
x = M\b;
end
