*2012
*updated on April 16th,2018
*updated on May 27th 2019: add educational expenditure 

*updated on may 29th 2019
*task: clean01.do does not seem right, go back to the original coding. aka create vars first then merge 
 
clear
*global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office
global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"


//community level char using control form 
use "${data}\data2012\control\cc_hh.dta", clear  //N=97 who did not participate 
drop if particip==0
sort cluster hhid12 
by cluster: gen thh=_N  //total hh within a community;
sort oblast hhid12
by oblast: gen ohh=_N // total hh within oblast;
rename hhid12 hhid
keep hhid cluster oblast thh ohh
save "${data}\data2012\control\hh_cc_2012.dta" , replace 
// N=2816


***STEP2: calculate hh level traits************
cd "${data}\data2012\household"
*demographics 
use hh1a.dta,clear
by hhid: g no_pp=_N

egen no_childr = sum(age < 18), by(hhid)
egen no_kid = sum(age < 6), by(hhid) 
egen no_old= sum (age > 60 ), by (hhid)

clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)
g married=(marstat==1)

clonevar age_h=age if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)

*gender /ethnicity
gen female=(h102==2) if  h104==1
bysort hhid: egen hhfemale=max(female) 

clonevar ethn=h105 if h104==1
bysort hhid: egen ethnicity=max(ethn)

keep hhid no_pp  no_childr no_kid no_old marstat hhage hhfemale ethnicity married
duplicates drop
save hh1a_m_2012, replace

*2.education expenditure 
use hh1b.dta, clear 
gen schexp_c=h121_4
bysort hhid: egen schexp=total(schexp_c)
keep hhid schexp
duplicates drop
save hh1b_m_2012, replace 
//N=2013


* ag activity;
use hh3,clear
gen agact = (h301 ==1) 
bysort hhid: egen agactivity=max(agact)
keep hhid agactivity 
duplicates drop
save hh3_m_2012, replace 
//N=2783


*food;
use hh4a.dta,clear

gen h401c_new=h401c
replace h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2
replace h401c_new=h401c*4 if h401d==3
egen foodexp = total(h401c_new), by (hhid)
keep foodexp hhid 
duplicates drop
save hh4a_m_2012, replace
// N=2813


*non-food exp
use hh4b.dta, clear
* usd 47.01 Eur 60.44  RUB 1.51
/* som, per month */
gen  nonfoode=h403
replace  nonfoode=h403*12 if h404==1 & h405==1  
* used, per month */
replace nonfoode=h403*47.01*12 if h404==2 & h405==1  
*usd, per year 
replace nonfoode=h403*47.01 if h404==2 & h405==1
egen nonfood=total (nonfoode), by (hhid)

*consumer goods  ;
egen cgoods= total (nonfoode) if n4b >=1 & n4b <5 , by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)

*med;
egen  med =total (nonfoode) if n4b == 5 | n4b==6 , by (hhid) 
egen  medexp = max (med) , by (hhid)

* communication
egen comm= total (nonfoode) if n4b ==7 |  n4b == 8 , by(hhid)
egen commexp=max(comm), by (hhid)


*housing exp;
egen hhsevice=total (nonfoode) if  (n4b >8 & n4b <= 15) , by (hhid)
egen hhdurable=total (nonfoode) if n4b >19 & n4b <= 25 , by (hhid)
egen hhexp= rowtotal(hhsevice hhdurable) 
egen housing=max (hhexp), by (hhid)
sum hhexp housing 

*others 
*other goods;
egen other=total (nonfoode) if   ( n4b >= 16 & n4b <= 19 )| n4b==26 ,by (hhid)
egen otherexp=max(other),by (hhid)

keep nonfood cgoodsexp medexp commexp housing  otherexp hhid
duplicates  drop 
save hh4b_m_2012, replace

* expences on events ;
use hh4c.dta,clear
egen expev=total (h415) , by (hhid)
sum (expev)
sort hhid
keep hhid expev
save hh4c_m_2012, replace 

*remittance recorded in the income moduel
use hh5, clear
g rem=h502*12 if n5==15
bysort hhid: egen rem_in=max(rem) 
keep hhid rem_in 
duplicates drop 
tempfile in
save `in.dta',replace 


*current labor migration
*note : the questionaire is different from 2011;
use hh6.dta,clear
gen mig= (h601>=1 & !missing (h601))
gen pastmig=(h600>=1 & !missing (h601))  // have ppl worked past 5yrs 
gen pmig=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 
keep mig pmig hhid
duplicates drop


***********merge total hhsize within a community 
// create migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
*merge 1:m hhid using "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2012\control\hh_cc_2012.dta"
merge 1:m hhid using "${data}\data2012\control\hh_cc_2012.dta"

egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh //percentage of migration at oblast level; 

la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl cluster
save hh6_m_2012, replace 


*migration destination;
use hh6a.dta,clear
bysort hhid: egen nrus=total(h605==1)
bysort hhid: egen nkaz=total(h605==2)

keep hhid nrus nkaz
duplicates drop 
save hh6a_m_2012, replace 


*remittances  ;
use hh6b.dta,clear

*  47.01   60.44   1.51 
*  USD	    EUR	    RUB	     
*year, sum
gen rem=h617_s if h617_c==1 & h617_t==3  
*used,month
replace rem=h617_s * 47.01 *12 if h617_c==2 & h617_t==1 
*used,year
replace rem=h617_s *47.01 if h617_c==2 & h617_t==2

*roble, month
replace rem=h617_s * 1.51 *12 if h617_c==3 & h617_t==1
 *roble, year
replace rem=h617_s * 1.51 if h617_c==3 & h617_t==2
*euro, month 
replace rem=h617_s * 60.44 *12  if h617_c==4 & h617_t==1
*euro, year 
replace rem=h617_s * 60.44 if h617_c==4 & h617_t==2

gen     rem_g =h625_s if h625_c==1
replace rem_g=h625_s * 47.01 if h625_c==2
replace rem_g=h625_s * 1.51 if h625_c==3
replace rem_g= h625_s * 60.44 if h625_c==4
replace rem_g =0 if rem_g ==. 

gen rem_total=rem + rem_g
summarize rem_total rem rem_g
replace rem_total=0 if rem_total==.

replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 

*remittance violatitlity
g stable=(h619==1 & h620==1 )
g volatile= (h619==2 & h620==2)

keep hhid rem  rem_g stable volatile
save hh6b_m_2012 , replace
// N=414

*outside shocks;
use hh7.dta
sort hhid
save hh7_m_2012, replace 



use hh1a_m_2012, clear 
merge 1:1 hhid using hh1b_m_2012, nogen  
merge 1:1 hhid using hh3_m_2012,  nogen    
merge 1:1 hhid using hh4a_m_2012, nogen  
merge 1:1 hhid using hh4b_m_2012, nogen
merge 1:1 hhid using hh4c_m_2012, nogen
merge 1:1 hhid using hh6_m_2012,  nogen
merge 1:1 hhid using hh6a_m_2012, nogen
merge 1:1 hhid using hh6b_m_2012, nogen 
merge 1:1 hhid using hh7_m_2012,  nogen 
merge 1:1 hhid using `in.dta', nogen



*===expense shares=== 
* DV food expences
egen totalexp=rowtotal(foodexp nonfood expev schexp)
summarize foodexp nonfood expev schexp totalexp 
g expp=totalexp/no_pp    //expensese per capita


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

*remittances: remittance income, if missing => remittance at the remittace module 
g rem_mig=rem+rem_g                 // remittance asked by household migrants
egen    rem_total=rowmax(rem_in rem_mig) 
replace rem_total=0 if rem_total==.

g lrem=log(rem_total+1) 
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (rem_total==0)

gen remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"

replace mig=0 if mig==.

* enviromental changes 
g drought = (h701_1 ==1)
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 


foreach x of var * { 
	rename `x' `x'2012
} 


*save G:\RA\RAship_Dr_Chi\Community_resiliency\paper3\LIK_10_13_stata\stata\panel\hhmerged_2012,replace 
duplicates drop  
sort hhid 
*save G:\RA\KYZpanel\hhmerged_2012,replace 
save "${dir}\data_revise\hhmerged_2012", replace 



*erase temporary files 
#delimit;
local data "hh1b_m_2012.dta   hh3_m_2012.dta  hh4a_m_2012.dta hh4b_m_2012.dta hh4c_m_2012.dta
            hh6_m_2012.dta hh6a_m_2012.dta hh6b_m_2012.dta hh7_m_2012.dta" ;
#delimit cr

foreach x of local data {
erase `x'
}
