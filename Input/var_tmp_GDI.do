	* 1. Discapacidad
	             
			* 1.1 Hogares con al menos una persona con discapacidad
			bys idh_ch: egen num_dis_ch=total(dis_ci), m
			recode num_dis_ch (1/max=1), gen (dis_ch)

     * 2. Variables de raza
            gen afroind_ci=raza_ci
