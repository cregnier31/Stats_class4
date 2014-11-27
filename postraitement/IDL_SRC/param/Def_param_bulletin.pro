PRO Def_param_bulletin

;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; C. REGNIER Mai 2009
;; Definition de  paramètres globaux pour les statistiques sur les CLASS4
;; utilisées dans le bulletin trimestriel 
;; Juin 2009 Add PSY2 zones C.REGNIER
;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COMMON param_CLASS4,variable_name,valeurs_cmax,$
valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
profondeur,profondeur2,liste_zone,liste_zone_PSY2,$
liste_TEST,listemodele,liste_zone_GLOMyo,profondeur3,$
profondeur4,liste_zone_PSY2_SHOM,tab_prof,tab_model,$
tab_e3t,tab_prof_2,variable_name_2,variable_name_3,$
variable_name_4,tab_prof_3,profondeur5,file_mask,file_save

;; Definition des variable_names
variable_name=strarr(26)
variable_name(0)='TEMP'
variable_name(1)='PSAL'
variable_name(2)='HDCST_TEMP'
variable_name(3)='HDCST_PSAL'
variable_name(4)='ANA_TEMP'
variable_name(5)='ANA_PSAL'
variable_name(6)='FRCST1D_TEMP'
variable_name(7)='FRCST1D_PSAL'
variable_name(8)='FRCST3D_TEMP'
variable_name(9)='FRCST3D_PSAL'
variable_name(10)='FRCST5D_TEMP'
variable_name(11)='FRCST5D_PSAL'
variable_name(12)='FRCST6D_TEMP'
variable_name(13)='FRCST6D_PSAL'
variable_name(14)='PERS_TEMP'
variable_name(15)='PERS_PSAL'
variable_name(16)='PERS3D_TEMP'
variable_name(17)='PERS3D_PSAL'
variable_name(18)='PERS6D_TEMP'
variable_name(19)='PERS6D_PSAL'
variable_name(20)='TMLEV'
variable_name(21)='SMLEV'
variable_name(22)='TMARV'
variable_name(23)='SMARV'      
variable_name(24)='TMLEV09'
variable_name(25)='SMLEV09'

variable_name_2=strarr(28)
variable_name_2(0)='TEMP'
variable_name_2(1)='PSAL'
variable_name_2(2)='HDCST_TEMP'
variable_name_2(3)='HDCST_PSAL'
variable_name_2(4)='ANA_TEMP'
variable_name_2(5)='ANA_PSAL'
variable_name_2(6)='FRCST1D_TEMP'
variable_name_2(7)='FRCST1D_PSAL'
variable_name_2(8)='FRCST3D_TEMP'
variable_name_2(9)='FRCST3D_PSAL'
variable_name_2(10)='FRCST5D_TEMP'
variable_name_2(11)='FRCST5D_PSAL'
variable_name_2(12)='FRCST6D_TEMP'
variable_name_2(13)='FRCST6D_PSAL'
variable_name_2(14)='PERS_TEMP'
variable_name_2(15)='PERS_PSAL'
variable_name_2(16)='PERS3D_TEMP'
variable_name_2(17)='PERS3D_PSAL'
variable_name_2(18)='PERS6D_TEMP'
variable_name_2(19)='PERS6D_PSAL'
variable_name_2(20)='TMLEV'
variable_name_2(21)='SMLEV'
variable_name_2(22)='TMARV'
variable_name_2(23)='SMARV'
variable_name_2(24)='TMLEV09'
variable_name_2(25)='SMLEV09'
variable_name_2(26)='TMARV11'
variable_name_2(27)='SMARV11'

variable_name_3=strarr(8)
variable_name_3(0)='TEMP'
variable_name_3(1)='PSAL'
variable_name_3(2)='HDCST_TEMP'
variable_name_3(3)='HDCST_PSAL'
variable_name_3(4)='TMLEV09'
variable_name_3(5)='SMLEV09'
variable_name_3(6)='TMLEV98'
variable_name_3(7)='SMLEV98'

variable_name_4=strarr(8)
variable_name_4(0)='TEMP'
variable_name_4(1)='PSAL'
variable_name_4(2)='HDCST_TEMP'
variable_name_4(3)='HDCST_PSAL'
variable_name_4(4)='TMLEV09'
variable_name_4(5)='SMLEV09'
variable_name_4(6)='TMARV11'
variable_name_4(7)='SMARV11'


file_mask=''
file_save=''

;; Range values
valeurs_cmax=fltarr(2,6)
valeurs_cmax_sal=fltarr(2,6)

;; Temperature
valeurs_cmax(1,0)=2.0 ;; 1.8
valeurs_cmax(1,1)=2.2
valeurs_cmax(1,2)=1.8  ;; 1.5
valeurs_cmax(1,3)=1.5  ;; 1
valeurs_cmax(1,4)=0.3
valeurs_cmax(1,5)=1.5

valeurs_cmax(0,0)=0.0  ;; 0.5  
valeurs_cmax(0,1)=0.5  ;; 0.8
valeurs_cmax(0,2)=0.0  ;; 0.6
valeurs_cmax(0,3)=0.0  ;; 0.2  
valeurs_cmax(0,4)=0.0  ;; 0.1 
valeurs_cmax(0,5)=0.0  ;; 0.5 

;; Salinité
valeurs_cmax_sal(1,0)=1.6
valeurs_cmax_sal(1,1)=1.0
valeurs_cmax_sal(1,2)=0.6
valeurs_cmax_sal(1,3)=0.15
valeurs_cmax_sal(1,4)=0.1
valeurs_cmax_sal(1,5)=1.2

valeurs_cmax_sal(0,0)=0.0 ;; 0.2
valeurs_cmax_sal(0,1)=0.0 ;; 0.2
valeurs_cmax_sal(0,2)=0.0
valeurs_cmax_sal(0,3)=0.0
valeurs_cmax_sal(0,4)=0.0
valeurs_cmax_sal(0,5)=0.0

valeurs_cmax2=fltarr(2,11)
valeurs_cmax2_sal=fltarr(2,11)  
;; Temperature
valeurs_cmax2(1,0)=1.0 ;; 1.8
valeurs_cmax2(1,1)=1.0
valeurs_cmax2(1,2)=1.0  ;; 1.5
valeurs_cmax2(1,3)=1.0  ;; 1
valeurs_cmax2(1,4)=1.0
valeurs_cmax2(1,5)=1.0
valeurs_cmax2(1,6)=1.0
valeurs_cmax2(1,7)=1.0  ;; 1.5
valeurs_cmax2(1,8)=1.0  ;; 1
valeurs_cmax2(1,9)=1.0
valeurs_cmax2(1,10)=2.0

valeurs_cmax2(0,0)=0.0  ;; 0.5  
valeurs_cmax2(0,1)=0.0  ;; 0.8
valeurs_cmax2(0,2)=0.0  ;; 0.6
valeurs_cmax2(0,3)=0.0  ;; 0.2  
valeurs_cmax2(0,4)=0.0  ;; 0.1 
valeurs_cmax2(0,5)=0.0  ;; 0.5 
valeurs_cmax2(0,6)=0.0  ;; 0.5  
valeurs_cmax2(0,7)=0.0  ;; 0.8
valeurs_cmax2(0,8)=0.0  ;; 0.6
valeurs_cmax2(0,9)=0.0  ;; 0.2  
valeurs_cmax2(0,10)=0.0  ;; 0.1 

;; Salinité
valeurs_cmax2_sal(1,0)=0.5
valeurs_cmax2_sal(1,1)=0.5 
valeurs_cmax2_sal(1,2)=0.5
valeurs_cmax2_sal(1,3)=0.5
valeurs_cmax2_sal(1,4)=0.5
valeurs_cmax2_sal(1,5)=0.5
valeurs_cmax2_sal(1,6)=0.5
valeurs_cmax2_sal(1,7)=0.5
valeurs_cmax2_sal(1,8)=0.5
valeurs_cmax2_sal(1,9)=0.5
valeurs_cmax2_sal(1,10)=0.5


valeurs_cmax2_sal(0,0)=0.0 ;; 0.2
valeurs_cmax2_sal(0,1)=0.0 ;; 0.2
valeurs_cmax2_sal(0,2)=0.0
valeurs_cmax2_sal(0,3)=0.0
valeurs_cmax2_sal(0,4)=0.0
valeurs_cmax2_sal(0,5)=0.0
valeurs_cmax2_sal(0,6)=0.0 ;; 0.2
valeurs_cmax2_sal(0,7)=0.0 ;; 0.2
valeurs_cmax2_sal(0,8)=0.0
valeurs_cmax2_sal(0,9)=0.0
valeurs_cmax2_sal(0,10)=0.0

tab_prof=fltarr(7)
tab_prof(0)=0
tab_prof(1)=5
tab_prof(2)=100
tab_prof(3)=300
tab_prof(4)=800
tab_prof(5)=2000
tab_prof(6)=5000


tab_prof_2=fltarr(8)
tab_prof_2(0)=0
tab_prof_2(1)=50
tab_prof_2(2)=100
tab_prof_2(3)=150
tab_prof_2(4)=200
tab_prof_2(5)=300
tab_prof_2(6)=400
tab_prof_2(7)=500

tab_prof_3=fltarr(5)
tab_prof_3(0)=0
tab_prof_3(1)=100
tab_prof_3(2)=300
tab_prof_3(3)=800
tab_prof_3(4)=2000

tab_model=fltarr(51)
tab_model(0)=0.4940254
tab_model(1)=1.541375 
tab_model(2)=2.645669 
tab_model(3)=3.819495 
tab_model(4)=5.078224 
tab_model(5)=6.440614 
tab_model(6)=7.929560 
tab_model(7)=9.572997 
tab_model(8)=11.40500 
tab_model(9)=13.46714 
tab_model(10)=15.81007
tab_model(11)=18.49556
tab_model(12)=21.59882
tab_model(13)=25.21141
tab_model(14)=29.44473
tab_model(15)=34.43415
tab_model(16)=40.34405
tab_model(17)=47.37369
tab_model(18)=55.76429
tab_model(19)=65.80727
tab_model(20)=77.85385
tab_model(21)=92.32607
tab_model(22)=109.7293
tab_model(23)=130.6660
tab_model(24)=155.8507
tab_model(25)=186.1256
tab_model(26)=222.4752
tab_model(27)=266.0403
tab_model(28)=318.1274
tab_model(29)=380.2130
tab_model(30)=453.9377
tab_model(31)=541.0889
tab_model(32)=643.5668
tab_model(33)=763.3331
tab_model(34)=902.3393
tab_model(35)=1062.440
tab_model(36)=1245.291
tab_model(37)=1452.251
tab_model(38)=1684.284
tab_model(39)=1941.893
tab_model(40)=2225.078
tab_model(41)=2533.336
tab_model(42)=2865.703
tab_model(43)=3220.820
tab_model(44)=3597.032
tab_model(45)=3992.484
tab_model(46)=4405.224
tab_model(47)=4833.291
tab_model(48)=5274.784
tab_model(49)=5727.917
tab_model(50)=5727.917

   
tab_e3t=fltarr(51)
tab_e3t(0)=1.02248397350079     
tab_e3t(1)=1.07392811351213     
tab_e3t(2)=1.13674814359675     
tab_e3t(3)=1.21345584707222     
tab_e3t(4)=1.30711575048712     
tab_e3t(5)=1.42146584903565     
tab_e3t(6)=1.56106425198585     
tab_e3t(7)=1.73146709254409     
tab_e3t(8)=1.93944403877130     
tab_e3t(9)=2.19323886239145     
tab_e3t(10)=2.50288375576515     
tab_e3t(11)=2.88057739611743     
tab_e3t(12)=3.34113806593193     
tab_e3t(13)=3.90254431853426     
tab_e3t(14)=4.58657651299428     
tab_e3t(15)=5.41957269345142     
tab_e3t(16)=6.43331123889259     
tab_e3t(17)=7.66602969916604     
tab_e3t(18)=9.16358317214816     
tab_e3t(19)=10.9807349566401     
tab_e3t(20)=13.1825550269287     
tab_e3t(21)=15.8458755786651     
tab_e3t(22)=19.0607145156183     
tab_e3t(23)=22.9315242134296     
tab_e3t(24)=27.5780518324723     
tab_e3t(25)=33.1355086584035     
tab_e3t(26)=39.7536438697515     
tab_e3t(27)=47.5942154497487     
tab_e3t(28)=56.8262730452722     
tab_e3t(29)=67.6186565548615     
tab_e3t(30)=80.1292298269766     
tab_e3t(31)=94.4906811968493     
tab_e3t(32)=110.793290979986     
tab_e3t(33)=129.065899882335     
tab_e3t(34)=149.257319370698     
tab_e3t(35)=171.221369079087     
tab_e3t(36)=194.709234040142     
tab_e3t(37)=219.372494549893     
tab_e3t(38)=244.778740101692     
tab_e3t(39)=270.439259898308     
tab_e3t(40)=295.845505450107     
tab_e3t(41)=320.508765959858     
tab_e3t(42)=343.996630920912     
tab_e3t(43)=365.960680629302     
tab_e3t(44)=386.152100117665     
tab_e3t(45)=404.424709020014     
tab_e3t(46)=420.727318803151     
tab_e3t(47)=435.088770173023     
tab_e3t(48)=447.599343445138     
tab_e3t(49)=458.391726954728     
tab_e3t(50)=5957.95745287756 

profondeur=strarr(6)
profondeur(0)='0-5m'
profondeur(1)='5-100m'
profondeur(2)='100-500m'
profondeur(3)='500-2000m'
profondeur(4)='2000-5000m'
profondeur(5)='0-6000m'

profondeur2=strarr(8)
profondeur2(0)='0-50m'
profondeur2(1)='50-100m'
profondeur2(2)='100-150m'
profondeur2(3)='150-200m'
profondeur2(4)='200-300m'
profondeur2(5)='300-400m'
profondeur2(6)='400-500m'
profondeur2(7)='0-500m'

profondeur3=strarr(5)
profondeur3(0)='0-5m'
profondeur3(1)='5-100m'
profondeur3(2)='100-500m'
profondeur3(3)='500-2000m'
profondeur3(4)='0-2000m'

profondeur4=strarr(7)
profondeur4(0)='0-5m'
profondeur4(1)='5-100m'
profondeur4(2)='100-300m'
profondeur4(3)='300-800m'
profondeur4(4)='800-2000m'
profondeur4(5)='2000-5000m'
profondeur4(6)='0-5000m'

profondeur5=strarr(5)
profondeur5(0)='0-100m'
profondeur5(1)='100-300m'
profondeur5(2)='300-800m'
profondeur5(3)='800-2000m'
profondeur5(4)='0-2000m'

;; Zones CLASS1
liste_zone=strarr(14)
liste_zone(0)='ACC'
liste_zone(1)='ARC'
liste_zone(2)='GLO'
liste_zone(3)='IND'
liste_zone(4)='MED'
liste_zone(5)='NAT'
liste_zone(6)='NPA'
liste_zone(7)='SAT'
liste_zone(8)='SPA'
liste_zone(9)='TAT'
liste_zone(10)='TPA'
liste_zone(11)='NORDSEA'
liste_zone(12)='FACADE'
liste_zone(13)='BALTIC'

;; Zones CLASS1 GLO Myo
liste_zone_GLOMyo=strarr(8)
liste_zone_GLOMyo(0)='ACC'
liste_zone_GLOMyo(1)='ARC'
liste_zone_GLOMyo(2)='GLO'
liste_zone_GLOMyo(3)='IND'
liste_zone_GLOMyo(4)='NPA'
liste_zone_GLOMyo(5)='SAT'
liste_zone_GLOMyo(6)='SPA'
liste_zone_GLOMyo(7)='TPA'

;;; Zones PSY2
liste_zone_PSY2=strarr(7)
liste_zone_PSY2(0)='NAT'
liste_zone_PSY2(1)='MED'
liste_zone_PSY2(2)='TAT'
liste_zone_PSY2(3)='NORDSEA'
liste_zone_PSY2(4)='FACADE'
liste_zone_PSY2(5)='ATL12'
liste_zone_PSY2(6)='BALTIC'


;; Zones PSY2_SHOM
liste_zone_PSY2_SHOM=strarr(9)
liste_zone_PSY2_SHOM(0)='Indien_Nord_Ouest'
liste_zone_PSY2_SHOM(7)='Atl_Nord_Est'
liste_zone_PSY2_SHOM(1)='Atl_Nord_Ouest'
liste_zone_PSY2_SHOM(1)='IBI36'
liste_zone_PSY2_SHOM(2)='Norvege'
liste_zone_PSY2_SHOM(3)='Atl_Trop'
liste_zone_PSY2_SHOM(4)='Atl_Trop_Guinee'
liste_zone_PSY2_SHOM(5)='Medit_Ouest'
;liste_zone_PSY2_SHOM(6)='Medit_Est'
liste_zone_PSY2_SHOM(6)='Indien_Est'
liste_zone_PSY2_SHOM(8)='Indien_Sud_Ouest'

;; zone TEST
liste_TEST=strarr(1)
liste_TEST(0)='ACC'
;; MODELES
listemodele=strarr(4)
listemodele(0)='PSY3V2R2'
listemodele(1)='PSY2V3R1'
listemodele(2)='WOA05'
listemodele(3)='FOAM'

;; Zones IND
liste_zone_IND=strarr(3)
liste_zone_IND(0)='NAT'
liste_zone_IND(1)='MED'
liste_zone_IND(2)='TAT'

return

END
