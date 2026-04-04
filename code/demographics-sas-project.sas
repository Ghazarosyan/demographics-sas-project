/*

Mkrtich Ghazarosyan

*/

libname task_lib "/home/u63766660/cv_projects/data";

proc format;
	value $f_section
		"section1" = "Age at Informed Consent (years)"
		
		"section2.0" = "Gender"
		"section2.1" = "    Male"
		"section2.2" = "    Female"
		
		"section3.0" = "Ethnicity"
		"section3.1" = "    Hispanic or Latino"
		"section3.2" = "    Not Hispanic or Latino"
		"section3.3" = "    Unknown"
		
		"section4.0" = "Race"
		"section4.1" = "    White"
		"section4.2" = "    Black or African American"
		"section4.3" = "    Asian"
		"section4.4" = "    American Indian or Alaska Native"
		"section4.5" = "    Native Hawaiian or Other Pacific Islander"
		"section4.6" = "    Multiple Race"
		
		"section5" = "Height at Screening (cm)"

		"section6" = "Weight at Screening (kg)"

		"section7" = "BMI at Screening (kg/m^2)"
		
		"sectionM.1" = "N"
		"sectionM.2" = "Mean"
		"sectionM.3" = "Std. Dev."
		"sectionM.4" = "Median"
		"sectionM.5" = "Min, Max"
		
		"sectionF" = "n (%)"
	;
	
	invalue inf_gender
		"m" = 1
		"f" = 2
	;
	
	invalue inf_ethnicity
		"hispanic or latino" = 1
		"not hispanic or latino" = 2
		"unknown" = 3
	;
	
	invalue inf_race
		"white" = 1
		"black or african american" = 2
		"asian" = 3
		"american indian or alaska native" = 4
		"native hawaiian or other pacific islander" = 5
		"multiple race" = 6
	;
	
	invalue inf_sectionNum
		"AAGE" = 1
		"SEX" = 2
		"ETHNIC" = 3
		"RACE" = 4
		"HEIGHTBL" = 5
		"WEIGHTBL" = 6
		"BMIBL" = 7
	;
	
	invalue inf_means
		"char_n" = 1
		"char_mean" = 2
		"char_std" = 3
		"char_median" = 4
		"char_min_max" = 5
	;
	
	value $f_missing
		"N" = "00"
		"Mean" = "00.0"
		"Std. Dev." = "00.00"
		"Median" = "00.0"
		"Min, Max" = "00.0"
		"n (%)" = "00 (00.0)"
	;
run;

/********** DUMMY **********/
/* dummy for means */
%macro mcpr_dummy_means(sectionNum=);
	data dummy_section&sectionNum.;
		length COL1 $ 200    COL2 $ 200;
		section = &sectionNum.;
		do index = 1 to 5;
			if index = 1 then COL1 = "section&sectionNum."; else COL1 = "";
			COL2 = "sectionM." || strip(put(index, best.));
			output;
		end;
	run;
%mend mcpr_dummy_means;

%mcpr_dummy_means(sectionNum=1);
%mcpr_dummy_means(sectionNum=5);
%mcpr_dummy_means(sectionNum=6);
%mcpr_dummy_means(sectionNum=7);
/* end - dummy for means */



/* dummy for freq */
%macro mcpr_dummy_freq(sectionNum=, indexNum=);
	data dummy_section&sectionNum.;
		length COL1 $ 200    COL2 $ 200;
		section = &sectionNum.;
		do index = 0 to &indexNum.;
			COL1 = "section&sectionNum.." || strip(put(index, best.));
			if index = 0 then COL2 = ""; else COL2 = "sectionF";
			output;
		end;
	run;
%mend mcpr_dummy_freq;

%mcpr_dummy_freq(sectionNum=2, indexNum=2);
%mcpr_dummy_freq(sectionNum=3, indexNum=3);
%mcpr_dummy_freq(sectionNum=4, indexNum=6);
/* end - dummy for freq */



/* main dummy */
data main_dummy;
	retain COL1 COL2 section index;
	set dummy_section1 dummy_section2 dummy_section3 dummy_section4 dummy_section5 dummy_section6 dummy_section7;
	COL1 = put(COL1, $f_section.); COL2 = put(COL2, $f_section.);
run;

proc sort data=main_dummy;
	by section index;
run;
/* end - main dummy */
/********** end - DUMMY **********/



/********** task_ADSL **********/
data ADSL;
	retain USUBJID AAGE SEX SEXN ETHNIC ETHNICN RACE RACEN HEIGHTBL WEIGHTBL BMIBL;
	
	set task_lib.adsl( where=(SAFFL="Y") );
	
	AAGE = AGE;
	SEXN = input(lowcase(SEX), inf_gender.);
	ETHNICN = input(lowcase(ETHNIC), inf_ethnicity.);
	RACEN = input(lowcase(RACE), inf_race.);
	
	keep USUBJID AAGE SEX SEXN ETHNIC ETHNICN RACE RACEN HEIGHTBL WEIGHTBL BMIBL;
run;
/********** end - task_ADSL **********/



/********** BIG_N **********/
proc sql noprint;
	select count(*) into:BIG_N trimmed from ADSL;
quit;
*	%put &=BIG_N.;
/********** end - BIG_N **********/



/********** 1 5 6 7 sections **********/
%macro mcpr_means(var=);
	proc means data=ADSL noprint;
		var &var.;
		output
			out = data_&var.
			n = _n    mean = _mean    std = _std    median = _median    min = _min    max = _max
		;
	run;
	
	data data_&var.;
		set data_&var.;
		char_n = strip(put(_n, best.));
		char_mean = strip(put(_mean, 8.1));
		char_std = strip(put(_std, 8.2));
		char_median = strip(put(_median, 8.1));
		char_min_max = strip(put(_min, best.)) || ", " || strip(put(_max, best.));
	run;
	
	proc transpose data=data_&var. out=final_&var.( rename = (COL1=COL3) );
		var 	char_n    char_mean    char_std    char_median    char_min_max;
	run;
	
	data final_&var.;
		length COL3 $ 200;
		set final_&var.;
		
		section = input(upcase("&var."), inf_sectionNum.);
		index = input(_NAME_, inf_means.);
		
		keep COL3 section index;
	run;
	
	proc sort data=final_&var.;
		by section index;
	run;
%mend mcpr_means;

%mcpr_means(var=AAGE);
%mcpr_means(var=HEIGHTBL);
%mcpr_means(var=WEIGHTBL);
%mcpr_means(var=BMIBL);
/********** end - 1 5 6 7 sections **********/



/********** 2 3 4 sections **********/
%macro mcpr_freq(var=);
	proc freq data=ADSL noprint;
		tables
			&var. * &var.N / 
			out=data_&var.(drop=percent)
		;
	run;
	
	data final_&var.;
		length COL3 $ 200;
		set data_&var.;
		COL3 = strip( put(COUNT, 8.) ) || " (" || strip( put(((COUNT / &BIG_N.) * 100), 8.1) ) || ")";
		section = input(upcase("&var."), inf_sectionNum.);
		index = &var.N;
	
		keep COL3 section index;
	run;
	
	proc sort data=final_&var.;
		by section index;
	run;
%mend mcpr_freq;

%mcpr_freq(var=SEX);
%mcpr_freq(var=ETHNIC);
%mcpr_freq(var=RACE);
/********** end - 2 3 4 sections **********/



/********** final data **********/
%put &=BIG_N.;

data final;
	merge main_dummy    final_SEX    final_ETHNIC    final_RACE    final_AAGE    final_HEIGHTBL    final_WEIGHTBL    final_BMIBL;
	by section index;
	
	if missing(COL3) and index ne 0 then COL3 = put(COL2, $f_missing.);
	
*	attrib
		col1 label="Parameter"
		col2 label="Statistic"
		col3 label="Overall"
	;
	rename
		col1 = Parameter
		col2 = Statistic
		col3 = Overall
	;
	
	drop section index;
run;
/********** end - final data **********/