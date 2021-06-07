

drop geografia_id tema description

gen iddate = "year"
gen idgeo = "country" 


rename tiempo_id year
rename pais_id isoalpha3
rename sexo sex
rename quintil_ingreso quintile
rename nivel_educativo education_level
rename grupo_etario age
rename etnicidad ethnicity
rename indicador indicator
rename valor value

replace ethnicity = "NA" if ethnicity == "No_aplica"

replace sex = "men"   if sex == "Hombre"
replace sex = "women" if sex == "Mujer"
replace sex = "NA" if sex == "No_aplica" 				


replace quintile = "quintile_1" if quintile == "quintil_1"
replace quintile = "quintile_2" if quintile == "quintil_2"
replace quintile = "quintile_3" if quintile == "quintil_3"
replace quintile = "quintile_4" if quintile == "quintil_4"
replace quintile = "quintile_5" if quintile == "quintil_5"
replace quintile = "NA" if quintile == "No_aplica" 				


replace age = "06_11" if age == "age_6_11"
replace age = "04_05" if age == "age_4_5"
replace age = "00_04" if age == "age_00_04"
replace age = "05_14" if age == "age_05_14"
replace age = "12_14" if age == "age_12_14"
replace age = "15_17" if age == "age_15_17"
replace age = "15_24" if age == "age_15_24"      
replace age = "15_29" if age == "age_15_29"      
replace age = "15_64" if age == "age_15_64"                
replace age = "18_23" if age == "age_18_23"
replace age = "18_24" if age == "age_18_24"                
replace age = "25_64" if age == "age_25_64"            
replace age = "65+" if age == "age_65_mas"                 
replace age = "NA" if age == "No_aplica" 				

			
replace education_level = "NA" if education_level == "No_aplica"                 
replace education_level = "preprimary" if education_level == "Prescolar"                 
replace education_level = "primary" if education_level == "Primaria"                 
replace education_level = "secondary" if education_level == "Secundaria"                 
replace education_level = "tertiary" if education_level == "Superior"                 
replace education_level = "0" if education_level == "anos_0"                 
replace education_level = "12" if education_level == "anos_12"                 
replace education_level = "13+" if education_level == "anos_13_o_mas"                 
replace education_level = "01-05" if education_level == "anos_1_5"                 
replace education_level = "06" if education_level == "anos_6"                 
replace education_level = "07-11" if education_level == "anos_7_11"                 
                 
                 
replace area = "NA" if area == "No_aplica"                 
replace area = "rural" if area == "Rural"                 
replace area = "urban" if area == "Urbano"                 
 
order iddate year idgeo isoalpha3 fuente indicator area quintile sex education_level age ethnicity value se cv sample

                
      
