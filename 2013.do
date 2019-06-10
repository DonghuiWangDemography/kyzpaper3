/*How large was the attrition of households in the LiK sample?
From the original sample of 3,000 households identified in 2010,2,450 households (81,6 percent) participated in all four waves of the project.*/


*STEP1: calculate remittance expenditure and merge all four waves;
  * cross-comparison of te survey items 2010-2013 
    * consumption : non-food consumtpion are measrued differently in different waves.  
	*income 
	* remittances

*updated on 05292019
 
clear
*global dir "E:\revise&resubmit\KYZpaper\paper3"  // usb office
global logs "${dir}\logs"
global tables "${dir}\tables"
global data "${dir}\LIK_10_13_stata\stata"


use "${data}\data2013\control\cc_hh.dta",clear
drop if particip==0

bysort psu: gen thh=_N  //total hh within a community;
sort oblast hhid13
bysort oblast: gen ohh=_N // total hh within oblast;
rename hhid13 hhid
rename psu cluster
keep hhid cluster oblast thh ohh
save "${data}\data2013\control\hh_cc_2013.dta" , replace 

  
***STEP2: calculate hh level traits************
*demographics 
cd "${data}\data2013\household"
use hh1a.dta,clear  // N=2584
by hhid: g no_pp=_N
egen no_childr = sum(h103a < 18), by(hhid)
egen no_kid = sum(h103a <= 6), by(hhid) 
egen no_old= sum (h103a > 60 ), by (hhid)

*marstat
clonevar marstat_h=h108 if h104==1 // hh head's marital stataus 
bysort hhid: egen marstat=max(marstat_h)
g married=(marstat==1)

clonevar age_h=h103a if h104==1 // hh head's age
bysort hhid: egen hhage=max(age_h)

*gender /ethnicity
gen female=(h102==2) if  h104==1
bysort hhid: egen hhfemale=max(female) 

clonevar ethn=h105 if h104==1
bysort hhid: egen ethnicity=max(ethn)

keep hhid no_pp no_childr no_childr no_kid no_old marstat hhage hhfemale ethnicity married
duplicates drop
save hh1a_m_2013, replace


//education expenditure 
use hh1b.dta, clear   // N=1443
gen schexp_c=h121_5
bysort hhid: egen schexp=total(schexp_c)
keep hhid schexp
duplicates drop
save hh1b_m_2013, replace 



*ag activity;
use hh3,clear  // N=1086
gen agact = (h301 ==1) 
bysort hhid: egen agactivity=max(agact)
keep hhid agactivity 
duplicates drop
save hh3_m_2013, replace 

*food expenses;
use hh4a.dta,clear
*expenses on purchased food;
gen     h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2

egen foodexp = total(h401c_new), by (hhid)
keep foodexp hhid 
duplicates drop
save hh4a_m_2013, replace
// N=2537 



*non-food expenses : consumer goods, household services transportation, medical care  ;
use hh4b.dta,clear

gen    h403_new= h403*12 if h404==1
replace h403_new=h403    if h404==2
egen nonfood = total (h403_new), by (hhid)

*consumer goods  ;
egen cgoods= total  (h403_new) if n4b >=1 & n4b <6 , by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)

*med;
egen med =total (h403_new) if n4b == 6 | n4b==7  , by (hhid) 
egen  medexp = max (med) , by (hhid)

*communitcation/transportation;
egen comm= total (h403_new) if (n4b >=8 & n4b <= 10 ), by(hhid)
egen commexp=max(comm), by (hhid)

*housing exp;

egen hhservice=total(h403_new) if  (n4b >10 & n4b <= 17) | n4b==23 |n4b==24 |n4b==27 , by (hhid)
egen hhdurable=total (h403_new) if n4b==22 |n4b==26 | (n4b >= 28 & n4b <= 32), by (hhid)
egen hhexp= rowtotal(hhservice hhdurable) 
egen housing=max (hhexp), by (hhid) 

*other goods;
egen other=total (h403_new) if  ( n4b >= 18 & n4b <= 21 )| n4b==25 | n4b==33 ,by (hhid)
egen otherexp=max(other),by (hhid) 

keep nonfood cgoodsexp medexp commexp housing  otherexp hhid
duplicates  drop 
*list nonfood cgoodsexp medexp commexp housing eventexp otherexp  in 1/30
save hh4b_m_2013, replace


 
* expences on events ;
use hh4c.dta
egen expev=total (h415) , by (hhid)
keep hhid expev
duplicates drop 
save hh4c_m_2013, replace 


*remittance recorded in the income moduel
use hh5a, clear
g rem=h502*12 if source==9
bysort hhid: egen rem_in=max(rem) 
keep hhid rem_in 
duplicates drop 
tempfile in
save `in.dta',replace 




*current labor migration
use hh6a.dta,clear
gen mig= (h601>=1 & !missing (h601))
gen pastmig=(h600>=1 & !missing (h600))  // have ppl worked past 5yrs 
gen pmig=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 

bysort hhid: egen nrus=total(h605==1)
bysort hhid: egen nkaz=total(h605==2)

keep mig pmig hhid  nrus nkaz
duplicates drop 

***********merge total hhsize within a community 
// create migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:m hhid using "${data}\data2013\control\hh_cc_2013.dta"
egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh //percentage of migration at oblast level; 
tab ptmcom
tab ptcobl
la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl nrus nkaz cluster
sort hhid
save hh6a_m_2013, replace 

 
 
/*
   russia  |        525       92.11       92.11
kazakhstan  |         40        7.02       99.12
     other  |          5        0.88      100.00
*/




*remittances  ;
*  48.4386 64.3536  1.5223 0.3184
*  USD	EUR	RUB	KZT 

use hh6b.dta,clear
gen rem=h617_s if h617_c==1
replace rem=h617_s * 48.4386 if h617_c==2
replace rem=h617_s * 1.5223 if h617_c==3
replace rem= h617_s * 64.3536  if  h617_c==4
replace rem = 0 if rem ==.
gen rem_g =h625_s if h625_c==1
replace rem_g=h625_s * 48.4386 if h625_c==2
replace rem_g=h625_s * 1.5223 if h625_c==3
replace rem_g=h625_s * 64.3536 if  h625_c==4
replace rem_g =0 if rem_g ==. 

*remittance violatitlity
g stable=(h619==1 & h620==1 )
g volatile= (h619==2 & h620==2)


keep hhid  rem rem_g stable  volatile
save hh6b_m_2013 , replace

*outside shocks;
use hh7.dta,clear
sort hhid
save hh7_m_2013, replace 

// use cc_hh,clear
// g hhid=hhid13
// sort hhid
// drop hhid13
// save cc_hh_m_2013, replace 



use hh1a_m_2013, clear 
merge 1:1 hhid using hh1b_m_2013, nogen  
merge 1:1 hhid using hh3_m_2013,  nogen    
merge 1:1 hhid using hh4a_m_2013, nogen  
merge 1:1 hhid using hh4b_m_2013, nogen
merge 1:1 hhid using hh4c_m_2013, nogen
merge 1:1 hhid using hh6a_m_2013, nogen
merge 1:1 hhid using hh6b_m_2013, nogen 
merge 1:1 hhid using hh7_m_2013,  nogen 

merge 1:1 hhid using `in.dta', nogen

// N=2586


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
gen remreceive = (rem_total >0) // & rem >0.1 ;
gen noremreceive= (rem_total==0)

gen     remcat=1 if remreceive==1 
replace remcat=2 if noremreceive==1 
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"

replace mig=0 if mig==.

* enviromental changes 
g drought = (h701_1 ==1)
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

drop h701*


foreach x of var * { 
	rename `x' `x'2013 
} 
*rename hhid12_2013 hhid
*save hhmerged_2013, replace

save "${dir}\data_revise\hhmerged_2013", replace 


*erase temporary files 
#delimit;
local data "hh1a_m_2013.dta hh1b_m_2013.dta   hh3_m_2013.dta  hh4a_m_2013.dta hh4b_m_2013.dta hh4c_m_2013.dta
             hh6a_m_2013.dta hh6b_m_2013.dta hh7_m_2013.dta" ;
#delimit cr
foreach x of local data {
erase `x'
}
