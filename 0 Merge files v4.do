
/*------------------------------------------------------------------------------
                     #1. Configuring your dofile
------------------------------------------------------------------------------*/

* Setup
	version		16.0            // Stata version control (put your own version)
	clear		all             // clear working memory
	macro		drop _all       // clear macros

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
                     #2. Merge variables
------------------------------------------------------------------------------*/


* Load data set ppathl for basic variables
	use			pid hid syear gebjahr netto phrf sex migback psample ///
				using "$data/ppathl.dta", clear
	sort		pid syear
	
* Merge variables from pl
	merge 		1:1 pid syear using "$data/pl.dta", ///	
				keepusing (plb0021 plb0031_h plb0284_h plb0001 plb0304_h) ///
				keep(match) nogen
				
* Merge education variables from pgen
	merge		1:1 pid syear using "$data/pgen.dta",				///
				keepusing (pgpsbil pgpbbil01 pgpbbil02 pgpbbil03 pgemplst ///
				pgisco88 pgisco08 pgcasmin pgjobch pgstib pgnace pgsiops88 ///
				pgsiops08 pgstib pglabnet pglabgro) ///
				keep(match) nogen
				
/*------------------------------------------------------------------------------
                     #3. Create masterfile
------------------------------------------------------------------------------*/
	
* Delete all measurements that are not based on successful individual interviews
	drop if netto>19
	
* Save as masterfile
	save 		"$posted/masterfile.dta", replace
		
	exit
