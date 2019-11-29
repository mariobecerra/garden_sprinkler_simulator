function Rasensprenger (FileName,Fak)
% Rasensprengerversuch
% (c) 2002 - 2009
% Hauptteil: Karl Siebertz
% Erweiterung: David van Bebber
%
% Grundlegende Einstellungen
Kodierung = 1; % 0Keine 1[-1;+1] 2[0;+1] 3[1,2,...,ns]
dpzulVariante = 1; % 1Basis 2Variation
sflVariante = 1; % 1Basis 2Variation
% Konstanten
g=10; pi=3.141592654; rho=1000; dynVis=1;
kinVis=dynVis/rho; MaxFehler=0.005;
% Datei mit Parameterbelegung einlesen
if nargin < 1
FileName = 'l128.inp';
end
s=load(FileName);
[kzei, kspa] = size(s);
if nargin >= 2
% Umrechnungsfaktoren für kodierte Daten
PF = 1; % Position des Faktors
[aspa,amin,aplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[bspa,bmin,bplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[cspa,cmin,cplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[dspa,dmin,dplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[espa,emin,eplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[fspa,fmin,fplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[gspa,gmin,gplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
[hspa,hmin,hplu]=SetD(Fak(PF,1),Fak(PF,2),Fak(PF,3));PF=PF+1;
else
[aspa,amin,aplu]=SetD(1, 0 , 90 ); % alpha [°]
[bspa,bmin,bplu]=SetD(2, 0 , 90 ); % beta [°]
[cspa,cmin,cplu]=SetD(3, 2e-6, 4e-6); % Aquer [mm^2]
[dspa,dmin,dplu]=SetD(4, 0.1 , 0.2 ); % Durchmesser [m]
[espa,emin,eplu]=SetD(5, 0.01, 0.02); % Mtrocken [Nm]
[fspa,fmin,fplu]=SetD(6, 0.01, 0.02); % Mfluessig [Nm/s]
[gspa,gmin,gplu]=SetD(7, 1 , 2 ); % Druck [bar]
[hspa,hmin,hplu]=SetD(8, 7 , 8 ); % Durchm. Zuleitung [mm]
end
% Ausgabedateien
ido0=fopen('d-kompl.dat','w');ido1=fopen('d-qm1.dat','w');
ido2=fopen('d-qm2.dat' ,'w');ido3=fopen('d-qm3.dat','w');
ido4=fopen('d-qm.dat' ,'w');ido5=fopen('d-par.dat','w');
% große Schleife
ominc=0;
for j=1:kzei
n=0;sfl=0;qp=0;
% Auswahl der Kodierungsfunktion
switch Kodierung
case 0
NormFunc = @Norm0;
case 1
NormFunc = @Norm1;
case 2
NormFunc = @Norm2;
case 3
NormFunc = @Norm3;
otherwise
break
end
% Berechnung der Parameter
alpha= feval(NormFunc,amin,aplu,s,j,aspa);
beta = feval(NormFunc,bmin,bplu,s,j,bspa);
A = feval(NormFunc,cmin,cplu,s,j,cspa);
d = feval(NormFunc,dmin,dplu,s,j,dspa);
mt = feval(NormFunc,emin,eplu,s,j,espa);
mf = feval(NormFunc,fmin,fplu,s,j,fspa);
pin = feval(NormFunc,gmin,gplu,s,j,gspa);
dzul = feval(NormFunc,hmin,hplu,s,j,hspa);
pin = pin * 1e5;
h = pin * 1e-4;
R = d/2;
sina = sin(alpha*pi/180); cosa = cos(alpha*pi/180);
tana = tan(alpha*pi/180); sinb = sin( beta*pi/180);
cosb = cos(beta *pi/180); tanb = tan( beta*pi/180);
% Interpolation gültig für d von 5mm bis 10mm
cvzul = 10^(5.0704 -0.579413*dzul+0.0196432*dzul^2);
cvzul = (cvzul*60000^2);
% Startwerte
m0 = 2*rho*A*R*2*g*h*cosa*cosb;
n1 = 0.1*abs(m0-mt)/(mf+5.0e-4);
omega = 2*pi*n1;
msoll = mt+omega*mf;
mdiff = m0;
va0 = sqrt(2*pin/rho);
deltap= abs(msoll*omega)/(A*va0); % Verlustleistung Startwert
dzul = dzul * 1e-3;
Azul = pi/4*dzul^2;
if dpzulVariante == 1
dpzul=cvzul*(A*va0)^2;
else
dpzul=0.1*pin;
end
it=0; va=0; vr=0; m=m0;
% Durchfluss bei n = 0
if dpzulVariante == 1
qp= sqrt(pin/(cvzul+rho/8/A^2));
else
c = 128*R*A^2*kinVis/(dzul^2*Azul);
qp= -c/2+sqrt((c/2)^2+8/rho*pin*A^2);
end
va = qp/2/A;
vr = va;
vrt= va*cosb*cosa;
vat= vrt;
m = rho*qp*R*vat;
if m>mt % Haftreibung überschritten?
% Iteration bis zum Momentengleichgewicht
while abs(mdiff) > MaxFehler*abs(m)
n = omega/2/pi;
msoll= mt+n*mf;
varm = omega*R;
% Energiebilanz des gesamten Rasensprengers
pen = pin-deltap-dpzul;
if(pen < 0.01*pin)
fprintf('Fehler: pen < 0.01*pin\n');
pin,deltap,dpzul,msoll
m0,m,mdiff,ominc,vr,varm,va
va=0;
break;
end
va=sqrt(2*pen/rho);
if(va^2+varm^2*(cosa^2*cosb^2-1) < 0 )
fprintf('Fehler: va^2+varm^2*(cosa^2*cosb^2-1)<0\n');
va,vr,varm,vak
break;
end
vr = varm*cosa*cosb;
vr = vr+sqrt(va^2+varm^2*(cosa^2*cosb^2-1));
vrt = vr*cosb*cosa;
vrr = vr*cosa*sinb;
vrv = vr*sina;
vat = vrt-omega*R;
var = vrr;
vav = vrv;
% Kontrolle der Komponentenzerlegung
vak = sqrt(vat^2+var^2+vav^2);
m = 2*rho*vr*A*R*vat;
mdiff = m-msoll;
ominc = 0.1*min(abs(mdiff/m),(0.5*pen/pin));
% variable Schrittweite
omega = omega*(1+ominc)^sign(mdiff);
qp = 2*vr*A;
% Verlustleistung in Druck umgerechnet
deltap= abs(msoll*omega)/qp;
if dpzulVariante == 1
dpzul= cvzul*qp^2;
else
vzul = qp/2/Azul; % qp/2 durch einen Arm
Re = abs(dzul*vzul/kinVis);
dpzul= 64/Re*rho/2*R/dzul*vzul^2;
end
it=it+1;
if it > 10000
fprintf('Fehler: it > 10000\n');
it,msoll,mdiff,ominc,alpha,beta
A,d,mt,mf,vr,va,vrt,varm,vat,omega
break;
end
if(omega < 0.0062 )
fprintf('Fehler: omega < 0.0062\n');
it,omega
n=0;
break;
end
end
else
omega=0; n=0;
end
% Flugbahn
dtropf = sqrt(4*A/pi);
etaluft= 1.82e-5;
nyluft = etaluft/1.25;
v = va;
z = 1.0e-3;
sfl = 0.0;
vh = va*cosa;
vv = va*sina;
deltat = 0.005;
mtr = pi/6*dtropf^3*rho;
while z > 0
if(va<0.01)
break;
end
Re = va*dtropf/nyluft;
% Abraham, The Physics of Fluids 13, S.2194
zeta= 24/Re*(1+0.11*sqrt(Re))^2;
Fwid= 1.25/2*va^2*pi/4*dtropf^2*zeta;
atr = Fwid/mtr;
sfl = sfl+vh*deltat;
z = z+vv*deltat;
vh = vh-atr*cosa*deltat;
vv = vv-g*deltat-atr*sina*deltat;
va = sqrt(vh^2+vv^2);
cosa= vh/va;
sina= vv/va;
end;
if sflVariante == 1
sfl=sfl;
else
sfl=sqrt((R+sinb*sfl)^2+(cosb*sfl)^2);
end
qp = 2*vr*A*60000;
pverh= deltap/(rho*g*h);
% Ausgabe
Amm2 = 1000000*A;
dmm = 1000*d;
mtmm = mt*1000;
mfmm = mf*1000;
dzulmm= dzul*1e3;
fprintf(ido0,'%6.2e %6.2e %6.2e %6.2e ',alpha,beta,Amm2,dmm);
fprintf(ido0,'%6.2e %6.2e %6.2e %6.2e ',mtmm,mfmm,h,dzulmm);
fprintf(ido0,'%10.8e %10.8e %10.8e \n',n,sfl,qp);
fprintf(ido1,'%10.4f \n',n);
fprintf(ido2,'%10.4f \n',sfl);
fprintf(ido3,'%10.8f \n',qp);
fprintf(ido4,'%10.8f %10.8f %10.8f \n',n,sfl,qp);
fprintf(ido5,'%6.2e %6.2e %6.2e %6.2e ',alpha,beta,Amm2,dmm);
fprintf(ido5,'%6.2e %6.2e %6.2e %6.2e \n',mtmm,mfmm,h,dzulmm);
end;
fclose(ido0);fclose(ido1);fclose(ido2);
fclose(ido3);fclose(ido4);fclose(ido5);
% Hilfsfunktionen
function Value=Norm0(MinVal,MaxVal,data,row,col)% ohne Kodierung
if size(data,2) < col || size(data,1) < row
Value = (MinVal+MaxVal)/2;
else
Value = data(row,col);
end
function Value=Norm1(MinVal,MaxVal,data,row,col)% [-1;1]
if size(data,2) < col || size(data,1) < row
Value = (MinVal+MaxVal)/2;
else
Value = MinVal+(MaxVal-MinVal)*(data(row,col)+1)/2;
end
function Value=Norm2(MinVal,MaxVal,data,row,col)% [0;1]
if size(data,2) < col || size(data,1) < row
Value = (MinVal+MaxVal)/2;
else
Value = MinVal+(MaxVal-MinVal)*data(row,col);
end
function Value=Norm3(MinVal,MaxVal,data,row,col)% [1,2,...,ns]
if size(data,2) < col || size(data,1) < row
Value = (MinVal+MaxVal)/2;
else
minStufe=min(data(:,col));data(:,col)=data(:,col)-minStufe+1;
maxStufe=max(data(:,col));diffStufe=maxStufe-1;
if diffStufe == 0
Value=(MinVal+MaxVal)/2;
else
Value=MinVal+(MaxVal-MinVal)*(data(row,col)-1)/diffStufe;
end
end
function [spalte,minus,plus]=SetD(Spalte,Minimal,Maximal)
spalte=Spalte;minus=Minimal;plus=Maximal; % Set Factor Data



