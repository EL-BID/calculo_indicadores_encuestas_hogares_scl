/*=============================================================================================
project:       Edades niveles de desagregación indicadores de pobreza, demografia y vivienda
Author:        Angela Lopez 
Modified:      Daniela Zuluaga
Dependencies:  SCL/EDU/LMK - IDB 
-----------------------------------------------------------------------------------------------
Creation Date:    14 Febrero 2020 - 11:38:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
===============================================================================================*/

/*=============================================================================================
                        Program description: para incluir en el programa maestro  
===============================================================================================*/

	* 1. Demografia 
	             
			* 1.1 Muejeres jefe de hogar 
                gen jefa_ci=(sexo_ci==2 & jefe_ci==1)
                replace jefa_ci=. if sexo_ci==. | jefe_ci==.
                bys idh_ch: gen jefa_ch=sum(jefa_ci)
	    	* 1.2 Hogares unipersonales con miembro empleado
                gen unipemp=(emp_ci==1 & nmiembros_ch==1)
			* 1.3 Hogares con mujeres que trabajan
                gen woemp=(sexo_ci==2 & emp_ci==1)
                bys idh_ch: egen hhwoemp=sum(woemp)
			* 1.4 Miembros que son mayores a 18 años
                gen dumedad=(edad_ci>=18 & edad_ci!=.)
                gen yallsr18=ytot_ci if dumedad==1
                bys idh_ch:egen hhyallsr=sum(yallsr18)
			* 1.5 Ingreso del hogar generado por mujeres
                bys idh_ch: egen ywomen=sum(yallsr18) if sexo_ci==2
                bys idh_ch: egen hhywomen=max(ywomen)
			* 1.6 Proporción del ingreso del hogar generado por mujeres con respecto al ingreso total del hogar
                gen relacion1=hhywomen/hhyallsr 
			* 1.7 Hogares donde la mayor parte del ingreso es generado por  mujeres
			    gen hhfem_ch=(relacion1>0.50 & relacion1<.)
                replace hhfem_ch=0 if relacion1==0.50 & jefa_ch==0
			* 1.8 Porcentaje del ingreso laboral de adultos generado por mujeres
			    gen ylmpri18=ylmpri_ci if dumedad==1
                bys idh_ch:egen hhylmpri=sum(ylmpri18)
			* 1.9 Ingreso laboral generado por mujeres
			    by idh_ch, sort: egen yLwomen=sum(ylmpri18) if sexo_ci==2
                bys idh_ch: egen hhyLwomen=max(yLwomen)
                gen ShareYLMfem_ch=hhyLwomen/hhylmpri
			* 1.10 Union civil formal o informal
			    gen union_ci=(civil_ci==2)
				replace union_ci=. if civil_ci==.
			* 1.11 Hogares con familiares de 0-5 años
			    gen miembro6_ch=(nmenor6_ch>0 & nmenor6_ch<.)
                replace miembro6_ch=. if nmenor6_ch==.
			* 1.12 Hogares con familiares entre 6-16 años
			    egen byte nentre6y16_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=6 & edad_ci<=16)), by(idh_ch)
			    gen miembro6y16_ch=(nentre6y16_ch>0 &nentre6y16_ch<.)
                replace miembro6y16_ch=. if nentre6y16_ch==.
			* 1.13 Hogares con familiares de 65+ años	
				gen miembro65_ch=(nmayor65_ch>0 & nmayor65_ch<.)
                replace miembro65_ch=. if nmayor65_ch==.
			* 1.14 Hogares unipersonales
			    gen unip_ch=(clasehog_ch==1)
                replace unip_ch=. if clasehog_ch==.
			* 1.15 Hogares nucleares
			    gen nucl_ch=(clasehog_ch==2)
                replace nucl_ch=. if clasehog_ch==.
			* 1.16 Hogares ampliados
			    gen ampl_ch=(clasehog_ch==3)
                replace ampl_ch=. if clasehog_ch==.
			* 1.17 Hogares compuestos
			    gen comp_ch=(clasehog_ch==4)
                replace comp_ch=. if clasehog_ch==.
			* 1.18 Hogares corresidentes
			    gen corres_ch=(clasehog_ch==5)
                replace corres_ch=. if clasehog_ch==.
			* 1.19 Razón de Dependencia
			    bys idh_ch: egen perceptor_ci=sum(miembros_ci) if ytot_ci>0 & ytot_ci!=.
				bys idh_ch: egen perceptor_ch=max(perceptor_ci)
				gen depen_ch=nmiembros_ch/perceptor_ch
			* 1.20 Porcentaje pob menor de 18 años
			    gen pob18_ci=(edad_ci<18)
				replace pob18_ci=. if edad_ci==.
			* 1.21 Porcentaje pob 65+ años
			    gen pob65_ci=(edad_ci>=65 & edad_ci!=.)
				replace pob65_ci=. if edad_ci==.
			* 1.22 Porcentaje pob que reside en zonas urbanas
			   capture gen urbano_ci=(zona_c==1)
               replace urbano_ci=. if zona_c==.		
				
					
	* 2. Pobreza 
	
		* 1.Edades niveles de desagregación indicadores de pobreza y desigualdad
			
				gen age_00_04  = inrange(edad_ci,0,4) 
				gen age_05_14  = inrange(edad_ci,5,14) 
		* 2.1 Menos de 3.1 dolares 		
				gen     poor31 =0 if pc_ytot_ch!=.
				replace poor31 =1 if pc_ytot_ch<lp31_ci
				
		* 2.2 Menos de 5 dolares
				gen      poor =0 if pc_ytot_ch!=.
				replace  poor =1 if pc_ytot_ch<lp5_ci
		* 2.3 Entre 5 - 12 USD
				gen vulnerable=0 if pc_ytot_ch!=.
                replace vulnerable=1 if ((pc_ytot_ch>=lp5_ci) & (pc_ytot_ch<lp31_ci*4))
		* 2.4 Entre 12.4 y 62
				gen middle=0 if pc_ytot_ch!=.
				replace middle=1 if ((pc_ytot_ch>=lp31_ci*4) & (pc_ytot_ch<lp31_ci*20))
<<<<<<< Updated upstream
		
=======
				

	* 3. Vivienda 
	            gen dirtf=(piso_ch==0)
                replace dirtf=. if piso_ch==.
				

>>>>>>> Stashed changes

		
		
		