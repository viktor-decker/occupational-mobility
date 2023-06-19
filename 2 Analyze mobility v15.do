/*------------------------------------------------------------------------------
                     #1. Configuring your dofile
------------------------------------------------------------------------------*/

* Setup
	version		16.0            // Stata version control (put your own version)
	clear		all             // clear working memory
	macro		drop _all       // clear macros
	set 		seed 339487731	// set seed

* Load required packages
	* ssc			install blindschemes, replace 	// for nice looking graphs
	* ssc			install estout, replace // for nice tables
	* net 			from "http://www.stata.com" // for combined graphs with 1 legend
    * net 			cd users
    * net 			cd vwiggins
    * net 			install grc1leg
	* ssc			install coefplot
	* net			install cleanplots, from("https://tdmize.github.io/data/cleanplots")
	
* Settings for graphs
	graph 		set window fontface "Georgia"
	set 		scheme cleanplots
	
* Working directory
	global		wdir  "/Users/vvdecker/Library/CloudStorage/OneDrive-UvA/PhD/1st Paper/stats" 


* Define paths to subdirectories (don't change anything here)
	global 		data 		"$wdir/0_data"   		// folder for original data
	global		code 		"$wdir/1_dofiles"   	// folder for do-files
	global		posted 		"$wdir/2_posted"    	// data ready for analysis
	global		temp 		"$wdir/3_temp"   		// folder for temporary files
	global		tables		"$wdir/4_tables" 		// folder for table output 
	global		graphs		"$wdir/5_graphs" 		// folder for graph output 


	
/*------------------------------------------------------------------------------
            #2. Information used in Data, variables, and method
------------------------------------------------------------------------------*/

* Load original data file
 	use			"$posted/masterfile.dta", clear
	
* Number of waves and range of years
	unique 		syear // 37 waves
	sum			syear // Min: 1984, Max:2020
	
* Number of observations and respondents in initial data set
	sort		pid syear
	unique		pid // observations: 741,927 respondents: 103,412
	
* Number of observations and respondents in analytic sample
	use			"$posted/prepdata.dta", clear
	sort		pid syear
	unique		pid
	
* Percentages of initial data set
	dis 411463/741927 // observation level
	dis 52911/103412 // individual level
	
* Number of observations per case
	tab 		N if pickone==1
	sum 		N if pickone==1
	
* Descriptive table
	
	/* I run all descriptives separately and then piece them together in Excel
	to make a nice looking table that accomodates my needs. */
	
	* Occupational change
	tab occupch
	sum occupch
	
	*Educational specificity
	tab voceduc if pickone==1
	sum voceduc if pickone==1
	
	*Educational level
	tab higheduc if pickone==1
	sum higheduc if pickone==1
	
	*Voluntary occup. change
	tab volch
	sum volch
	
	*Involuntary occup. change
	tab invch
	sum invch
	
	* Age
	sum age
	
	* Gender
	tab female if pickone==1
	sum female if pickone==1
	
	* Migration background
	tab migback if pickone==1
	sum migback if pickone==1	
	
	* Year of birth
	sum gebjahr if pickone==1
	
	* Cohorts groups
	tab cohg if pickone==1	
 
	
/*------------------------------------------------------------------------------
                     #3. Results section
------------------------------------------------------------------------------*/
	
	
* Load data file
	use		"$posted/prepdata.dta", clear
	
* Sort cases
	sort	pid syear
	xtset	pid syear
	


* Table 2: Predicting probabilities to enter a new occupation

	eststo		m1: ///
	mixed 		occupch i.voceduc || pid:, var
	
	eststo		m2: ///
	mixed	 	occupch i.voceduc i.higheduc i.female i.migback i.yob || pid:, var 
	
	eststo		m3: ///
	mixed	 	occupch i.voceduc##c.agec10 i.higheduc i.female i.migback i.yob || pid: agec10, var
	
	eststo		m4: ///
	mixed	 	occupch i.voceduc##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10, var
				
	eststo		m5: ///
	mixed	 	occupch i.voceduc##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10, var
				
	eststo		m6: ///
	mixed	 	occupch i.voceduc##c.agec10##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10 agec10_agec10_agec10_agec10, var
				
	
	// full model
	esttab		m1 m2 m3 m4 m5 m6 ///
				using "$tables/occupch-full.rtf", replace 						///
					b(%9.3f) se(%9.3f) aic(%9.0f) bic(%9.0f) 				///
					noomit nobase star nonum nodepvars nogaps label			///
					interaction("*") 										///
					sfmt(%9.4g) 											///
					transform(ln*: exp(@)^2 exp(@)^2)						///
					drop(*.yob)												///
					mtitles("M1" "M2" "M3" "M4" "M5" "M6") 					///
					coeflabels(												///		
					_cons "Intercept" 										///
					1.voceduc "Vocational educ."							///	
					1.higheduc "Tertiary educ."								///
					1.female "Female"										///
					1.migback "Migration backgr." 							///	
					agec10 "Age/10" 								///	
					c.agec10#c.agec10 "Age2/10"								///
					c.agec10#c.agec10#c.agec10 "Age3/10"						///
					c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10"				///
					1.voceduc#c.agec10 "Age/10 * Voc. educ."						///
					1.voceduc#c.agec10#c.agec10 "Age2/10 * Voc educ."					///
					1.voceduc#c.agec10#c.agec10#c.agec10 "Age3/10 * Voc. educ."				///
					1.voceduc#c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10 * Voc. educ.")	///
					eqlabels("" "Intercept variance" "Residual variance" "Slope variance: Age" ///
					"Slope variance: Age2" "Slope variance: Age3" "Slope variance: Age4", none)
					
	// reduced model				
	esttab		m1 m2 m3 m6 ///
				using "$tables/occupch-reduc.rtf", replace 						///
					b(%9.3f) se(%9.3f) aic(%9.0f) bic(%9.0f) 				///
					noomit nobase star nonum nodepvars nogaps label			///
					interaction("*") 										///
					sfmt(%9.4g) 											///
					transform(ln*: exp(@)^2 exp(@)^2)						///
					drop(*.yob *.higheduc *.migback *.female)				///
					mtitles("M1" "M2" "M3" "M4") 							///
					coeflabels(												///		
					_cons "Intercept" 										///
					1.voceduc "Vocational educ."							///	
					1.higheduc "Tertiary educ."								///
					1.female "Female"										///
					1.migback "Migration backgr." 							///	
					agec10 "Age/10" 								///	
					c.agec10#c.agec10 "Age2/10"								///
					c.agec10#c.agec10#c.agec10 "Age3/10"						///
					c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10"				///
					1.voceduc#c.agec10 "Age/10 * Voc. educ."						///
					1.voceduc#c.agec10#c.agec10 "Age2/10 * Voc. educ."					///
					1.voceduc#c.agec10#c.agec10#c.agec10 "Age3/10 * Voc. educ."				///
					1.voceduc#c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10 * Voc. educ.")	///
					eqlabels("" "Intercept variance" "Residual variance" "Slope variance: Age" ///
					"Slope variance: Age2" "Slope variance: Age3" "Slope variance: Age4", none)
	
	// Some additional calculations	
	est restore m1
	margins // probability to change occupations in a given year
	margins, at(voceduc=(0 1))
	
	est restore m6
	margins, dydx(voceduc)
	margins, at(voceduc=(0 1))
	
	// Coefplot
	est restore m6
	margins, 	at(voceduc=(1)) post
	est 		store voc_mean
	
	est restore m6
	margins, 	at(voceduc=(0)) post
	est 		store gen_mean
	
	coefplot (voc_mean, msymbol(O) mcolor(cranberry) msize(large)   ///
					ciopts(color(cranberry) lpattern(solid) recast(rcap))  ///
					mlabels mlabcolor(cranberry) mlabsize(large))	  ///
			 (gen_mean, msymbol(S) mcolor(navy) msize(large) ///
					ciopts(color(navy) lpattern(solid) recast(rcap))  ///
					mlabels mlabcolor(navy) mlabsize(large))  	 ///
				, title("", size(vlarge) margin(b=3)) ///
				ytitle("Predicted probabilities", size(medium)) ///
				ylab(0.057(0.002)0.067, labsize(medium)) ///
				xlab(, nolabels nogrid) 			///
				graphregion(color(white) fcolor(white)) plotregion(color(white))	///
				vertical  format(%9.2g) ///
				legend(order(2 "Vocational educ." 4 "General educ") ring(0) position(5))
	graph		export "$graphs/coef-occupch.png", replace width(10000)
	


* Table 3: Voluntary / involutnary probabilities for occupational change 	
	
	eststo		v1: ///
	mixed 		volch i.voceduc || pid:, var	
	
	eststo		v2: ///
	mixed	 	volch i.voceduc##c.agec10##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10 agec10_agec10_agec10_agec10, var
				
	eststo		i1: ///
	mixed 		invch i.voceduc || pid:, var	
	
	eststo		i2: ///
	mixed	 	invch i.voceduc##c.agec10##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10 agec10_agec10_agec10_agec10, var

	// reduced model				
	esttab		v1 v2 i1 i2 ///
				using "$tables/volinv-reduc.rtf", replace 						///
					b(%9.3f) se(%9.3f) aic(%9.0f) bic(%9.0f) 				///
					noomit nobase star nonum nodepvars nogaps label			///
					interaction("*") 										///
					sfmt(%9.4g) 											///
					transform(ln*: exp(@)^2 exp(@)^2)						///
					drop(*.yob *.higheduc *.migback *.female)				///
					mtitles("M5" "M6" "M7" "M8") 							///
					coeflabels(												///		
					_cons "Intercept" 										///
					1.voceduc "Vocational educ."							///	
					1.higheduc "Tertiary educ."								///
					1.female "Female"										///
					1.migback "Migration backgr." 							///	
					agec10 "Age/10" 								///	
					c.agec10#c.agec10 "Age2/10"								///
					c.agec10#c.agec10#c.agec10 "Age3/10"						///
					c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10"				///
					1.voceduc#c.agec10 "Age/10 * Voc. educ."						///
					1.voceduc#c.agec10#c.agec10 "Age2/10 * Voc. educ."					///
					1.voceduc#c.agec10#c.agec10#c.agec10 "Age3/10 * Voc. educ."				///
					1.voceduc#c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10 * Voc. educ.")	///
					eqlabels("" "Intercept variance" "Residual variance" "Slope variance: Age" ///
					"Slope variance: Age2" "Slope variance: Age3" "Slope variance: Age4", none)
	
	// additional calculations
	est restore v1
	margins
	
	est restore v2
	margins, dydx(voceduc)
	margins, at(voceduc=(0 1))
	
	est restore i2
	margins, dydx(voceduc)
	margins, at(voceduc=(0 1))
	
	
	
	
* Figure 2: Predicted probabilities to enter a new occupation over age

	eststo		m_graph: ///
	mixed	 	occupch i.voceduc##c.age##c.age##c.age##c.age i.higheduc i.female i.migback i.gebjahr /// 
				|| pid: age age_age age_age_age age_age_age_age, var
				
	margins		, at(age=(18(1)65) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities", size(medium)) ///
		xtitle("Age", size(medium)) ///
		ylabel(0.00(0.02)0.12, format(%9.2f) labsize(medium)) ///
		xlabel(15(5)65, labsize(medium)) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.") ring(0) position(6) ///
		size(medium))
	graph		export "$graphs/occupch_quart-age.png", replace width(10000)
	
	// Additional calculations
	est restore	m_graph
	margins, dydx(voceduc) at(age=(18(1)23)) noestimcheck // find when significant early career
	margins, at(age=(25 26 27) voceduc=(0 1)) noestimcheck // find highest probability
	margins, dydx(voceduc) at(age=(41(1)44)) noestimcheck // find when difference becomes insignificant
	
	margins, dydx(voceduc) at(age=(46(1)58)) noestimcheck // find when vocational graduates are more mobile
	margins, at(age=(52) voceduc=(0 1)) noestimcheck
	marigns, dydx(voceduc) at(age=(53))

	
	
* Figure 3: voluntary and involuntary differences
	
	* Panel a) involuntary change
	eststo	invch_graph: ///
	mixed 		invch i.voceduc##c.age##c.age##c.age##c.age i.higheduc i.female ///
				i.migback i.yob || pid: age age_age age_age_age age_age_age_age, var
	est restore	invch_graph
	eststo	invch_margins: ///
	margins		, at(age=(18(1)65) voceduc=(0 1)) noestimcheck post
	est restore invch_margins
	marginsplot, recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(vsmall) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(vsmall) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("b) Involuntary occupational change" ///
		, color(black) margin(medlarge) size(large)) ///
		ytitle("Predicted probabilities", size(medlarge)) ///
		xtitle("Age", size(medlarge)) ///
		ylabel(0(0.01)0.05, format(%9.2f) labsize(medium)) ///
		xlabel(15(5)65, labsize(medium)) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(4 "Vocational educ." 3 "General educ." ) ///
		size(medsmall) ring(0) position(6)) ///
		saving("$graphs/invch_quart-age", replace)
		graph		export "$graphs/invch_quart-age.png", replace width(10000)
		
	// Additional calculations
	est restore	invch_graph
	margins, 	dydx(voceduc) at(age=(20)) noestimcheck // marginal difference at age 20
	margins,	dydx(voceduc) at(age=(18(1)65)) noestimcheck // check when marginal differences are significant
	
	* Panel b) voluntary change
	eststo	volch_graph: ///	
	mixed 		volch i.voceduc##c.age##c.age##c.age##c.age i.higheduc i.female ///
				i.migback i.yob || pid: age age_age age_age_age age_age_age_age, var
	est restore	volch_graph
	eststo volch_margins: ///
	margins		, at(age=(18(1)65) voceduc=(0 1)) noestimcheck post
	est restore volch_margins
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(vsmall) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(vsmall) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("a) Voluntary occupational change" ///
		, color(black) margin(medlarge) size(large)) ///
		ytitle("Predicted probabilities", size(medlarge)) ///
		xtitle("Age", size(medlarge)) ///
		ylabel(0(0.01)0.05, format(%9.2f) labsize(medium)) ///
		xlabel(15(5)65, labsize(medium)) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(4 "Vocational educ." 3 "General educ." ) ///
		size(medsmall) ring(0) position(6)) ///
		saving("$graphs/volch_quart-age", replace)
		graph		export "$graphs/volch_quart-age.png", replace width(10000)
		
	gr combine 	"$graphs/volch_quart-age" "$graphs/invch_quart-age", ///
				row(1) imargin(small) fysize(65)
	graph		export "$graphs/volinv_comb.png", replace width(10000)
	
	// Additional calculations
	est restore	invch_graph
	margins,	dydx(voceduc) at(age=(18(1)65)) noestimcheck // check when marginal differences are significant	

	

/*------------------------------------------------------------------------------
                    #X. Graphs and figures for Appendix
------------------------------------------------------------------------------*/	
	
	
* Figure A1: Histogram for number of observations per case
	hist 		N if pickone==1, bin(36) freq ///
	ytitle("Frequency", size(medlarge)) ylabel(, labsize(medium)) ///
	xtitle("Number of observations per individual case", size(medlarge)) ///
	xlabel(, labsize(medium))
	graph		export "$graphs/numobs_hist.png", replace width(10000)

* Figure A2: Age distribution
	hist 		age, bin(47) freq ///
	ytitle("Frequency / 1000", size(medlarge)) ylabel(, labsize(medium)) ///
	xtitle("Age", size(medlarge)) ///
	ylabel(0 "0" 5000 "5" 10000 "10" 15000 "15", labsize(medium)) ///
	xlabel(20(5)65, labsize(medium))
	graph		export "$graphs/age_hist.png", replace width(10000)

	
* Figure A3: Occupational change over categorical age
	mixed 		occupch i.voceduc##i.age_2yr i.higheduc i.female i.migback i.yob || pid: age_2yr, var
	margins		, at(age_2yr=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities", size(medlarge)) ///
		xtitle("Age", size(medlarge)) ///
		ylabel(0(0.02)0.14, format(%9.2f) labsize(medium)) ///
		xlabel(15(5)65, labsize(medium)) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(4 "Vocational educ." 3 "General educ." ) ///
		size(medium) ring(0) position(6)) ///
		saving("$graphs/occupch_age_2yr", replace)
		graph		export "$graphs/occupch_age_2yr.png", replace width(10000)
	
* Figure A4: Occupational change over age for different cohorts
	mixed		occupch i.voceduc##c.age##c.age##i.cohg i.higheduc i.female i.migback || pid: age age_age, var
	
	// <1950
	margins		, at(age=(45(1)65) voceduc=(0 1) cohg=0) saving(coh0, replace)
	marginsplot, recastci(rarea) recast(line) ///
		plot1opts(lcolor(navy)) ///
		plot2opts(lcolor(cranberry)) ///
		ci1opts(alcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("< 1950" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.12, format(%9.2f) grid) ///
		xlabel(20(5)65, grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/occupch_cohg0", replace)
		graph		export "$graphs/occupch_cohg0.png", replace
		
	// 1950-1959
	margins		, at(age=(35(1)60) voceduc=(0 1) cohg=1) saving(coh1, replace)
	marginsplot, recastci(rarea) recast(line) ///
		plot1opts(lcolor(navy)) ///
		plot2opts(lcolor(cranberry)) ///
		ci1opts(alcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("1950-1959" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.12, format(%9.2f) grid) ///
		xlabel(20(5)65, grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		legend(order(3 "General educ." 4 "Vocational educ")) ///
		saving("$graphs/occupch_cohg1", replace)
		graph		export "$graphs/occupch_cohg1.png", replace
		
	// 1960-1969
	margins		, at(age=(30(1)55) voceduc=(0 1) cohg=2) saving(coh2, replace)
	marginsplot, recastci(rarea) recast(line) ///
		plot1opts(lcolor(navy)) ///
		plot2opts(lcolor(cranberry)) ///
		ci1opts(alcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("1960-1969" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.12, format(%9.2f) grid) ///
		xlabel(20(5)65, grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/occupch_cohg2", replace)
		graph		export "$graphs/occupch_cohg2.png", replace
		
	// 1970-1979
	margins		, at(age=(25(1)45) voceduc=(0 1) cohg=3) saving(coh3, replace)
	marginsplot, recastci(rarea) recast(line) ///
		plot1opts(lcolor(navy)) ///
		plot2opts(lcolor(cranberry)) ///
		ci1opts(alcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("1970-1979" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.12, format(%9.2f) grid) ///
		xlabel(20(6)65, grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		legend(order(3 "General educ." 4 "Vocational educ." )) ///
		saving("$graphs/occupch_cohg3", replace)
		graph		export "$graphs/occupch_cohg3.png", replace

	// > 1979
	margins		, at(age=(18(1)35) voceduc=(0 1) cohg=4) saving(coh4, replace)
	marginsplot, recastci(rarea) recast(line) ///
		plot1opts(lcolor(navy)) ///
		plot2opts(lcolor(cranberry)) ///
		ci1opts(alcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("> 1979" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.12, format(%9.2f) grid) ///
		xlabel(20(5)65, grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/occupch_cohg4", replace)
		graph		export "$graphs/occupch_cohg4.png", replace
	
	
	grc1leg		"$graphs/occupch_cohg4.gph" 	///
				"$graphs/occupch_cohg3.gph"		///
				"$graphs/occupch_cohg2.gph"		///
				"$graphs/occupch_cohg1.gph"		///
				"$graphs/occupch_cohg0.gph",	///
				row(2) imargin(tiny) fysize(100) scheme(s1mono) 
	graph		export "$graphs/occupch_cohgcomb.png", replace width(10000)
	

	
* Figure A5: Secondary and tertiary education

// Occupch	
	mixed occupch i.voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if higheduc==0, var difficult
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.02)0.14, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.") size(medsmall)) ///
		saving("$graphs/occupch_age_secondary", replace)
		graph		export "$graphs/occupch_age_secondary.png", replace	
	
	mixed occupch voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if higheduc==1, var difficult
	margins		, at(age=(18(2)65) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.02)0.14, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.") size(medsmall)) ///
		saving("$graphs/occupch_age_tertiary", replace)
		graph		export "$graphs/occupch_age_tertiary.png", replace		
	
	grc1leg		"$graphs/occupch_age_secondary.gph"	///
				"$graphs/occupch_age_tertiary.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/occupch_higheduc.png", replace width(10000)
	
	
// Voluntary change
	mixed volch voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if higheduc==0, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/volch_age_secondary", replace)
		graph		export "$graphs/volch_age_secondary.png", replace	
	
	mixed volch voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if higheduc==1, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/volch_age_tertiary", replace)
		graph		export "$graphs/volch_age_tertiary.png", replace		
	
	grc1leg		"$graphs/volch_age_secondary.gph"	///
				"$graphs/volch_age_tertiary.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/volch_higheduc.png", replace width(10000)
		
	
	// Involuntary change
	mixed invch voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if higheduc==0, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.02(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/invch_age_secondary", replace)
		graph		export "$graphs/invch_age_secondary.png", replace	
		
	mixed invch voceduc##c.age##c.age##c.age##c.age i.female i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if higheduc==1, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.02(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/invch_age_tertiary", replace)
		graph		export "$graphs/invch_age_tertiary.png", replace		
	
	grc1leg		"$graphs/invch_age_secondary.gph"	///
				"$graphs/invch_age_tertiary.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/invch_higheduc.png", replace width(10000)
	
	
	
	
* Figure A6: Male and female
	
	// Occupational change
	mixed occupch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if female==0, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.14, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/occupch_age_male", replace)
		graph		export "$graphs/occupch_age_male.png", replace	
	
	mixed occupch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if female==1, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(0(0.02)0.14, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/occupch_age_female", replace)
		graph		export "$graphs/occupch_age_female.png", replace		
	
	grc1leg		"$graphs/occupch_age_male.gph"	///
				"$graphs/occupch_age_female.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/occupch_gender.png", replace width(10000)

// Voluntary change
	mixed volch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if female==0, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.06, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/volch_age_male", replace)
		graph		export "$graphs/volch_age_male.png", replace	
		
	mixed volch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob ///
	|| pid: age age_age age_age_age age_age_age_age if female==1, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.06, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/volch_age_female", replace)
		graph		export "$graphs/volch_age_female.png", replace		
	
	grc1leg		"$graphs/volch_age_male.gph"	///
				"$graphs/volch_age_female.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/volch_gender.png", replace width(10000)	
	
	
	// Involuntary change
	mixed invch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if female==0, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/invch_age_male", replace)
		graph		export "$graphs/invch_age_male.png", replace	
		
	mixed invch voceduc##c.age##c.age##c.age##c.age i.higheduc i.migback i.yob /// 
	|| pid: age age_age age_age_age age_age_age_age if female==1, var
	margins		, at(age=(18(2)64) voceduc=(0 1)) noestimcheck
	marginsplot,  recastci(rarea) ///
		plot1opts(lcolor(navy) mcolor(navy) msize(small) msymbol(O)) ///
		plot2opts(lcolor(cranberry) mcolor(cranberry) msize(small) msymbol(O)) ///
		ci1opts(lcolor(navy%60) fcolor(navy%20)) ///
		ci2opts(lcolor(cranberry%60) fcolor(cranberry%20)) ///
		title("" ///
		, color(black) margin(medium) size(medium)) ///
		ytitle("Predicted probabilities") ///
		xtitle("Age") ///
		ylabel(-0.01(0.01)0.05, format(%9.2f) ) ///
		xlabel(15(5)65, ) ///
		graphregion(color(white)) plotregion(color(white) margin(small)) ///
		legend(order(3 "General educ." 4 "Vocational educ.")) ///
		saving("$graphs/invch_age_female", replace)
		graph		export "$graphs/invch_age_female.png", replace		
	
	grc1leg		"$graphs/invch_age_male.gph"	///
				"$graphs/invch_age_female.gph" 	///
				, row(1) imargin(tiny) fysize(70) scheme(s1mono) 
	graph		export "$graphs/invch_gender.png", replace width(10000)
	

		
	
	
* Table A1: Analytic sample restrictions and associated change in case numbers
	// made in Excel
	
* Table A2: Comparing original sample and analytic sample
	// Stats on analytic sample are copied from descriptive table
	// Original sample
	use "$posted/compdata.dta", clear
	
	* Update person ID
	sort		pid syear
	egen 		pickone=tag(pid)
	lab var		pickone "Tag first observation"
	
	capture 	drop pid
	gen 		pid=sum(pickone)
	lab var		pid "Personal ID"
	
	* Occupational change
	tab occupch
	sum occupch
	
	* Vocational education
	tab voceduc if pickone==1
	sum voceduc if pickone==1
	
	*Educational level
	tab higheduc if pickone==1
	sum higheduc if pickone==1
	
	*Voluntary occup. change
	tab volch
	sum volch
	
	*Involuntary occup. change
	tab invch
	sum invch
	
	* Age
	sum age
	
	* Gender
	tab female if pickone==1
	sum female if pickone==1
	
	* Migration background
	tab migback if pickone==1
	sum migback if pickone==1	
	
	* Year of birth
	sum gebjahr if pickone==1
	
	* Cohorts groups
	tab cohg if pickone==1	

	
* Table A3 Multilevel linear probability models predicting occupational change
	// see above under Table 2
	
* Table A4: Multilevel linear probability models predicting voluntary occupational change
	eststo		v1: ///
	mixed 		volch i.voceduc || pid:, var	
	
	eststo		v2: ///
	mixed 		volch i.voceduc i.higheduc i.female i.migback i.yob /// 
				|| pid:, var
				
	eststo		v3: ///
	mixed 		volch i.voceduc##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10, var
				
	eststo		v4: ///
	mixed 		volch i.voceduc##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10, var
				
	eststo		v5: ///
	mixed 		volch i.voceduc##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10, var
	
	eststo		v6: ///
	mixed	 	volch i.voceduc##c.agec10##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10 agec10_agec10_agec10_agec10, var
				
								
	esttab		v1 v2 v3 v4 v5 v6 ///
				using "$tables/volch-full.rtf", replace 						///
					b(%9.3f) se(%9.3f) aic(%9.0f) bic(%9.0f) 				///
					noomit nobase star nonum nodepvars nogaps label			///
					interaction("*") 										///
					sfmt(%9.4g) 											///
					transform(ln*: exp(@)^2 exp(@)^2)						///
					drop(*.yob)												///
					mtitles("M1" "M2" "M3" "M4" "M5" "M6") 					///
					coeflabels(												///		
					_cons "Intercept" 										///
					1.voceduc "Vocational educ."							///	
					1.higheduc "Tertiary educ."								///
					1.female "Female"										///
					1.migback "Migration backgr." 							///	
					agec10 "Age/10" 								///	
					c.agec10#c.agec10 "Age2/10"								///
					c.agec10#c.agec10#c.agec10 "Age3/10"						///
					c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10"				///
					1.voceduc#c.agec10 "Age/10 * Voc. educ."						///
					1.voceduc#c.agec10#c.agec10 "Age2/10 * Voc. educ."					///
					1.voceduc#c.agec10#c.agec10#c.agec10 "Age3/10 * Voc. educ."				///
					1.voceduc#c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10 * Voc. educ.")	///
					eqlabels("" "Intercept variance" "Residual variance" "Slope variance: Age" ///
					"Slope variance: Age2" "Slope variance: Age3" "Slope variance: Age4", none)

					
* Table A4: Multilevel linear probability models predicting involuntary occupational change									
	eststo		i1: ///
	mixed 		invch i.voceduc || pid:, var	
	
	eststo		i2: ///
	mixed 		invch i.voceduc i.higheduc i.female i.migback i.yob /// 
				|| pid:, var
				
	eststo		i3: ///
	mixed 		invch i.voceduc##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10, var
				
	eststo		i4: ///
	mixed 		invch i.voceduc##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10, var
				
	eststo		i5: ///
	mixed 		invch i.voceduc##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10, var
	
	eststo		i6: ///
	mixed	 	invch i.voceduc##c.agec10##c.agec10##c.agec10##c.agec10 i.higheduc i.female i.migback i.yob /// 
				|| pid: agec10 agec10_agec10 agec10_agec10_agec10 agec10_agec10_agec10_agec10, var
	
	esttab		i1 i2 i3 i4 i5 i6 ///
				using "$tables/invch-full.rtf", replace 						///
					b(%9.3f) se(%9.3f) aic(%9.0f) bic(%9.0f) 				///
					noomit nobase star nonum nodepvars nogaps label			///
					interaction("*") 										///
					sfmt(%9.4g) 											///
					transform(ln*: exp(@)^2 exp(@)^2)						///
					drop(*.yob)												///
					mtitles("M1" "M2" "M3" "M4" "M5" "M6") 					///
					coeflabels(												///		
					_cons "Intercept" 										///
					1.voceduc "Vocational educ."							///	
					1.higheduc "Tertiary educ."								///
					1.female "Female"										///
					1.migback "Migration backgr." 							///	
					agec10 "Age/10" 								///	
					c.agec10#c.agec10 "Age2/10"								///
					c.agec10#c.agec10#c.agec10 "Age3/10"						///
					c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10"				///
					1.voceduc#c.agec10 "Age/10 * Voc. educ."						///
					1.voceduc#c.agec10#c.agec10 "Age2/10 * Voc. educ."					///
					1.voceduc#c.agec10#c.agec10#c.agec10 "Age3/10 * Voc. educ."				///
					1.voceduc#c.agec10#c.agec10#c.agec10#c.agec10 "Age4/10 * Voc. educ.")	///
					eqlabels("" "Intercept variance" "Residual variance" "Slope variance: Age" ///
					"Slope variance: Age2" "Slope variance: Age3" "Slope variance: Age4", none)
	
	
	
