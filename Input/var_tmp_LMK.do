
/*============================================================================
project:       Edades niveles de desagregación indicadores de mercado laboral
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
------------------------------------------------------------------------------
Creation Date:    20 Febrero 2020 - 11:38:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
===============================================================================*/

/*=================================================================================
                        Program description: para incluir en el programa maestro  
===================================================================================*/

*1 Edades niveles de desagregación indicadores de mercado laboral

	*1.1 Poblacion en Edad de Trabajar - PET y economicamente activa PEA:
				cap gen pet=1 if condocup_ci==1 | condocup_ci==2 | condocup_ci==3
				cap gen pea=1 if condocup_ci==1 | condocup_ci==2 
				replace pea = 0 if condocup_ci==3
				
	*1.2. Diferentes análisis de la PET:			
				gen age_15_64  = inrange(edad_ci,15,64) 
				gen age_25_64  = inrange(edad_ci,25,64) 
				gen age_65_mas = inrange(edad_ci,65,120) 
				
*2 ppp por país:
	
		*PPP 2011
				g 		ppp=1							// cambié la variable inicial que comenzaba con el valor de ARG
				replace	ppp=2.768382  if pais_c=="ARG"
				replace ppp=1.150889  if pais_c=="BHS"
				replace ppp=1.182611  if pais_c=="BLZ"
				replace ppp=2.906106  if pais_c=="BOL"
				replace ppp=1.658783  if pais_c=="BRA"
				replace ppp=2.412881  if pais_c=="BRB"
				replace ppp=370.1987  if pais_c=="CHL"
				replace ppp=1196.955  if pais_c=="COL"
				replace ppp=343.7857  if pais_c=="CRI"
				replace ppp=20.74103  if pais_c=="DOM"
				replace ppp=0.5472345 if pais_c=="ECU"
				replace ppp=3.873239  if pais_c=="GTM"
				replace ppp=10.08031  if pais_c=="HND"
				replace ppp=8.940212  if pais_c=="MEX"
				replace ppp=9.160075  if pais_c=="NIC"
				replace ppp=0.553408  if pais_c=="PAN"
				replace ppp=1.568639  if pais_c=="PER"
				replace ppp=2309.43   if pais_c=="PRY"
				replace ppp=0.5307735 if pais_c=="SLV"
				replace ppp=16.42385  if pais_c=="URY"
				replace ppp=2.915005  if pais_c=="VEN"
				replace ppp=63.35445  if pais_c=="JAM"
				replace ppp=4.619226  if pais_c=="TTO"

* 3 Variables de ingresos

	* 3.1 Población ocupada por encima del umbral del salario horario suficiente (1.95 US ppp)

				gen 	ylmpri_ppp = ylmpri_ci/ppp/ipc_c

				gen 	hsal_ci    = ylmpri_ppp/(horaspri_ci*4.3) if condocup_ci==1  
				gen 	liv_wage   = (hsal_ci>1.95) 
				replace liv_wage   =. if hsal==.			

	* 3.2 Ingreso laboral monetario
				replace ylm_ci=. if ylmpri_ci==.
				gen       ylab_ci=ylm_ci if emp_ci==1
				label var ylab_ci "ingreso laboral monetario total"

				gen 	  ylab_ppp=ylab_ci/ppp/ipc_c
				label var ylab_ppp "Ingreso laboral monetario total a US$PPP(2011)"
				
	* 3.3 Ingreso horario en la actividad principal USD
	
				gen 	hwage_ci=ylmpri_ci/(horaspri_ci*4.3) if condocup_ci==1
				gen 	hwage_ppp=hwage_ci/ppp/ipc_c
				
	* 3.4 Ingreso por pensión contributiva 
	
				gen  	 ypen_ppp=ypen_ci/ppp/ipc_c
				
	* 3.5 Salario mínimo mensual y horario - PPP 
	
				gen salmm_ppp=salmm_ci/ppp/ipc_c
				label var salmm_ppp "salario minimo legal mensual a US$PPP(2011)"
				
				gen hsmin_ppp=salmm_ppp/(5*8*4.3)
				label var hsmin_ppp "salario minimo legal horario a US$PPP(2011)"
				
				gen hsmin_ci=salmm_ci/(5*8*4.3)
				label var hsmin_ci "salario minimo legal horario"
	
	* 3.6 Salario por actividad principal menor al mínimo legal (por mes)
	
				g menorwmin = (ylmpri_ci<=salmm_ci) if condocup_ci==1 & salmm_ci !=. & ylmpri_ci!=.
	
	* 3.7 Valor de todas las pensiones
		
				egen ypent_ci = rsum(ypen_ci ypensub_ci), missing
				replace ypent_ci=. if edad_ci<65 | pension_ci==0
				label var ypent_ci "Valor de todas las pensiones que recibe"
	*3.8 Cuociente salario mínimo mensual/ingreso ocupación principal mensual
     gen sm_smeanm_ci= salmm_ci/ylmpri_ci
	*3.9 Cuociente salario mínimo por hora/ingreso ocupación principal por hora
     gen sm_smeanh_ci= hsmin_ci/hwage_ci
	
	
	
* 4 Formalidad laboral 
				gen 	formal_aux=1 if cotizando_ci==1
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="URY" & anio_c<=2000
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI" & anio_c<2000
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c>1998
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="COL" & anio_c<=1999
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="ECU" 
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BHS"

				drop formal_ci
				gen byte formal_ci=1 if formal_aux==1 & (condocup_ci==1 | condocup_ci==2)
				recode formal_ci .=0 if (condocup_ci==1 | condocup_ci==2)
				label var formal_ci "1=afiliado o cotizante / PEA"
				
* 5 Pensionistas 
				gen pensiont_ci=1 if pension_ci==1 | pensionsub_ci==1
				egen aux_pensiont_ci=mean(pensiont_ci)  /*indica q no hay dato ese año*/
				recode pensiont_ci .=0 if edad_ci>=65
				
* 7 Categorías de rama de actividad
				
				gen byte agro=1 if condocup_ci==1 & rama_ci==1
				recode agro .=0 if condocup_ci==1
				gen byte minas=1 if condocup_ci==1 & rama_ci==2
				recode minas .=0 if condocup_ci==1
				gen byte industria=1 if condocup_ci==1 & rama_ci==3
				recode industria .=0 if condocup_ci==1
				gen byte sspublicos=1 if condocup_ci==1 & rama_ci==4
				recode sspublicos .=0 if condocup_ci==1
				gen byte construccion=1 if condocup_ci==1 & rama_ci==5
				recode construccion .=0 if condocup_ci==1
				gen byte comercio=1 if condocup_ci==1 & rama_ci==6
				recode comercio .=0 if condocup_ci==1
				capture drop transporte
				gen byte transporte=1 if condocup_ci==1 & rama_ci==7
				recode transporte .=0 if condocup_ci==1
				gen byte financiero=1 if condocup_ci==1 & rama_ci==8
				recode financiero .=0 if condocup_ci==1
				gen byte servicios=1 if condocup_ci==1 & rama_ci==9
				recode servicios .=0 if condocup_ci==1		
				
* 8 Categorías de grandes grupos de ocupación

				gen byte profestecnico=1 if condocup_ci==1 & ocupa_ci==1
				recode profestecnico .=0 if condocup_ci==1
				gen byte director=1 if condocup_ci==1 & ocupa_ci==2
				recode director .=0 if condocup_ci==1
				gen byte administrativo=1 if condocup_ci==1 & ocupa_ci==3
				recode administrativo .=0 if condocup_ci==1
				gen byte comerciantes=1 if condocup_ci==1 & ocupa_ci==4
				recode comerciantes .=0 if condocup_ci==1
				gen byte trabss=1 if condocup_ci==1 & ocupa_ci==5
				recode trabss .=0 if condocup_ci==1
				gen byte trabagricola=1 if condocup_ci==1 & ocupa_ci==6
				recode trabagricola .=0 if condocup_ci==1
				gen byte obreros=1 if condocup_ci==1 & ocupa_ci==7
				recode obreros .=0 if condocup_ci==1
				gen byte ffaa=1 if condocup_ci==1 & ocupa_ci==8
				recode ffaa .=0 if condocup_ci==1
				gen byte otrostrab=1 if condocup_ci==1 & ocupa_ci==9
				recode otrostrab .=0 if condocup_ci==1
	
*9 Categorías

				gen byte asalariado=1 if condocup_ci==1 & categopri_ci==3
				recode asalariado .=0 if condocup_ci==1
				gen byte ctapropia=1 if condocup_ci==1 & categopri_ci==2
				recode ctapropia .=0 if condocup_ci==1 
				gen byte patron=1 if condocup_ci==1 & categopri_ci==1
				recode patron .=0 if condocup_ci==1 
				gen byte sinremuner=1 if condocup_ci==1 & categopri_ci==4
				recode sinremuner .=0 if condocup_ci==1							

*10 Categoría por tipo de contrato
				gen byte contratoindef=1 if condocup_ci==1 & tipocontrato_ci==1 & categopri_ci==3
				recode contratoindef .=0 if condocup_ci==1 & tipocontrato_ci !=. & categopri_ci==3
				gen byte contratofijo=1 if condocup_ci==1 & tipocontrato_ci==2 & categopri_ci==3
				recode contratofijo .=0 if condocup_ci==1 & tipocontrato_ci !=. & categopri_ci==3
				gen byte sincontrato=1 if condocup_ci==1 & tipocontrato_ci==3 & categopri_ci==3
				recode sincontrato .=0 if condocup_ci==1 & tipocontrato_ci !=. & categopri_ci==3

*11 Tasa de desempleo de larga duración
				recode durades_ci (12/max=1) (else=0), gen(desemplp_ci)
				cap replace desemplp_ci=1 if durades1_ci==5 & pais_c=="ARG" & anio_c>=2003
				cap recode desemplp_ci .=0 if condocup_ci==2 & pais_c=="ARG" & anio_c>=2003
				*9/24 mod MLO
				egen aux_n=mean(desemplp_ci)
				recode desemplp_ci 0=. if aux_n==0
				drop aux_n

				replace desemplp_ci=. if condocup_ci !=2 
				label var desemplp_ci "Desempleo de larga duracion"

				*9/24 mod MLO
				egen aux_n=mean(durades_ci)
				recode durades_ci 0=. if aux_n==0
				drop aux_n

