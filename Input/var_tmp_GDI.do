	* 1. Discapacidad
	             
			* 1.1 Hogares con al menos una persona con discapacidad
			bys idh_ch: egen num_dis_ch=total(dis_ci), m
			recode num_dis_ch (1/max=1), gen (dis_ch)

     * 2. Variables de raza
            * 1.1 Variable de raza individual
			gen afroind_ci=raza_ci
			
			*1.2 Variable de raza del jefe del hogar asignado a todos los miembros del hogar
			gen afroind_jefe_ch= afroind_ci if jefe_ci==1
            bys idh_ch: egen afroind_ch= total (afroind_jefe_ch)
			
			