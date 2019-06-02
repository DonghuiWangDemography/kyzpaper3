 *2011
 *updated on March 25th 2018
 *task : created community-level variable on the percentage ppl who migranted out among total population ? 
* updaated on April 16th, 2018 
*task : 1. record income 2, retrieve land use information 

 *updated on May 24, 2019
 *task :  add eduational expenditure 
 *updated on may 29th 2019
 *task: clean01.do does not seem right, go back to the original coding. aka create vars first then merge 
 
clear
global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office

global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"


//community level char using control form 
use "${data}\data2011\control\cc_hh.dta", clear
drop if particip==2 
sort cluster hhid 
by cluster: gen thh=_N  //total hh within a community;
sort oblast hhid
by oblast: gen ohh=_N // total hh within oblast;
keep hhid cluster oblast thh ohh
duplicates drop 
drop if cluster==.
unique hhid 
duplicates list hhid  
// add another hhid(6482) mannually for the ease to merge later on 
expand 2 if hhid==6483
bysort hhid: replace hhid=6482 if hhid==6483 & _n==2
save "${data}\data2011\control\hh_cc_2011.dta", replace // Nhhid=2,862


clear
cd "${data}\data2011\household"
*1.demographcis 
use hh1a.dta,clear
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 2005), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)
clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)

*marstats
g married=(marstat==1)
clonevar age_h=age if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)

*gender /ethnicity
gen female=(h102==2) if  h104==1
bysort hhid: egen hhfemale=max(female) 

clonevar ethn=h105 if h104==1
bysort hhid: egen ethnicity=max(ethn)

keep hhid no_pp no_childr no_childr no_kid no_old marstat hhage hhfemale ethnicity married
duplicates drop
save hh1a_m_2011, replace

*2.education expenditure 
use hh1b.dta, clear 
gen schexp_c=h121_4
bysort hhid: egen schexp=total(schexp_c)
keep hhid schexp
duplicates drop
save hh1b_m_2011, replace 


*4.ag activity;
use hh3,clear
gen agactivity = (h301 ==1) 
sort hhid
keep hhid ag 
duplicates drop
save hh3_m_2011, replace 


*5.food;
clear
use hh4a.dta
*expenses on purchased food;
gen 	h401a_new=h401a
replace h401a_new=h401a*52 if h401b==1
replace h401a_new=h401a*12 if h401b==2
replace h401a_new=h401a*4 if h401b==3
egen foodexp = total(h401a_new), by (hhid)
keep foodexp hhid 
duplicates drop
sort hhid
save hh4a_m_2011, replace

*6.non-food expenses
* used 46.14
use hh4b.dta
gen nonfoode=h403
replace nonfoode=h403*12 if h404==1 & h405==1
replace nonfoode=h403*46.14*12 if h404==2 & h405==1
replace nonfoode=h403*46.14 if h404==2 & h405==2
egen nonfood=total (nonfoode), by (hhid)

*detailed non-food expenses 
*consumer goods  ;
egen cgoods= total (nonfoode) if nitem ==1 | nitem ==2  | nitem ==19, by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)

*med;
egen med =total (nonfoode) if nitem == 3 | nitem==4 , by (hhid) 
egen  medexp = max (med) , by (hhid)

*communication
egen comm= total (nonfoode) if nitem ==14 |nitem ==15 , by(hhid)
egen commexp=max(comm), by (hhid)

*housing exp;
egen hhexp=total (nonfoode) if  (nitem >4 & nitem <= 12) , by (hhid)
egen housing=max (hhexp), by (hhid)

*others 
*other goods;
egen other=total (nonfoode) if nitem==13 | ( nitem >= 16 & nitem <= 18 )| nitem==20 |  nitem==21 ,by (hhid)
egen otherexp=max(other),by (hhid)

keep nonfood cgoodsexp medexp commexp housing  otherexp hhid
duplicates  drop 
save hh4b_m_2011, replace

*7.expences on events ;
use hh4c.dta
egen expev=total (h415) , by (hhid)
sum (expev)
sort hhid
keep hhid expev
duplicates drop
save hh4c_m_2011, replace 

*8.current labor migration
use hh6.dta, clear 
misschk h600b h601
gen mig= (h601>=1)   // how many adult members currently live abroad 
gen pmig=(h600a==1)  //at least one people migrated in last five years ; 
keep mig pmig  hhid
duplicates drop  //2863
sort hhid 

*merge total hhsize within a community 
// migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:1 hhid using "${data}\data2011\control\hh_cc_2011.dta", keep(matched)  //144 not matched. 

*list hhid cluster pmig thh ohh in 1/80

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh

la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl cluster
sort hhid
save hh6_m_2011, replace 


*9.destination countries;
use hh6a.dta, clear
bysort hhid: egen nrus=total(h605==1)
bysort hhid: egen nkaz=total(h605==2)

keep hhid nrus nkaz
duplicates drop  
save hh6a_m_2011, replace 



*10.remittances  ;
use hh6b.dta,clear

*  46.14   64.28   1.57 
*  USD	    EUR	    RUB	     
*year, sum
gen rem=h617_s if h617_c==1 & h617_t==3  
*used,month
replace rem=h617_s * 46.14 *12 if h617_c==2 & h617_t==1 
*used,year
replace rem=h617_s * 46.14 if h617_c==2 & h617_t==2

*roble, month
replace rem=h617_s * 1.57 *12 if h617_c==3 & h617_t==1
 *roble, year
replace rem=h617_s * 1.57 if h617_c==3 & h617_t==2
*euro, month 
replace rem=h617_s * 64.28*12  if h617_c==4 & h617_t==1
*euro, year 
replace rem=h617_s *  64.28  if h617_c==4 & h617_t==2

gen rem_g =h625s if h625c==1
replace rem_g=h625s * 46.14 if h625c==2
replace rem_g=h625s * 1.57 if h625c==3
replace rem_g= h625s * 64.28  if h625c==4
replace rem_g =0 if rem_g ==. 

gen rem_total=rem + rem_g
summarize rem_total rem rem_g
replace rem_total=0 if rem_total==.


sort hhid
keep hhid rem_total rem rem_g
save hh6b_m_2011 , replace


*11.outside shocks;
use hh7.dta
sort hhid
save hh7_m_2011, replace 


use hh1a_m_2011, clear 
merge 1:1 hhid using hh1b_m_2011, nogen  
merge 1:1 hhid using hh3_m_2011,  nogen    
merge 1:1 hhid using hh4a_m_2011, nogen  
merge 1:1 hhid using hh4b_m_2011, nogen
merge 1:1 hhid using hh4c_m_2011, nogen
merge 1:1 hhid using hh6_m_2011,  nogen
merge 1:1 hhid using hh6a_m_2011, nogen
merge 1:1 hhid using hh6b_m_2011, nogen 
merge 1:1 hhid using hh7_m_2011,  nogen 



*===expense shares=== 
egen totalexp=rowtotal(foodexp nonfood expev schexp)
summarize foodexp nonfood expev schexp totalexp 

*gen food_1=foodexp/totalexp
gen food_s=foodexp/totalexp 
gen med_s=medexp/totalexp
gen housing_s=housing/totalexp
gen event_s=expev/totalexp
gen schexp_s=schexp/totalexp

*other expences;
g   cgoods_s=cgoodsexp/totalexp
gen comm_s=commexp/totalexp
gen otherexp_s=otherexp/totalexp

gen tconsum= food_s+cgoods_s+med_s+housing_s+event_s+comm_s+otherexp_s+schexp_s
sum food_s cgoods_s med_s housing_s event_s comm_s otherexp_s schexp_s  //looks about right

*===further modification of vars 
replace rem_total=0 if rem_total==.
g lrem=log(rem_total+1) 
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)

gen     remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"

replace mig=0 if mig==.

* enviromental schocks  
g drought = (h701_1 ==1  )
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 
replace agactivity =0 if agactivity==.

drop h701*

*****************************************
*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*how many work in russia in the communiy ?
egen rus_com = sum(nrus), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.89*rus_com*hhage 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*hhage

la var iv1"unexpected job creation "
la var iv2 "previous migration flow"
foreach x of var * { 
	rename `x' `x'2011 
} 

duplicates drop
sort hhid 
save "${dir}\data_revise\hhmerged_2011", replace 


*erase temporary files 
#delimit;
local data "hh1a_m_2011.dta hh1b_m_2011.dta   hh3_m_2011.dta  hh4a_m_2011.dta hh4b_m_2011.dta hh4c_m_2011.dta
            hh6_m_2011.dta hh6a_m_2011.dta hh6b_m_2011.dta hh7_m_2011.dta" ;
#delimit cr
foreach x of local data {
erase `x'
}

