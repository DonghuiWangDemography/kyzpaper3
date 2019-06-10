*construct iv
*created on 05302019
clear
global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office

global logs "${dir}\logs"
global tables "${dir}\tables"

// *work on population data first
// cd "${dir}\data_revise"
// import excel "${dir}\data_revise\populationRUSKAZ_WB.xlsx", sheet("v2") firstrow clear
// *total number of pop age 15 +
// g rus65=(rpop65_RUS/100)*totalpop_RUS 
// g rus15=pop1564_RUS+rus65
//
// g KAZ65=(rpop66_KAZ/100)*totalpop_KAS
// g KAZ15=pop1564_KAZ+KAZ65
//
// save pop,replace


*employment 
import excel "${dir}\data_revise\employmentdata.xlsx", sheet("emp") firstrow clear
rename CountryName yr
rename RUS emp_rus
rename KAZ emp_kaz
g year=_n+1991

*unexpected job creation 
tsset year
regress emp_rus L.emp_rus
predict remp_rus, residuals

regress emp_kaz L.emp_kaz
predict remp_kaz, residuals

keep year emp_rus emp_kaz remp_rus remp_kaz

list year emp_rus emp_kaz  if year==2010 | year==2011 | year==2012 | year==2013

list year remp_rus remp_kaz  if year==2010 | year==2011 | year==2012 | year==2013

tempfile emp
save `emp.dta'

*exchange rate
*import excel "${dir}\data_revise\exchangerates_real&nominal.xls", sheet("table1") firstrow clear
import excel "${dir}\data_revise\exchangerates_wk10-13.xls", sheet("assembled")firstrow clear 
drop D-L

g year=year(date)
g month=month(date)

g mth=ym(year, month)
format mth %tm

// g lnrus=log(RUB)
// g Llnrus=lnrus[_n-2]
// g drus=lnrus-Llnrus
// bysort mth: egen sdrus=sd(drus)


bysort year month : egen mex_rus=mean(RUB)
bysort year month : egen mex_kaz=mean(KZT)

keep year month mth mex_rus mex_kaz
duplicates drop 

g nmex_rus=mex_rus/1.4984    // normalized to Dec 20091 
g nmex_kaz=mex_kaz/.29730001


twoway line nmex_rus mth || line nmex_kaz mth

*2011: 2010nov-2011nov  
tsset mth
g lrus=mex_rus[_n-6]  // lag six month 
g lkaz=mex_kaz[_n-6]

reg lrus L.lrus
predict rlrus, residual

bysort year: egen rex_rus=mean(rlrus)
bysort year: egen rex_kaz=mean(lkaz)


list year rex_rus  if year==2011 | year==2012 | year==2013


la var mth "Monthly exchange rates"
la var mex_rus "som per Russian Ruble"
la var mex_kaz "som per Kazakhstani tenge"

*changes on exchange rate 
keep year month mth mex_rus mex_kaz yex_rus yex_kaz
duplicates drop 
tsset mth
regress mex_rus L.mex_rus
predict rmex_rus, residuals

regress mex_kaz L.mex_kaz
predict rmex_kaz, residuals

*calculate monthly change
g cgmex_rus=(mex_rus-L.mex_rus)/mex_rus


twoway line rmex_rus mth
twoway line rmex_kaz mth
twoway line cgmex_rus mth

keep year month mth yex_rus yex_kaz mex_rus mex_kaz
duplicates drop 

tempfile exg
save `exg.dta', replace 

// *keep yearly only 
// keep year yex_rus yex_kaz 
// duplicates drop
// merge 1:1 year using `emp.dta', keep(match)
// 




//
// *exchange rate 
// tsset year 
// g ryex_rus=(yex_rus-L.yex_rus)/yex_rus
// g ryex_kaz=(yex_kaz-L.yex_kaz)/yex_kaz
//
//
// regress ryex_rus L.ryex_rus
// predict rryex_rus, residuals
//
// regress ryex_kaz L.ryex_kaz
// predict rryex_kaz, residuals
//
//



*may not useful 
// *total remittances 
import excel "${dir}\data_revise\remmtancemoneytransfer.xls",  sheet("table2") firstrow clear
g year=year(date)
g month=month(date)

g mth=ym(year, month)
format mth %tm

bysort year month : egen mrem_rus=mean(RUS)
bysort year month : egen mrem_kaz=mean(KAZ)

bysort year: egen rem_rus=mean(RUS)
bysort year: egen rem_kaz=mean(KAZ)


keep year month mth mrem_rus mrem_kaz rem_rus rem_kaz



// merge 1:1 year using `emp.dta' , keep(match) nogen 
// merge 1:1 year using `exg.dta' , keep(match) nogen 
merge 1:1 mth using `exg.dta', keep(match) nogen 

tsset mth
twoway line mex_rus mth

graph twoway (lfit L(1).mrem_rus mex_rus) (scatter L(1).mrem_rus mex_rus )
graph twoway (lfit mrem_kaz L(6).mex_kaz) (scatter mrem_kaz L(6).mex_kaz )
save rem&ex.dta,replace

*/



*AR(1)
use macro.dta,clear
tsset year

reg emp_rus L.emp_rus
predict remp_rus, residuals

reg emp_kaz L.emp_kaz
predict remp_kaz, residuals


list year remp_rus remp_kaz if year==2010 | year==2011 |   year==2012 |  year==2013


*employment growth rate
g remp_rus=(emp_rus-L.emp_rus)/emp_rus
g remp_kaz=(emp_kaz-L.emp_kaz)/emp_kaz


regress remp_rus L.remp_rus
predict rremp_rus, residuals

regress remp_kaz L.remp_kaz
predict rremp_kaz, residuals

graph twoway (lfit rem_RUS L.rremp_rus)  || (scatter  rem_RUS L.rremp_rus)

*exchange 
regress exg_RUS L.exg_RUS
predict rexg_rus, residuals

regress exg_KAZ L.exg_KAZ
predict rexg_kaz, residuals


list year rremp_rus rremp_kaz if year==2010 | year==2011 |   year==2012 |  year==2013

tsset year
twoway scatter rem_RUS L.remp_rus
twoway scatter rem_KAZ L.remp_kaz

clear
import excel "E:\revise&resubmit\KYZpaper\paper3\data_revise\complie.xlsx", sheet("v2") firstrow clear

twoway scatter rem_RUS remp_rus
twoway scatter rem_RUS rexg_rus


//twoway line RUS date if year>=2010 & year<=2013 || line KAZ date if year>=2010 & year<=2013
*/
