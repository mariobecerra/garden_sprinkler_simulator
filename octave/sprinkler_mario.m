% Der folgende Quellcode ist unter Octave und Matlab lauffähig. Erforderlich ist eine Eingabedatei 
% mit dem gewünschten Versuchsplan passend zu der gewählten Kodierung (zum Beispiel -1 bis 1). 
% Jede Zeile entspricht einer separaten Berechnung mit der entsprechenden Faktoreneinstellung. 
% Der gesamte Versuchsplan wird per Stapelverarbeitung mit einem Aufruf abgearbeitet.

% The following source code is executable under Octave and Matlab. Required is an input file with 
% the desired design matching the chosen encoding (for example -1 to 1). Each line corresponds to 
% a separate calculation with the corresponding factor setting. The entire experiment plan is 
% processed by batch with a call.

function sprinkler_mario (FileName)
	% Rasensprengerversuch
	% (c) 2002 - 2009
	% Hauptteil: Karl Siebertz
	% Erweiterung: David van Bebber
	%
	
	% Grundlegende Einstellungen
	% Basic settings
	
	dpzulVariante = 1; % 1Basis 2Variation
	sflVariante = 1; % 1Basis 2Variation

	% Konstanten
	% Constants
	g=10; pi=3.141592654; rho=1000; dynVis=1;
	kinVis=dynVis/rho; MaxFehler=0.005;

	% Datei mit Parameterbelegung einlesen
	% Read in file with parameter assignment
	if nargin < 1
		% FileName = 'l128.inp';
		% s= [1, 0 , 90 % alpha [°]
		% 	2, 0 , 90 % beta [°]
		% 	3, 2e-6, 4e-6 % Aquer [mm^2]
		% 	4, 0.1 , 0.2 % Durchmesser [m]
		% 	5, 0.01, 0.02 % Mtrocken [Nm]
		% 	6, 0.01, 0.02 % Mfluessig [Nm/s]
		% 	7, 1 , 2 % Druck [bar]
		% 	8, 7 , 8 ]; % Durchmesser Zuleitung [mm]
		% 	kzei = 8;

		s =	[40, 40, 3e-6, 0.17, 0.018, 0.018, 1.3, 7.44
			 40, 40, 3e-6, 0.17, 0.018, 0.018, 1.3, 7.44
			 11, 80, 3.4e-6, 0.11, 0.011, 0.012, 1.9, 7.94];

		[kzei, kspa] = size(s);

	end

	if nargin == 1
		s=load(FileName);
		[kzei, kspa] = size(s);
	end
	
	

	[aspa,amin,aplu]=SetD(1, 0 , 90 ); % alpha [°]
	[bspa,bmin,bplu]=SetD(2, 0 , 90 ); % beta [°]
	[cspa,cmin,cplu]=SetD(3, 2e-6, 4e-6); % Aquer [mm^2]
	[dspa,dmin,dplu]=SetD(4, 0.1 , 0.2 ); % Durchmesser [m]
	[espa,emin,eplu]=SetD(5, 0.01, 0.02); % Mtrocken [Nm]
	[fspa,fmin,fplu]=SetD(6, 0.01, 0.02); % Mfluessig [Nm/s]
	[gspa,gmin,gplu]=SetD(7, 1 , 2 ); % Druck [bar]
	[hspa,hmin,hplu]=SetD(8, 5 , 10 ); % Durchm. Zuleitung [mm]
	


	% Ausgabedateien
	% output files
	ido0=fopen('d-kompl.dat','w');
	% ido1=fopen('d-qm1.dat','w');
	% ido2=fopen('d-qm2.dat' ,'w');
	% ido3=fopen('d-qm3.dat','w');
	ido4=fopen('d-qm.dat' ,'w');
	% ido5=fopen('d-par.dat','w');


	% große Schleife
	% big loop
	ominc=0;
	for j=1:kzei
		n=0;sfl=0;qp=0;
		NormFunc = @Norm1;	
		
		% Berechnung der Parameter
		% Calculation of the parameters
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
		% Interpolation valid for d from 5mm to 10mm
		cvzul = 10^(5.0704 -0.579413*dzul+0.0196432*dzul^2);
		cvzul = (cvzul*60000^2);

		% Startwerte
		% starting values
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
		% Flow at n = 0
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
		if m>mt % Haftreibung überschritten? %% Stiction exceeded?
			% Iteration bis zum Momentengleichgewicht
			% Iteration until moment equilibrium
			while abs(mdiff) > MaxFehler*abs(m)
				n = omega/2/pi;
				msoll= mt+n*mf;
				varm = omega*R;
				% Energiebilanz des gesamten Rasensprengers
				% Energy balance of the entire lawn sprinkler
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
				% Control of component decomposition
				vak = sqrt(vat^2+var^2+vav^2);
				m = 2*rho*vr*A*R*vat;
				mdiff = m-msoll;
				ominc = 0.1*min(abs(mdiff/m),(0.5*pen/pin));
				% variable Schrittweite
				% variable step size
				omega = omega*(1+ominc)^sign(mdiff);
				qp = 2*vr*A;
				% Verlustleistung in Druck umgerechnet
				% Power loss converted into pressure
				deltap= abs(msoll*omega)/qp;
				if dpzulVariante == 1
					dpzul= cvzul*qp^2;
				else
					vzul = qp/2/Azul; % qp/2 durch einen Arm %% qp/2 through an arm
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
			end % while
		else
			omega=0; n=0;
		end
		% Flugbahn
		% trajectory
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
		% output
		Amm2 = 1000000*A;
		dmm = 1000*d;
		mtmm = mt*1000;
		mfmm = mf*1000;
		dzulmm= dzul*1e3;
		fprintf(ido0,'%6.2e %6.2e %6.2e %6.2e ',alpha,beta,Amm2,dmm);
		fprintf(ido0,'%6.2e %6.2e %6.2e %6.2e ',mtmm,mfmm,h,dzulmm);
		fprintf(ido0,'%10.8e %10.8e %10.8e \n',n,sfl,qp);
		% fprintf(ido1,'%10.4f \n',n);
		% fprintf(ido2,'%10.4f \n',sfl);
		% fprintf(ido3,'%10.8f \n',qp);
		fprintf(ido4,'%10.8f %10.8f %10.8f \n',n,sfl,qp);
		% fprintf(ido5,'%6.2e %6.2e %6.2e %6.2e ',alpha,beta,Amm2,dmm);
		% fprintf(ido5,'%6.2e %6.2e %6.2e %6.2e \n',mtmm,mfmm,h,dzulmm);
	end; %% End huge for loop
	fclose(ido0);
	% fclose(ido1);
	% fclose(ido2);
	% fclose(ido3);
	fclose(ido4);
	%fclose(ido5);
end




% function Value=Norm1(MinVal,MaxVal,data,row,col)% [-1;1]
% 	if size(data,2) < col || size(data,1) < row
% 		Value = (MinVal+MaxVal)/2;
% 	else
% 		Value = MinVal+(MaxVal-MinVal)*(data(row,col)+1)/2;
% 	end
% end

function Value=Norm1(MinVal,MaxVal,data,row,col)% [-1;1]
	if size(data,2) < col || size(data,1) < row
		Value = (MinVal+MaxVal)/2;
	else
		Value = data(row,col);
	end
end



function [column,minus,plus]=SetD(Column,Minimal,Maximal)
	column=Column;minus=Minimal;plus=Maximal; % Set Factor Data
end




% An warmen Sommertagen gesellt sich zur Bewässerungsfunktion des Rasensprengers noch die Nebenfunktion der Kinderbelustigung. Bei der dann angestrebten langen Nutzungsdauer gelangt zu viel Wasser auf den Rasen. Insgesamt lassen sich drei unabhängige Qualitätsmerkmale identifizieren: große Reichweite, hohe Drehzahl und geringer Wasserverbrauch. Betrachtet wird das System Rasensprenger ab Zuleitung hinter dem Absperrhahn.


% A.2 Berechnung
% Das bereits im Kapitel Auswertung verwendete Fallbeispiel wird hier näher erläutert, um dem Leser die Möglichkeit zu geben, es bei Bedarf selbst für eigene Studien zu benutzen, sozusagen als Erstanwendung. Insgesamt gibt es acht voneinander unabhängige Parameter mit dem in der Tabelle vorgeschlagenen Einstellbereich. Das zugehörige Octave / Matlab Modell ist numerisch recht stabil und gestattet auch einen größeren Einstellbereich.

% Eine konstante Drehzahl stellt sich ein, wenn Reibungsmoment und Antriebsmoment im Gleichgewicht stehen. Das Reibungsmoment besteht aus einem konstanten Anteil, der trockenen Reibung und einem drehzahlabhängigen Anteil, der flüssigen Reibung.


% Die Komponentenzerlegung der Absolutgeschwindigkeit in tangentiale, radiale und vertikale Komponente ist nicht trivial, da die beiden Düsenwinkel die relative
% Ausrichtung des Wasserstrahls in Bezug zum rotierenden Rasensprenger angeben. Mit Kenntnis der Düsengeschwindigkeit läßt sich jedoch die Relativgeschwindigkeit zunächst betragsmäßig berechnen und anschließend in Komponenten zerlegen. Durch vektorielle Addition mit der Düsengeschwindigkeit folgt daraus dann die gesuchte Absolutgeschwindigkeit als vollständig bestimmter Vektor. Sobald die Relativgeschwindigkeit ermittelt ist, läßt sich auch der Volumenstrom angeben.



% A.3 Erweiterungen

% Basierend auf der dargestellten Basisvariante des Berechnungsprogramms wurden verschiedene optionale Erweiterungen eingeführt, um größere Stufenbreiten rechnen zu können. Dadurch entstehen stark nichtlineare Zusammenhänge zwischen den Eingangsgrößen und den Qualitätsmerkmalen. Für die Verdeutlichung der aufwendigen Verfahren (Kriging, Radial Based Functions, neuronale Netze etc.) war dies erforderlich.

% Druckverlust
% Die Berechnung des Druckverlustes in der Zuführleitung kann neben der Basisvariante ebenfalls durch den in Gleichung A.29 dargestellten Ansatz ermittelt werden. Durch die separate Berechnung des Reibungskoeffizienten λ können neben laminaren ebenfalls turbulente Strömungsverluste berücksichtigt werden, worauf im Rahmen dieser Arbeit verzichtet wird. Weiterhin wird im Gegensatz zur Basisvariante nicht ein Zulauf vor dem Rasensprenger angenommen, sondern die Arme selbst als Zulauf betrachtet, so dass neben dem Durchmesser dzul der Leitung ebenfalls der Radius R des Rasensprengers einen direkten Einfluss auf den Druckverlust aufweist.



% Flugweite
% Soll der Radius R des Rasensprengers in der Flugweitenbestimmung berücksichtigt werden, so kann die Flugweite "s" mit der Basisflugweite sh bestimmt werden.

% Haftreibung
% Werden die Faktoren a, b und MRt in großen Bereichen variiert, so treten Faktorkombinationen auf, bei denen das Antriebsmoment des Wasserstrahls geringer ist als das Reibmoment MRt, so dass keine Rotation des Rasensprengers auftritt (n = 0). Da der implementierte Lösungsalgorithmus in diesen speziellen Fällen keinen Gleichgewichtszustand findet, wird vor der Volumenstromberechnung geprüft, ob die Haftreibung bei n = 0 überwunden wird. Ist dieses nicht der Fall, so wird die Flugweite mit dem berechneten Volumenstrom Q0 und der Drehzahl n = 0 ermittelt.



% Kodierung

% Neben der Standardkodierung [−1; 1] sind insgesamt folgende Faktorkodierungen implementiert worden:
% • keine Kodierung
% • [−1; 1]
% • [0; 1]
% • [1,2,3,···,ns]

% Variablen-Übergabe
% Zur Erleichterung einer Automatisierung verschiedener Versuchsläufe können der Berechnungsfunktion folgende Variablen übergeben werden:
% • FileName: Name der Eingabedatei (z.B. ’l128.inp’)
% • Fak: Faktoreinstellungen [Spalte der Eingabedatei,Min,Max]
% Ein Beispiel für eine mögliche Faktoreinstellung ist:


% Fak=[1, 0 , 90 % alpha [°]
% 2, 0 , 90 % beta [°]
% 3, 2e-6, 4e-6 % Aquer [mm^2]
% 4, 0.1 , 0.2 % Durchmesser [m]
% 5, 0.01, 0.02 % Mtrocken [Nm]
% 6, 0.01, 0.02 % Mfluessig [Nm/s]
% 7, 1 , 2 % Druck [bar]
% 8, 7 , 10 ]; % Durchmesser Zuleitung [mm







% On warm summer days joined to the irrigation function of lawn sprinkler nor the side function of children's entertainment. In the then desired long service life gets too much water on the lawn. Overall, three independent quality features can be identified: long range, high speed and low water consumption. The system Lawn Sprinkler is considered from the supply line behind the stopcock.


% A.2 calculation
% The case study already used in the chapter Evaluation will be explained in more detail here in order to give the reader the possibility to use it for own studies if required, as a first-time application. In total, there are eight independent parameters with the adjustment range proposed in the table. The associated Octave / Matlab model is numerically quite stable and also allows a larger adjustment range.

% A constant speed is set when friction torque and drive torque are in equilibrium. The friction torque consists of a constant proportion, the dry friction and a speed-dependent proportion, the liquid friction.



% The component decomposition of the absolute velocity into tangential, radial and vertical components is not trivial, since the two nozzle angles are the relative
% Specify the orientation of the water jet with respect to the rotating lawn sprinkler. With knowledge of the nozzle speed, however, the relative speed can first be calculated in terms of absolute value and then decomposed into components. By vectorial addition with the nozzle velocity, the sought absolute velocity then follows as the completely determined vector. As soon as the relative speed has been determined, the volumetric flow can also be indicated.


% A.3 extensions

% Based on the basic variant of the calculation program, various optional enhancements have been introduced in order to be able to calculate larger step widths. This results in strongly non-linear relationships between the input variables and the quality features. This was necessary for the clarification of the complex procedures (kriging, radial based functions, neural networks, etc.).

% pressure drop
% The calculation of the pressure loss in the supply line can be determined in addition to the basic variant also by the approach shown in equation A.29. The separate calculation of the coefficient of friction λ can be taken into account in addition to laminar turbulent flow losses, which is omitted in this work. Furthermore, in contrast to the basic variant, not an inlet in front of the lawn sprinkler is assumed, but the arms themselves are regarded as inflow, so that in addition to the diameter dzul of the line, the radius R of the lawn sprinkler also has a direct influence on the pressure loss.

% stiction
% If the factors a, b and MRt are varied in large ranges, then factor combinations occur in which the drive torque of the water jet is lower than the friction torque MRt, so that no rotation of the lawn sprinkler occurs (n = 0). Since the implemented solution algorithm does not find an equilibrium state in these special cases, it is checked before the volumetric flow calculation whether the static friction at n = 0 is overcome. If this is not the case, the flight distance is calculated with the calculated volume flow Q0 and the speed n = 0.


% coding

% In addition to the standard encoding [-1; 1] the following factor codes have been implemented:
% • no coding
% • [-1; 1]
% • [0; 1]
% • [1,2,3, ···, ns]

% Variable transfer
% To facilitate automation of various test runs, the following functions can be passed to the calculation function:
% • FileName: name of the input file (for example, 'l128.inp')
% • Fak: Factor settings [input file column, Min, Max]

% An example of a possible factor setting is:

% Fak = [	1, 0 , 90 % alpha [°]
% 		2, 0 , 90 % beta [°]
% 		3, 2e-6, 4e-6 % Aquer [mm^2]
% 		4, 0.1 , 0.2 % Durchmesser [m]
% 		5, 0.01, 0.02 % Mtrocken [Nm]
% 		6, 0.01, 0.02 % Mfluessig [Nm/s]
% 		7, 1 , 2 % Druck [bar]
% 		8, 7 , 10 ]; % Durchmesser Zuleitung [mm]





