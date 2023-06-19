 

/*------------------------------------------------------------------------------
                     #1. Configuring your dofile
------------------------------------------------------------------------------*/

* Setup
	version		16.0            // Stata version control (put your own version)
	clear		all             // clear working memory
	macro		drop _all       // clear macros
	set 		seed 339487731	// set seed

* Load requicranberry packages
	* ssc		install carryforward, replace
	* ssc 		install fillmissing, replace
	* ssc		install iscogen, replace
	
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
                     #2. Prepare data
------------------------------------------------------------------------------*/


* Load data file
	use			"$posted/masterfile.dta", clear

* Sort cases
	sort pid syear
	
* Define panel structure
	xtset pid syear
	
* Create observation indexers 
	// n: counts up within individuals, N: total nr of observations per individual
	bysort 		pid (syear): gen N = _N
	bysort 		pid (syear): gen n = _n

	
* Create a variable that identifies employer change from plb0284_h (Code 3)
	// plb0284_h has only been recorded from 1994 onwards
	gen 		empch=0
	replace 	empch=1 if plb0284_h==3
	lab var 	empch "Employer change (0/1)"

	
* Transform ISCO88 into ISCO08

	// Recode negative values to missings
	gen			isco88=pgisco88
	replace		isco88=. if pgisco88<0
	tab1		isco88, m
	
	// Transform using iscogen
	iscogen 	isco08_4 = isco08(isco88), from(isco88) invalid 
	
	// 1 invalid code: 7139. I recode that into 7120: Building Finishers and Related Trades Workers on isco08
	replace		isco08_4=7120 if pgisco88==7139
	
	
* Combine with existing ISCO08 codes
	replace		isco08_4=pgisco08 if pgisco08>0
	tab			isco08_4, nol
	
* Generate 1- 2- 3-digit isco08 codes
	iscogen 	isco08_3 = minor(isco08_4), from(isco08) invalid 
	iscogen 	isco08_2 = submajor(isco08_4), from(isco08) invalid 
	iscogen 	isco08_1 = major(isco08_4), from(isco08) invalid 
	
	// There are some codes on 4-digit and 3-digit level which are not part of the official classification e.g. 1200. Should not be an issue as long as we are just interested in change
	
* We use 3-digit codes as main variables
	gen occup=isco08_3
	tab occup, m
	
	
	// Create variable that is 1 if occup changes compared to prior year or to year last observed employed
	// With this code we account for possible distance between jobs to 20 years. There are no cases in the data set for 19 or 20 year distance so we stop there assuming that there are no cases with 21 years distance or more
	// If individuals enter the sample in unemployment but enter an occupation afterwards, this is not recorded as occupational change (as we don't know what they did before)
	xtset		pid syear
	capture		drop occupch
	gen 		occupch=0
replace	occupch=1 if	occup!=l1.occup	& occup!=. & n!=1	& l1.occup!=.																			
replace	occupch=1 if	occup!=l2.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup!=.																		
replace	occupch=1 if	occup!=l3.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup!=.																	
replace	occupch=1 if	occup!=l4.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup!=.																
replace	occupch=1 if	occup!=l5.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup!=.															
replace	occupch=1 if	occup!=l6.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup!=.														
replace	occupch=1 if	occup!=l7.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup!=.													
replace	occupch=1 if	occup!=l8.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup!=.												
replace	occupch=1 if	occup!=l9.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup!=.											
replace	occupch=1 if	occup!=l10.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup!=.										
replace	occupch=1 if	occup!=l11.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup!=.									
replace	occupch=1 if	occup!=l12.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup!=.								
replace	occupch=1 if	occup!=l13.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup!=.							
replace	occupch=1 if	occup!=l14.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup!=.						
replace	occupch=1 if	occup!=l15.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup!=.					
replace	occupch=1 if	occup!=l16.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup==.	& l16.occup!=.				
replace	occupch=1 if	occup!=l17.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup==.	& l16.occup==.	& l17.occup!=.			
replace	occupch=1 if	occup!=l18.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup==.	& l16.occup==.	& l17.occup==.	& l18.occup!=.		
replace	occupch=1 if	occup!=l19.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup==.	& l16.occup==.	& l17.occup==.	& l18.occup!=.	& l19.occup!=.	
replace	occupch=1 if	occup!=l20.occup	& occup!=. & n!=1	& l1.occup==.	& l2.occup==.	& l3.occup==.	& l4.occup==.	& l5.occup==.	& l6.occup==.	& l7.occup==.	& l8.occup==.	& l9.occup==.	& l10.occup==.	& l11.occup==.	& l12.occup==.	& l13.occup==.	& l14.occup==.	& l15.occup==.	& l16.occup==.	& l17.occup==.	& l18.occup!=.	& l19.occup!=.	& l20.occup!=.
	
	// To be sure that we are not measureing noise on the isco variables we restrict occupch to observations were individuals explicitly reported job change (pgjobch==4)
	rename occupch occupch_wn // with noise
	gen occupch=occupch_wn
	recode occupch (1=0) if pgjobch!=4
	
	lab var 	occupch "Occup. change"
	lab var		occupch_wn "Occup. change with noise"
	
* Construct variable that records occupational exit (exiting a job conditional on entering another occupation later)
	// Works similar to the command above
	capture 	drop occupex
	gen 		occupex=0
replace 	occupex=1 if	occup!=l1.occup &	pgjobch==4 &	l1.occup!=. &	occup!=.																						
replace 	occupex=1 if	l1.occup!=f1.occup &	f1.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup!=.																					
replace 	occupex=1 if	l1.occup!=f2.occup &	f2.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup!=.																				
replace 	occupex=1 if	l1.occup!=f3.occup &	f3.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup!=.																			
replace 	occupex=1 if	l1.occup!=f4.occup &	f4.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup!=.																		
replace 	occupex=1 if	l1.occup!=f5.occup &	f5.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup!=.																	
replace 	occupex=1 if	l1.occup!=f6.occup &	f6.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup!=.																
replace 	occupex=1 if	l1.occup!=f7.occup &	f7.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup!=.															
replace 	occupex=1 if	l1.occup!=f8.occup &	f8.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup!=.														
replace 	occupex=1 if	l1.occup!=f9.occup &	f9.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup!=.													
replace 	occupex=1 if	l1.occup!=f10.occup &	f10.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup!=.												
replace 	occupex=1 if	l1.occup!=f11.occup &	f11.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup!=.											
replace 	occupex=1 if	l1.occup!=f12.occup &	f12.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup!=.										
replace 	occupex=1 if	l1.occup!=f13.occup &	f13.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup!=.									
replace 	occupex=1 if	l1.occup!=f14.occup &	f14.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup!=.								
replace 	occupex=1 if	l1.occup!=f15.occup &	f15.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup!=.							
replace 	occupex=1 if	l1.occup!=f16.occup &	f16.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup!=.						
replace 	occupex=1 if	l1.occup!=f17.occup &	f17.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup!=.					
replace 	occupex=1 if	l1.occup!=f18.occup &	f18.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup==. &	f18.occup!=.				
replace 	occupex=1 if	l1.occup!=f19.occup &	f19.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup==. &	f18.occup==. &	f19.occup!=.			
replace 	occupex=1 if	l1.occup!=f20.occup &	f20.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup==. &	f18.occup==. &	f19.occup==. &	f20.occup!=.		
replace 	occupex=1 if	l1.occup!=f21.occup &	f21.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup==. &	f18.occup==. &	f19.occup==. &	f20.occup==. &	f21.occup!=.	
replace 	occupex=1 if	l1.occup!=f22.occup &	f22.pgjobch==4 &	l1.occup!=. &	occup==. &	f1.occup==. &	f2.occup==. &	f3.occup==. &	f4.occup==. &	f5.occup==. &	f6.occup==. &	f7.occup==. &	f8.occup==. &	f9.occup==. &	f10.occup==. &	f11.occup==. &	f12.occup==. &	f13.occup==. &	f14.occup==. &	f15.occup==. &	f16.occup==. &	f17.occup==. &	f18.occup==. &	f19.occup==. &	f20.occup==. &	f21.occup==. &	f22.occup!=.


* Add reason for job exit from plb0304_h
	
	// involuntary
	gen 		invex=0
	replace 	invex=1 if occupex==1 & inlist(plb0304_h,1,3,5,11) // involuntary
	replace		invex=. if occupex!=1
	lab var 	invex "Involuntary occup. exit"
	tab			invex, m
	
	// voluntary
	gen			volex=0
	replace		volex=1 if occupex==1 & inlist(plb0304_h,2,4,8,10)
	replace		volex=. if occupex!=1
	lab var 	volex "Voluntary occup. exit"
	tab			volex, m
	

* Construct variable that ascribes reason for prior job exit to the respective transition
	
	// Create variable and place a blocker so that carryforward does not fill in values where no new job termination has been recorded
	gen 		whypriorexit=.
	replace		whypriorexit=99 if l2.occupch==1
	
	// We categorize plb0304_h into: -1 no info, 0 other, 1 voluntary, 2 involuntary
	replace		whypriorexit=0 if inlist(plb0304_h,6,7,9,12,13,14,15)
	replace		whypriorexit=1 if inlist(plb0304_h,2,4,8,10)
	replace		whypriorexit=2 if inlist(plb0304_h,1,3,5,11)
	
	lab var 	whypriorexit "Reason for job exit (year when it happend)"
	lab de		whypriorexitl 0 "other / unkown" 1 "voluntary" 2 "involuntary"
	lab val		whypriorexit whypriorexitl
	tab			whypriorexit, m
	
	// Create dummies
	gen			volquit=0
	replace		volquit=1 if whypriorexit==1
	
	gen			invquit=0
	replace		invquit=1 if whypriorexit==2
	
	
	// Move reason of jobexit into year of reemployment
	// Use carryforward to fill in the gaps (package needs to be installed)
	sort		pid syear
	bysort 		pid (syear): carryforward whypriorexit, gen(whypriorexit_cf)
	tab			whypriorexit_cf, m
	
	// Link reasons for exit to job entering
	gen			whyexit=.
	replace		whyexit=0 if empch==1 & whypriorexit_cf==.
	replace		whyexit=0 if empch==1 & whypriorexit_cf==99
	replace		whyexit=0 if empch==1 & whypriorexit_cf==0
	replace		whyexit=1 if empch==1 & whypriorexit_cf==1
	replace		whyexit=2 if empch==1 & whypriorexit_cf==2
	
	replace		whyexit=0 if occupch==1 & whypriorexit_cf==.
	replace		whyexit=0 if occupch==1 & whypriorexit_cf==99
	replace		whyexit=0 if occupch==1 & whypriorexit_cf==0
	replace		whyexit=1 if occupch==1 & whypriorexit_cf==1
	replace		whyexit=2 if occupch==1 & whypriorexit_cf==2
	
	lab var 	whyexit "Reason for job exit (year when reemployed)"
	lab val		whyexit whypriorexitl
	tab			whyexit, m

	// Create dummies
	gen volch=0
	replace volch=1 if occupch==1 & whyexit==1

	gen invch=0
	replace invch=1 if occupch==1 & whyexit==2
	
		
* Construct variable that indicates prior occupation in the year of mobility
	gen 		proccup=.
	replace		proccup=l1.occup if occupex==1
	bysort 		pid (syear): carryforward proccup, replace
	
	// People who worked in the same occupation over all observations have missings
	egen 		stayer = total(occupex) , by(pid) // counting occupational exits
	replace		proccup=occup if stayer==0
	bysort 		pid (syear): carryforward proccup, replace
	drop		stayer
	
	// People where prior job is unkown have missings
	// We carry observations backwards to fill missings
	gen 		int negyear = -syear
	bysort		pid (negyear): carryforward proccup, replace
	
	// Prior occupation 2-digit
	rename		proccup proccup3
	tostring 	proccup3, gen(proccup3_str)
	gen 		proccup2_str = substr(proccup3_str,1,2)
	gen 		proccup1_str = substr(proccup3_str,1,1)
	destring	proccup2_str, gen(proccup2)
	destring	proccup1_str, gen(proccup1)
	drop 		proccup1_str proccup2_str proccup3_str

* Construct variable that =1 when someone previously worked in routine task intensive occupation
	gen			rti=0
	replace		rti=1 if inlist(proccup2,41,42,81,82)
	
/*

* Construct variable that counts years between occupational exit and entrance
	// For about 3.8 percent of the occupational transitions we can not record transition length because individuals are unobserved for one or more years in between exiting and entering so we can't determine the exact transition length

capture drop trleng
gen trleng=.
replace trleng=0 if	occupch==1 & 	occupex==1 																				
replace trleng=1 if	occupch==1 & 	l1.occupex==1 &	l1.occup==.																			
replace trleng=2 if	occupch==1 & 	l2.occupex==1 &	l1.occup==. &	l2.occup==.																		
replace trleng=3 if	occupch==1 & 	l3.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==.																	
replace trleng=4 if	occupch==1 & 	l4.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==.																
replace trleng=5 if	occupch==1 & 	l5.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==.															
replace trleng=6 if	occupch==1 & 	l6.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==.														
replace trleng=7 if	occupch==1 & 	l7.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==.													
replace trleng=8 if	occupch==1 & 	l8.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==.												
replace trleng=9 if	occupch==1 & 	l9.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==.											
replace trleng=10 if	occupch==1 & 	l10.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==.										
replace trleng=11 if	occupch==1 & 	l11.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==.									
replace trleng=12 if	occupch==1 & 	l12.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==.								
replace trleng=13 if	occupch==1 & 	l13.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==.							
replace trleng=14 if	occupch==1 & 	l14.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==.						
replace trleng=15 if	occupch==1 & 	l15.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==.					
replace trleng=16 if	occupch==1 & 	l16.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==.				
replace trleng=17 if	occupch==1 & 	l17.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==.			
replace trleng=18 if	occupch==1 & 	l18.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup==.		
replace trleng=19 if	occupch==1 & 	l19.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup==. &	l19.occup==.	
replace trleng=20 if	occupch==1 & 	l20.occupex==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup==. &	l19.occup==. &	l20.occup==.	

*/

* Construct variable to track wage mobility
	sort 		pid syear
	xtset		pid syear
	gen			originalwage=pglabgro
	replace		originalwage=. if pglabgro<=0
	
	* Exclude top and bottom 0.5 percent of the wage distribution
	// centile(originalwage), centile(0.5, 99.5)
	// replace		originalwage=. if !inrange(originalwage,r(c_1), r(c_2))
	gen 		wage=originalwage
	
	* Naturally log wage 
	// gen			wage=ln(originalwage) // take natural logarithm to enable percent interpretations
	
	
capture drop wagech
gen wagech=wage-	l1.wage if	occupch==1 &	l1.occup!=.																			
replace wagech=wage-	l2.wage if	occupch==1 &	l1.occup==. &	l2.occup!=.																		
replace wagech=wage-	l3.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup!=.																	
replace wagech=wage-	l4.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup!=.																
replace wagech=wage-	l5.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup!=.															
replace wagech=wage-	l6.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup!=.														
replace wagech=wage-	l7.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup!=.													
replace wagech=wage-	l8.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup!=.												
replace wagech=wage-	l9.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup!=.											
replace wagech=wage-	l10.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup!=.										
replace wagech=wage-	l11.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup!=.									
replace wagech=wage-	l12.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup!=.								
replace wagech=wage-	l13.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup!=.							
replace wagech=wage-	l14.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup!=.						
replace wagech=wage-	l15.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup!=.					
replace wagech=wage-	l16.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup!=.				
replace wagech=wage-	l17.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup!=.			
replace wagech=wage-	l18.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup!=.		
replace wagech=wage-	l19.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup==. &	l19.occup!=.	
replace wagech=wage-	l20.wage if	occupch==1 &	l1.occup==. &	l2.occup==. &	l3.occup==. &	l4.occup==. &	l5.occup==. &	l6.occup==. &	l7.occup==. &	l8.occup==. &	l9.occup==. &	l10.occup==. &	l11.occup==. &	l12.occup==. &	l13.occup==. &	l14.occup==. &	l15.occup==. &	l16.occup==. &	l17.occup==. &	l18.occup==. &	l19.occup==. &	l20.occup!=.	
	
	lab var		wage "Wage"
	lab var		wagech "Wage change"

* Construct education variable that distinguishes vocational (0) and general education (1)
	gen 		voceduc_tv=.
	replace		voceduc_tv=0 if inrange(pgpsbil,1,5) // Secondary school-leaving qualification
	replace		voceduc_tv=1 if inrange(pgpbbil01,1,6) // Ausbildungen
	replace		voceduc_tv=1 if inlist(pgpbbil02,1,4) // FH, FH (Ost)
	replace		voceduc_tv=0 if inlist(pgpbbil02,2,5,6,7) //Uni, Uni (Ost), Promotion, Promotion (Ausland)
	tab 		voceduc_tv, m
	
	* Make it time constant
	
	// Generate age
	recode		gebjahr (-1=.) // those cases will be dropped later
	gen 		age=syear-gebjahr
	lab var 	age "Age"
	tab 		age, m // current age range is 14 to 105
	
	// Redo observation indexer
	capture		drop n
	bysort 		pid (syear): gen n = _n
	
	// Create variable for cases observed at age 25
	gen			aux=.
	replace		aux=0 if age==25 & voceduc_tv==0
	replace		aux=1 if age==25 & voceduc_tv==1
	bysort 		pid: egen voceduc = max(aux) // turn into time-constant
	drop 		aux
	
	// Create another variable for cases who entered the sample after 25
	gen			aux=.
	replace		aux=0 if n==1 & age>25 & voceduc_tv==0
	replace		aux=1 if n==1 & age>25 & voceduc_tv==1
	bysort 		pid: egen voceduc2 = max(aux) // turn into time-constant
	drop 		aux
	
	// Create a third variable for cases who left the sample before 25
	bysort 		pid (negyear): gen negn = _n // create a revers observation indexer
	gen			aux=.
	replace		aux=0 if age<25 & negn==1 & voceduc_tv==0
	replace		aux=1 if age<25 & negn==1 & voceduc_tv==1
	bysort 		pid: egen voceduc3 = max(aux) // turn into time-constant
	drop 		aux
	sort		pid syear
	
	// Put the three variables together
	replace		voceduc=0 if voceduc==. & voceduc2==0
	replace		voceduc=1 if voceduc==. & voceduc2==1
	replace		voceduc=0 if voceduc==. & voceduc3==0
	replace		voceduc=1 if voceduc==. & voceduc3==1
	drop 		voceduc2 voceduc3
	tab			voceduc, m
	tab 		voceduc voceduc_tv, m
	
	lab 		var voceduc "Vocational educ."
	label		define voceducl 0 "General educ." 1 "Vocational educ."
	label		values voceduc voceducl
	
	
* Create a variable that distinguishes secondary and tertiary education
	gen 		higheduc_tv=.	
	replace		higheduc_tv=0 if inrange(pgpsbil,1,5) //  low gen
	replace		higheduc_tv=0 if inrange(pgpbbil01,1,6) // low voc
	replace		higheduc_tv=1 if inlist(pgpbbil02,1,4) // high voc
	replace		higheduc_tv=1 if inlist(pgpbbil02,2,5,6,7) // high gen
	tab 		higheduc_tv, m
	
	// Make it time-constant
	
	// Create variable for cases observed at age 25
	gen			aux=.
	replace		aux=0 if age==25 & higheduc_tv==0
	replace		aux=1 if age==25 & higheduc_tv==1
	bysort 		pid: egen higheduc = max(aux) // turn into time-constant
	drop 		aux
	
	// Create another variable for cases who enter the sample after 25
	gen			aux=.
	replace		aux=0 if n==1 & age>25 & higheduc_tv==0
	replace		aux=1 if n==1 & age>25 & higheduc_tv==1
	bysort 		pid: egen higheduc2 = max(aux) // turn into time-constant
	drop 		aux
	
	// Create a third variable for cases who left the sample before 25
	gen			aux=.
	replace		aux=0 if age<25 & negn==1 & higheduc_tv==0
	replace		aux=1 if age<25 & negn==1 & higheduc_tv==1
	bysort 		pid: egen higheduc3 = max(aux) // turn into time-constant
	drop 		aux
	
	// Put the three variables together
	replace		higheduc=0 if higheduc==. & higheduc2==0
	replace		higheduc=1 if higheduc==. & higheduc2==1
	replace		higheduc=0 if higheduc==. & higheduc3==0
	replace		higheduc=1 if higheduc==. & higheduc3==1
	drop 		higheduc2 higheduc3
	tab			higheduc, m
	tab 		higheduc higheduc_tv, m
	
	lab 		var higheduc "Tertiary educ."
	label		define higheducl 0 "Secondary education" 1 "Tertiary education"
	label		values higheduc higheducl
	
	// check voceduc and higheduc
	tab 		voceduc higheduc, m
	
* Create variable with 4 educatinal categories
	gen 		educ4=.
	replace		educ4=0 if voceduc==1 & higheduc==0
	replace		educ4=1 if voceduc==1 & higheduc==1
	replace		educ4=2 if voceduc==0 & higheduc==0
	replace		educ4=3 if voceduc==0 & higheduc==1
	
	lab var 	educ4 "Voc-Gen / High-Low educ."
	lab def 	educ4l 0 "Voc-Low" 1 "Voc-High" 2 "Gen-Low" 3 "Gen-High"
	lab val		educ4 educ4l
	
	tab 		educ4, m
	

/*	
* Generate 1-digit NACE codes (industies)
	rename 		pgnace pgnace2digit
	gen 		pgnace=. if pgnace2digit<0							// Missings
	replace 	pgnace=1 if pgnace2digit<10 & pgnace2digit>0		// A
	replace		pgnace=2 if pgnace2digit<=14 & pgnace2digit>=10		// B
	replace		pgnace=3 if pgnace2digit<=39 & pgnace2digit>=15		// C
	replace		pgnace=4 if pgnace2digit==40						// D
	replace		pgnace=5 if pgnace2digit<=44 & pgnace2digit>=41		// E
	replace		pgnace=5 if pgnace2digit==90						// E
	replace		pgnace=6 if	pgnace2digit==45						// F
	replace		pgnace=7 if	pgnace2digit<=54 & pgnace2digit>=50		// G
	replace		pgnace=8 if	pgnace2digit<=63 & pgnace2digit>=60		// H
	replace		pgnace=9 if	pgnace2digit==55						// I
	replace		pgnace=10 if	pgnace2digit==64 | pgnace2digit==72	// J
	replace		pgnace=11 if	pgnace2digit<=69 & pgnace2digit>=65 // K
	replace		pgnace=12 if	pgnace2digit==70					// L
	replace		pgnace=13 if	pgnace2digit==73					// M
	replace		pgnace=14 if	pgnace2digit==71 | pgnace2digit==74 // N
	replace		pgnace=15 if	pgnace2digit==75					// O
	replace		pgnace=16 if	pgnace2digit==80					// P
	replace		pgnace=17 if	pgnace2digit==85					// Q
	replace		pgnace=18 if	pgnace2digit==92					// R
	replace		pgnace=19 if	pgnace2digit==91 | pgnace2digit==93	// S
	replace		pgnace=20 if	pgnace2digit==95					// T
	replace		pgnace=21 if	pgnace2digit==99					// U
	
	lab var 	pgnace "Industry (1/21)"
	tab			pgnace2digit pgnace, m
	
	// Generate industry control variable where missings are 0
	gen			pgnace_con=pgnace
	recode		pgnace_con (.=0)		
*/	
	
	

* Create birth cohort group variable
	tab 		gebjahr
	gen 		cohg=0 if gebjahr<=1949
	replace		cohg=1 if gebjahr>=1950 & gebjahr<=1959
	replace		cohg=2 if gebjahr>=1960 & gebjahr<=1969
	replace		cohg=3 if gebjahr>=1970 & gebjahr<=1979
	replace		cohg=4 if gebjahr>=1980 & gebjahr!=.
	tab 		cohg, m
	
	label 		var cohg "Cohort groups"
	label 		define cohgl 0 "<1950" 1 "1950-59" 2 "1960-69" 3 "1970-79" 4 ">1980"
	label		val cohg cohgl
	
	gen 		cohg_3=0 if gebjahr<1955
	replace		cohg_3=1 if gebjahr>=1955 & gebjahr<1975
	replace		cohg_3=2 if gebjahr>=1975
	
	lab de		cohg_3_l 0 "< 1955" 1 "1955 - 1974" 2 "< 1975"
	lab val		cohg_3 cohg_3_l
	tab 		cohg_3, m
	
* Rescale gebjahr so that 1920 is 0
	gen 		yob=gebjahr-1920
	tab 		yob
	
	lab 		var yob "Year of birth"
	tab 		yob
	
* Create 2-year age groups
	capture		drop age_2yr
	egen		age_2yr = cut(age), at(18(2)66)
	tab			age age_2yr
	

	
* More variables for the analysis

	// geneduc
	gen			geneduc=1-voceduc
	tab			geneduc voceduc, m

	// within-occupational mobility
	gen			withoccupch=0
	replace 	withoccupch=1 if empch==1 & occupch==0
	lab var 	withoccupch "Within-occupational change (0/1)"
	
	// gender / female
	recode		sex (-3=.) (1=0) (2=1), gen(female)
	lab var 	female "Female"
	lab de 		femalel 0 "Male" 1 "Female"
	lab val 	female femalel
	
	// employment (Vollzeit und Teilzeit - code 1 und 2 auf pgempelst)
	gen 		emp=0
	replace		emp=1 if inlist(pgemplst,1,2)
	tab1		emp, m
	
	// unemployment (code 5 on pgemplst)
	gen			unemp=1 if pgemplst==5
	replace		unemp=0 if unemp!=1
	tab1		unemp, m
	
	// prob. for negative wage mobility
	gen			negwagech=0
	replace		negwagech=1 if wagech<0
	replace		negwagech=. if wagech==.
	lab var		negwagech "Neg. wage change"
	tab			negwagech
	
	// Year of birth
	lab var		gebjahr "Year of birth"
	
	// Migration background
	rename migback migback_original
	gen migback=.
	replace migback=0 if migback_original==1
	replace migback=1 if migback_original==2
	replace migback=1 if migback_original==3
	lab var migback "Migration backgr."
	lab define migbackl 0 "No MGB" 1 "Migration backgr."
	lab val migback migbackl
	tab migback migback_original, m
	
	
* Save data file to make comparison between original and analytic sample	
	save 		"$posted/compdata.dta", replace

	
**** Creating analytic sample

* Drop cases with only missing values on occupation
	capture		drop N
	bysort 		pid (syear): gen N = _N // redo observation counter
	egen 		totmiss = total(missing(occup)), by(pid)
	drop		if totmiss == N
	drop		totmiss
	
* Drop cases without secondary school-leaving qualification
	drop		if voceduc==.
	tab			voceduc, m	

* Drop first observation of every case as we cannot observe occupational change there
	capture		drop n
	bysort 		pid (syear): gen n = _n // redo observation indexer
	drop 		if n==1 // this also drops cases with just one observation

* Drop observations outside the age range
	drop		if age<18
	drop		if age>65
	tab 		age
	
* Drop observations that are still in education besides they are recorded as employed
	drop		if inlist(pgstib,11,110,120,130) & occup==.
	
* Drop observations in retirement besides they are recorded as employed
	drop		if pgstib==13 & occup==.
	

* Drop obs with missings on age and female
	drop if		female==.
	
/*	
* Drop obs with missings on occupation at the beginning of each individual case
	by 			pid (syear), sort: drop if _n == sum(mi(occup))
	// this also drop all observations with only missings
*/	
	



* Update observation indexers 
	// n: counts up within individuals, N: total nr of observations per individual
	drop		n N
	bysort 		pid (syear): gen N = _N
	bysort 		pid (syear): gen n = _n

* Update person ID
	
	// new persion ID
	sort		pid syear
	egen 		pickone=tag(pid)
	lab var		pickone "Tag first observation"
	
	capture 	drop pid
	gen 		pid=sum(pickone)
	lab var		pid "Personal ID"
	
* Generate mean-centered variables

	// age
	sum 		age, meanonly
	gen 		agec = age - r(mean)
	gen			agec10 = agec / 10
	lab var 	agec "Age (mean-centered)"
	lab var 	agec "Age/10"
	
	// age polynomials
	gen age_age=age*age
	gen age_age_age=age*age*age
	gen age_age_age_age=age*age*age*age
	
	gen agec10_agec10=agec10*agec10
	gen agec10_agec10_agec10=agec10*agec10*agec10
	gen agec10_agec10_agec10_agec10=agec10*agec10*agec10*agec10

	// year of birth
	sum			gebjahr, meanonly
	gen			yobc=gebjahr-r(mean)
	
	
	
	
	
* Variable graveyard 

	/*	
		// Prepare SIOPS as measure of occupational status
	// Problem here is that iscogen cannot translate siops08 and siops88. For now I just merge them together which may be problematic
	gen 		siops=pgsiops88
	replace		siops=. if siops<0
	replace		siops=pgsiops08 if siops==. & pgsiops08>0 // 27,022 changes
	replace		siops=. if occup==.
	
	// Being upwardly mobile
	sort 		pid syear	// sort cases
	xtset		pid syear	// define panel structure	
	gen 		upmob=0
	replace		upmob=1 if occupch==1 & siops>l1.siops // does not record if someone changed jobs with unemployment in between
	replace		upmob=1 if occupch==1 & l1.siops==. & siops>l2.siops // 1 year of unemployment
	replace		upmob=1 if occupch==1 & l1.siops==. & l2.siops==. & siops>l3.siops // 2 years of unemployment
	replace		upmob=1 if occupch==1 & l1.siops==. & l2.siops==. & l3.siops==. & siops>l4.siops // 3 years of unemployment
	
	// Being downwardly mobile
	gen			downmob=0
	replace		downmob=1 if occupch==1 & l1.siops!=. & siops<l1.siops // does not record if someone changed jobs with unemployment in between
	replace		downmob=1 if occupch==1 & l1.siops==. & l2.siops!=. & siops<l2.siops // 1 year of unemployment
	replace		downmob=1 if occupch==1 & l1.siops==. & l2.siops==. & l3.siops!=. & siops<l3.siops // 2 years of unemployment
	replace		downmob=1 if occupch==1 & l1.siops==. & l2.siops==. & l3.siops==. & l4.siops!=.  & siops<l4.siops // 3 years of unemployment
	tab			upmob downmob, m
	
	// Being laterally mobile
	gen			latmob=0
	replace		latmob=1 if occupch==1 & siops==l1.siops 
	replace		latmob=1 if occupch==1 & l1.siops==. & siops==l2.siops
	replace		latmob=1 if occupch==1 & l1.siops==. & l2.siops==. & siops==l3.siops
	replace		latmob=1 if occupch==1 & l1.siops==. & l2.siops==. & l3.siops==. & siops==l4.siops
	tab			latmob upmob, m
	tab			latmob downmob, m
	
	// Create dummy variable: 1 = upward, 0 = downward or lateral
	gen 		socmob=.
	replace 	socmob=1 if upmob==1
	replace		socmob=0 if latmob==1
	replace		socmob=0 if downmob==1
	
	tab 		socmob, m
	
	
	// voluntary occupational mobility
	gen			voloccupch=0
	replace		voloccupch=1 if occupch==1 & whyexit==1
	
	// voluntary within-occupational mobility
	gen			volwithoccupch=0
	replace		volwithoccupch=1 if empch==1 & occupch!=1 & whyexit==1
	
	// involuntary occupational mobility
	gen			invoccupch=0
	replace		invoccupch=1 if occupch==1 & whyexit==2
	
	// involuntary within occupational mobility
	gen			invwithoccupch=0
	replace		invwithoccupch=1 if empch==1 & occupch!=1 & whyexit==2

*/
	

	
* Save data
	save 		"$posted/prepdata.dta", replace
	
	
	exit
	

	

