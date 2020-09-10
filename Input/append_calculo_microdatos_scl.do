	
	
	
	preserve 
	
	tempfile microdatos_`pais'_`ano'
	keep pais_c anio_c idh_ch zona_c factor_ch relacion_ci sexo_ci edad_ci aedu_ci nmiembros_ch ylm_ci ylnm_ci ynlm_ci ynlnm_ci lp31_ci asiste_ci condocup_ci pension_ci formal_ci miembros_ci salmm_ci rama_ci raza_ci raza_idioma_ci cotizando_ci afiliado_ci categopri_ci Total Hombre Mujer Urbano Rural quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 jefe_ci age_pres age_prim asis_prim age_seco asis_seco age_tert asis_tert age_term_p_c tprimaria age_term_s_c tsecundaria leavers asis_prim_c age_prim_sobre pea pet liv_wage ylab_ppp hwage_ppp pensiont_ci ypen_ppp poor31 poor vulnerable middle aguared_ch des2_ch luz_ch dirtf 

	save `microdatos_`pais'_`ano'', replace

		use "${covidtmp}\microdatos_encuestas_hogares_scl.dta"
		append using  `microdatos_`pais'_`ano''
		

		save "${covidtmp}\microdatos_encuestas_hogares_scl", replace 
		
	restore 