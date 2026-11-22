from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.integrate import solve_ivp
from scipy.optimize import brentq
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'comprobacion_independiente'
S = loadmat(ROOT/'matlab/parametros.mat', simplify_cells=True)
P = S['p']; X0=np.array([S['Tc0'],S['Th0']]); I0=S['I0']
A=S['A']; B=S['B']; N=S['numG']; D=S['denG']
T=np.arange(6001)*.2
NOISE=np.random.default_rng(9).normal(0,.05,1201)
NOISE[:300]=0

def equilibrium(i,p):
    a,R,K=p['alpha'],p['R'],p['K']
    M=np.array([[-(1/p['RCA']+K+a*i),K],[K,-(K+1/p['RHA']-a*i)]])
    return np.linalg.solve(M,[-p['Tamb']/p['RCA']-.5*R*i*i,-p['Tamb']/p['RHA']-.5*R*i*i])

def rhs(x,i,q,p):
    tc,th=x; a,R,K=p['alpha'],p['R'],p['K']
    qc=a*tc*i-.5*R*i*i-K*(th-tc)
    qh=a*th*i+.5*R*i*i-K*(th-tc)
    return np.array([((p['Tamb']-tc)/p['RCA']-qc+q)/p['CC'],(qh-(th-p['Tamb'])/p['RHA'])/p['CH']])

def metrics(t,r,y,i,start,band):
    y0=y[max(0,np.searchsorted(t,start)-1)]
    use=t>=start
    tt=t[use]-start; yy=y[use]; rr=r[use]; ii=i[use]
    tail=tt>=tt[-1]*.9
    yf=np.trapezoid(yy[tail],tt[tail])/(tt[tail][-1]-tt[tail][0])
    e=rr-yy
    def settle(v):
        bad=np.flatnonzero(abs(v)>band)
        return 0 if len(bad)==0 else (tt[bad[-1]+1] if bad[-1]<len(tt)-1 else np.nan)
    tr=np.nan
    if abs(yf-y0)>1e-6 and (yf-y0)*(rr[-1]-y0)>0:
        frac=(yy-y0)/(yf-y0)
        a=np.flatnonzero(frac>=.1);b=np.flatnonzero(frac>=.9)
        if len(a) and len(b):tr=tt[b[0]]-tt[a[0]]
    over=np.nan
    if abs(rr[-1]-y0)>1e-6:
        over=100*max(0,np.max(np.sign(rr[-1]-y0)*(yy-rr[-1])))/abs(rr[-1]-y0)
    tail20=tt>=tt[-1]*.8
    stationary=np.ptp(yy[tail])<=band
    ess=rr[-1]-yf if stationary else np.nan
    return dict(ess_K=ess,ess_abs_K=abs(ess),yfinal_C=yf,
        error_medio_cola_K=rr[-1]-yf,estacionario_observado=stationary,
        rango_cola_K=np.ptp(yy[tail]),ISE_K2s=np.trapezoid(e*e,tt),Imax_A=max(ii),Imin_A=min(ii),
        t_saturacion_s=np.trapezoid(((ii<=1e-6)|(ii>=6.4-1e-6)).astype(float),tt),
        tr_s=tr if stationary else np.nan,ts_ref_s=settle(e),ts_final_s=settle(yy-yf) if stationary else np.nan,sobrepaso_pct=over,
        Tb_std_K=np.std(yy[tail20],ddof=1),I_std_A=np.std(ii[tail20],ddof=1),banda_K=band)

def simulate(plant,trial,kp,p=None,xop=None,bias=None):
    p=P.copy() if p is None else p
    op=X0.copy() if xop is None else xop
    ib=I0 if bias is None else bias
    ref0=op[0]-273.15
    init=np.array([p['Tamb'],p['Tamb']]) if trial=='arranque' else op.copy()
    breaks=[0,20,1200] if trial=='escalon' else ([0,300,1200] if trial=='carga' else [0,1200])
    if trial=='ruido':breaks=[0]+list(range(300,1201))
    xx=np.empty((len(T),2))
    for left,right in zip(breaks[:-1],breaks[1:]):
        ref=ref0-(trial=='escalon' and left>=20)
        q=2. if trial=='carga' and left>=300 else 0.
        noise=NOISE[int(left)] if trial=='ruido' else 0.
        def f(t,x):
            i=np.clip(ib+kp*(x[0]-273.15+noise-ref),0,6.4)
            if plant=='lineal':return A@(x-op)+B*(i-ib)+np.array([q/p['CC'],0])
            return rhs(x,i,q,p)
        sol=solve_ivp(f,[left,right],init,rtol=1e-8,atol=1e-9,max_step=1,dense_output=True)
        assert sol.success
        ids=(T>=left)&(T<=right)
        xx[ids]=sol.sol(T[ids]).T
        init=sol.y[:,-1]
    r=np.full(len(T),ref0);r[(T>=20)&(trial=='escalon')]-=1
    noise=NOISE[np.minimum(np.floor(T).astype(int),1200)] if trial=='ruido' else 0
    i=np.clip(ib+kp*(xx[:,0]-273.15+noise-r),0,6.4)
    v=p['R']*i+p['alpha']*(xx[:,1]-xx[:,0])
    data=pd.DataFrame(dict(t_s=T,ref_C=r,Tb_C=xx[:,0]-273.15,Th_C=xx[:,1]-273.15,I_A=i,V_V=v,P_W=i*v))
    start=20 if trial=='escalon' else (0 if trial=='arranque' else 300)
    m=metrics(T,r,data.Tb_C.to_numpy(),i,start,.4 if trial=='arranque' else .02)
    if trial in ['carga','ruido']:m.update(tr_s=np.nan,sobrepaso_pct=np.nan)
    if trial=='ruido':m.update(ts_ref_s=np.nan,ts_final_s=np.nan)
    assert np.isfinite(data.to_numpy()).all()
    assert i.min()>=0 and i.max()<=6.4
    return data,m

plt.rcParams.update({'font.size':10,'axes.grid':True,'figure.figsize':(8,6)})
checks=[]
assert np.max(abs(rhs(X0,I0,0,P)))<1e-13
checks.append('Equilibrio nominal: residuo menor que 1e-13 K/s.')
analytic=[]
for kp in [.2,1,5]:
    poles=np.sort(np.roots(D-kp*np.r_[0,N]))
    assert np.all(poles<0)
    assert np.allclose(poles,np.sort(np.linalg.eigvals(A+np.outer(B,[kp,0]))))
    analytic.append([kp,*poles,1/(1-kp*N[-1]/D[-1]),I0+20*kp,min(6.4,I0+20*kp)])
pd.DataFrame(analytic,columns=['Kp_A_K','polo1','polo2','ess_1K','I_pedida_A','I_aplicada_A']).to_csv(OUT/'analisis_P_referencia.csv',index=False)
rows=[]; cases={}
for plant in ['lineal','ecuaciones_no_lineales']:
    for trial in ['escalon','arranque','carga','ruido']:
        fig,axs=plt.subplots(2,1,sharex=True)
        for kp in [.2,1,5]:
            data,m=simulate(plant,trial,kp)
            cases[(plant,trial,kp)]=data
            rows.append(dict(planta=plant,prueba=trial,Kp_A_K=kp,**m))
            data.to_csv(OUT/f'{plant}_{trial}_Kp_{kp:g}.csv',index=False)
            axs[0].plot(T,data.Tb_C,label=f'Kp={kp:g} A/K')
            axs[1].plot(T,data.I_A,label=f'Kp={kp:g} A/K')
            if plant=='lineal' and trial=='escalon':
                assert abs(m['ess_abs_K']-1/(1-kp*N[-1]/D[-1]))<2e-5
        axs[0].plot(T,data.ref_C,'k--',label='Referencia')
        axs[0].set_ylabel('Tb [°C]');axs[0].legend(fontsize=8,ncol=2)
        axs[1].set_ylabel('Corriente [A]');axs[1].set_xlabel('Tiempo [s]')
        axs[1].axhline(6.4,color='k',ls='--',lw=.7)
        fig.suptitle(f'Comprobación independiente: {plant.replace("_"," ")} / {trial}\nEcuaciones en Python; no es una ejecución Simscape',fontsize=10)
        fig.tight_layout()
        fig.savefig(OUT/f'{plant}_{trial}.pdf')
        fig.savefig(OUT/f'{plant}_{trial}.png',dpi=130)
        plt.close(fig)
pd.DataFrame(rows).to_csv(OUT/'metricas_referencia_python.csv',index=False)
checks.append('24 ensayos integrados con RK45: señales finitas y corriente entre 0 y 6.4 A.')
checks.append('Error lineal del escalón coincide con fórmula DC dentro de 2e-5 K.')

sens=[]
for case in ['nominal','natural','aire_200','masa_menos20','masa_mas20','operacion_10C']:
    p=P.copy();op=X0.copy();ib=I0
    if case=='natural':p['RHA']=8.4
    if case=='aire_200':p['RHA']=2.11
    if case=='masa_menos20':p['mC']*=.8;p['CC']*=.8
    if case=='masa_mas20':p['mC']*=1.2;p['CC']*=1.2
    if case=='operacion_10C':
        ib=brentq(lambda i:equilibrium(i,p)[0]-283.15,0,2)
        op=equilibrium(ib,p)
    data,m=simulate('ecuaciones_no_lineales','escalon',1,p,op,ib)
    data.to_csv(OUT/f'sens_P_{case}.csv',index=False)
    sens.append(dict(caso=case,RHA_K_W=p['RHA'],masa_kg=p['mC'],Th_max_C=data.Th_C.max(),
        extrapolacion=data[['Tb_C','Th_C']].max().max()>100,**m))
pd.DataFrame(sens).to_csv(OUT/'sensibilidad_P_referencia.csv',index=False)

feasible=[]
fig,ax=plt.subplots(figsize=(8,4.8))
for rha,label in [(1.29,'400 LFM'),(2.11,'200 LFM'),(8.4,'Natural')]:
    p=P.copy();p['RHA']=rha
    curr=np.arange(6401)*.001;temp=[]
    for i in curr:
        x=equilibrium(i,p)
        gc=1/p['RCA']+p['K']+p['alpha']*i;gh=p['K']+1/rha-p['alpha']*i
        aj=np.array([[-gc/p['CC'],p['K']/p['CC']],[p['K']/p['CH'],-gh/p['CH']]])
        temp.append(x[0]-273.15 if max(np.linalg.eigvals(aj))<0 and min(x)>0 else np.nan)
    temp=np.array(temp);j=np.nanargmin(temp)
    feasible.append(dict(disipacion=label,RHA_K_W=rha,Tb_min_C=temp[j],I_en_min_A=curr[j],objetivo_5C_alcanzable=temp[j]<=5))
    ax.plot(curr,temp,label=label)
ax.axhline(5,color='k',ls='--',label='Objetivo 5 °C');ax.set_ylim(-5,50)
ax.set_xlabel('Corriente [A]');ax.set_ylabel('Tb de equilibrio [°C]');ax.legend()
ax.set_title('Factibilidad según ecuaciones de la planta\nBarrido de equilibrios estables; comprobación independiente')
fig.tight_layout();fig.savefig(OUT/'factibilidad_termica.pdf');fig.savefig(OUT/'factibilidad_termica.png',dpi=150);plt.close(fig)
pd.DataFrame(feasible).to_csv(OUT/'factibilidad_termica_referencia.csv',index=False)

# Known-response checks for the metric definitions.
tt=np.arange(10001)*.01;rr=np.full(len(tt),4);ii=np.ones(len(tt))
m=metrics(tt,rr,4+np.exp(-tt/5),ii,0,.02)
assert abs(m['tr_s']-5*np.log(9))<.03
assert abs(m['ts_ref_s']-5*np.log(50))<.03
m=metrics(tt,rr,4.2+.8*np.exp(-tt/5),ii,0,.02)
assert np.isnan(m['ts_ref_s']) and np.isfinite(m['ts_final_s'])
m=metrics(tt,rr,4.2+.8*np.exp(-tt/5),ii*6.4,0,.02)
assert abs(m['t_saturacion_s']-100)<1e-9
checks.append('Definiciones de métricas comprobadas con exponencial conocida, error residual y saturación constante.')
checks.append('6 casos de sensibilidad P; natural y 200 LFM marcados como extrapolación térmica.')
checks.append('Python usa generador NumPy; el ruido concreto no coincide muestra por muestra con rng de MATLAB.')
(OUT/'VERIFICACION_REALIZADA.txt').write_text('\n'.join(checks)+'\n',encoding='utf-8')
print(pd.DataFrame(analytic,columns=['Kp','p1','p2','ess1K','Ipedido','Iaplicado']).to_string(index=False))
print(pd.DataFrame(feasible).to_string(index=False))
print(pd.DataFrame(rows)[['planta','prueba','Kp_A_K','ess_abs_K','ts_ref_s','tr_s','Imax_A','t_saturacion_s']].to_string(index=False))
