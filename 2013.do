/*How large was the attrition of households in the LiK sample?
From the original sample of 3,000 households identified in 2010,2,450 households (81,6 percent) participated in all four waves of the project.*/


*STEP1: calculate remittance expenditure and merge all four waves;
  * cross-comparison of te survey items 2010-2013 
    * consumption : non-food consumtpion are measrued differently in different waves.  
	*income 
	* remittances

clear
use "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2013\control\cc_hh.dta"
sort psu hhid13 
by psu: gen thh=_N  //total hh within a community;
sort oblast hhid13
by oblast: gen ohh=_N // total hh within oblast;
rename hhid13 hhid
rename psu cluster
keep hhid cluster oblast thh ohh
save "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2013\control\hh_cc_2013.dta",replace


  
*2013 
clear
cd "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2013\household"
use hh1a.dta,replace
egen no_pp= max (pid ) , by (hhid)
egen no_childr = sum(h103a < 18), by(hhid)
egen no_kid = sum(h103_y <= 2007), by(hhid) 
egen no_old= sum (h103a > 60 ), by (hhid)
*egen school_kid = sum ( h103a  60 )
sort hhid 
keep if h104==1
duplicates drop
save hh1a_m_2013, replace



clear 
use hh2c.dta
gen land=h224*h227_g if h227_g !=. & h224==1  //hecter 
replace land=(h224*h227_s)/100 if h227_s !=. & h224==1
replace land=0 if  h224==0
la var land "own land (hectar)"
sort hhid
save hh2c_2013, replace



*food expenses;
use hh4a.dta
*expenses on purchased food;
gen h401c_new=h401c*52 if h401d==1
replace h401c_new=h401c*12 if h401d==2
replace h401c_new=0 if h401c==.
g price=h401c_new/h401b
*sum price 
egen foodexp = total(h401c_new), by (hhid)
duplicates drop
keep foodexp hhid 
duplicates drop
sort hhid
save hh4a_m, replace

*non-food expenses : consumer goods, household services transportation, medical care  ;
use hh4b.dta
gen h403_new= h403*12 if h404==1
replace h403_new=h403 if h404==2
egen nonfood = total (h403_new), by (hhid)
*consumer goods  ;
egen cgoods= total  (h403_new) if n4b >=1 & n4b <6 , by(hhid)
egen cgoodsexp = max (cgoods) , by (hhid)
*list cgoodsexp in 1/50

*med;
egen med =total (h403_new) if n4b == 6 | n4b==7  , by (hhid) 
egen  medexp = max (med) , by (hhid)

*communitcation/transportation;
egen comm= total (h403_new) if (n4b >=8 & n4b <= 10 ), by(hhid)
egen commexp=max(comm), by (hhid)

*housing exp;
**
egen hhservice=total (h403_new) if  (n4b >10 & n4b <= 17) | n4b==23 |n4b==24 |n4b==27 , by (hhid)
*egen hhserviceexp=max(hhservice), by (hhid)
egen hhdurable=total (h403_new) if n4b==22 |n4b==26 | (n4b >= 28 & n4b <= 32), by (hhid)
*egen hhdurableexp=max ( hhdurable ), by (hhid)
egen hhexp= rowtotal(hhservice hhdurable) 
*list hhservice hhdurable  hhexp in 1/40
egen housing=max (hhexp), by (hhid) 

egen event =total (h403_new) if n4b == 19, by (hhid) 
egen eventexp= max (event), by (hhid)

*other goods;
egen other=total (h403_new) if  ( n4b >= 18 & n4b <= 21 )| n4b==25 | n4b==33 ,by (hhid)
egen otherexp=max(other),by (hhid) 

keep nonfood cgoodsexp medexp commexp housing eventexp otherexp hhid
duplicates  drop 
*list nonfood cgoodsexp medexp commexp housing eventexp otherexp  in 1/30
sort hhid
save hh4b_m, replace

* expences on events ;
use hh4c.dta
egen expev=total (h415) , by (hhid)
sum (expev)
sort hhid
keep hhid expev
save hh4c_m, replace 


*source of income;

clear
use hh5a.dta
egen ag=total (h502) if source==1 | source==2 , by(hhid)
gen ag_in=ag*12
egen other=total (h502) if source >2 &(source !=15& source!=16), by(hhid)   // exclude remittance from this chunck. bx need to calculate rem separately;
gen other_in=other*12
egen income_labor = total (h502) , by (hhid)
gen annincome=income_labor *12 
keep  ag_in other_in annincome hhid
duplicates drop 
sort hhid
save hh5a_m, replace 


use hh5b
egen income_social = total (h504) , by (hhid)
gen aincome_social=12*income_social
keep aincome_social hhid
duplicates drop 
sort hhid 
save hh5b_m, replace

*current labor migration
clear
use hh6a.dta
sort hhid
gen mig= (h601>=1 & !missing (h601))
gen pastmig=(h600>=1 & !missing (h601))  // have ppl worked past 5yrs 
gen pmig=(mig==1 | pastmig==1) //at least one people migrated in last five years ; 

tab h601
gen destination=h605 if n6a==1 // 2013 asked each migrate their destination 


sort hhid
by hhid: gen dupid=_N
drop if dupid==2

keep mig pmig hhid destination


***********merge total hhsize within a community 
// create migration network : percentage of hh that has at least one migrants over the past 5 years in the community;
merge 1:m hhid using "G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2013\control\hh_cc_2013.dta"
egen tmig_com = sum(pmig), by(cluster)  // total number of migrations at community level 
egen tmig_obl = sum(pmig), by(oblast)  // total number of migrations at oblast level 

gen ptmcom=tmig_com/thh  //percentage of migration at community level; 
gen ptcobl=tmig_obl/ohh //percentage of migration at oblast level; 
tab ptmcom
tab ptcobl
la var ptmcom "migration network (community)"
la var ptcobl "migration network (oblast) "

keep hhid mig ptmcom ptcobl destination cluster
sort hhid
save hh6a_m, replace 

/*
   russia  |        525       92.11       92.11
kazakhstan  |         40        7.02       99.12
     other  |          5        0.88      100.00
*/



*labor migration destination;


*remittances  ;
*  48.4386 64.3536  1.5223 0.3184
*  USD	EUR	RUB	KZT 

use hh6b.dta
gen rem=h617_s if h617_c==1
replace rem=h617_s * 48.4386 if h617_c==2
replace rem=h617_s * 1.5223 if h617_c==3
replace rem= h617_s * 64.3536  if  h617_c==4
replace rem = 0 if rem ==.
gen rem_g =h625_s if h625_c==1
replace rem_g=h625_s * 48.4386 if h625_c==2
replace rem_g=h625_s * 1.5223 if h625_c==3
replace rem_g= h625_s * 64.3536 if  h625_c==4
replace rem_g =0 if rem_g ==. 

gen rem_total=rem + rem_g
summarize rem_total rem rem_g

*summarize h621

sort hhid
keep hhid rem_total rem rem_g

save hh6b_m , replace

*outside shocks;
use hh7.dta
sort hhid
save hh7_m, replace 

use cc_hh
g hhid=hhid13
sort hhid
drop hhid13
save cc_hh_m, replace 

*drop _merge
merge  hhid  using cc_hh_m hh0_m hh1a_m hh1b_m hh2c_2013 hh2a_m hh4c_m hh3_m hh4a_m hh4b_m hh5a_m hh5b_m  hh6a_m hh6b_m hh7_m


*IV
*generate dependent variables ;
replace rem_total=0 if rem_total==.
g lrem=log( rem_total) 


*demographics of the hh;
gen female=(h102 == 2)
gen age =h103a
tab h105, gen (ethnicity)
rename ethnicity1 kyz
rename ethnicity2 uzb 
rename ethnicity3 rus
gen other= (h105 > 4)

tab h108, gen(mar)
rename mar1 married
rename mar2 divorced 

*don't forget no_pp no_kid no_old

*household income;
replace aincome_social=0 if aincome_social==.
replace annincome=0 if annincome==.
gen income=annincome + aincome_social 
g lincome=log(income)

* enviromental changes 
g drought = (h701_1 ==1)
g flood = ( h701_2 ==1 )
g coldwinter = (h701_3==1) 
g frosts = (h701_4==1) 

* geography
gen rural = (residence ==2)

* DV food expences
gen totalexp=foodexp+nonfood
gen  totalexp_2=foodexp+nonfood+expev
summarize foodexp nonfood expev totalexp income

*gen food_1=foodexp/totalexp
gen food_2=foodexp/totalexp_2 
*gen food_3= foodexp/ (foodexp+nonfood)
*gen med_1=medexp/totalexp
gen med_2=medexp/totalexp_2
*gen med_3=medexp/ (foodexp+nonfood)
*gen housing_1=housingexp/totalexp
gen housing_2=housing/totalexp_2
*gen ed_1=edexp/income 
*gen event_1=expev/totalexp
gen event_2=expev/totalexp_2

*other expences;
g cgoods=cgoodsexp/totalexp_2
gen comm=commexp/totalexp_2
gen othercom=otherexp/totalexp_2

gen tconsum= food_2+cgoods+med_2+housing_2+event_2+comm+othercom
*list food_2 cgoods housing_2 med_2 event_2 comm othercom tconsum in 1/30

sum food_2 cgoods housing_2 med_2 event_2 comm othercom 

tab oblast, gen (oblast)

replace agactivity =0 if agactivity==.
replace lrem=0 if lrem==.


replace mig=0 if mig==.
gen remreceive = (rem_total >0.1) // & rem >0.1 ;
gen noremreceive= (mig==1 & rem_total==0)

tab remreceive 
tab mig
tab noremreceive

gen remcat=1 if remreceive==1
replace remcat=2 if noremreceive==1
replace remcat=3 if mig==0
label define remcat 1 "Recieve Remettances"   2 "Receive no remittance"  3 "Non migrants"
tab remcat
*misschk female age kyz uzb rus other married divorced  income_labor income_social totalexp rural oblast  
*misschk totalexp totalexp_2 foodexp medexp edexp food_1 med_1 food_3 med_3 event_2 event_1 expev

drop if food_2 ==. | cgoods==. | event_2==. | housing_2==. |comm==. | othercom==.

*****************************************
*****create of instruments***************
* (1) unexpected job creation in the destination countries  X age of hh head****
*generate percetage of pop work in russia
gen rus1=(destination==1) 
*how many work in russia in the communiy ?
egen rus_com = sum(rus1), by(cluster)  // total number of migrations in russian at community level 

gen iv1=0.2*rus_com*age 
*(2)community previous migration flow Xproportion of hh who have at least secondary level of ed
gen iv2=ptmcom*age



foreach x of var * { 
	rename `x' `x'2013 
} 
*rename hhid12_2013 hhid
*save hhmerged_2013, replace

duplicates drop

sort hhid2013
save G:\RA\KYZpanel\hhmerged_2013,replace 


/***community-level migration networks*************************************
clear
cd"G:\RA\RAship Dr Chi\Community resiliency\paper3\LIK_10_13_stata\stata\data2013\community"
use cm1.dta
tab c110
// do not know 46.53 ;
// conclusion:  the proportion of migration at community level is not accurate, may need to calcuate the proportion of migrates using 
//hh data; Also information on 2012 is missing
*******************************************************************************************
******************************************************************************
cd "G:\RA\KYZpanel"
use hhmerged_2013
*/
