"""
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 C. REGNIER Mai 2009
 Definition de  parametres globaux pour les statistiques sur les CLASS4
 utilisees dans le bulletin trimestriel 
 Juin 2009 Add PSY2 zones C.REGNIER
 Avril 2013 python conversion L.ZAWADZKI
 Octobre 2013 C.REGNIER ajout de la climatologie
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"""

import numpy as np

## Definition des variable_names

variable_nameT     = np.chararray(8,itemsize=25)
variable_nameT[0]  = 'BEST_TEMP'
variable_nameT[1]  = 'FRCST1D_TEMP'
variable_nameT[2]  = 'FRCST3D_TEMP'
variable_nameT[3]  = 'FRCST5D_TEMP'
variable_nameT[4]  = 'PERS1D_TEMP'
variable_nameT[5]  = 'PERS3D_TEMP'
variable_nameT[6]  = 'PERS5D_TEMP'
variable_nameT[7]  = 'CLIM_TEMP'

variable_nameT_new     = np.chararray(12,itemsize=25)
variable_nameT_new[0]  = 'BEST_TEMP'
variable_nameT_new[1]  = 'FRCST1D_TEMP'
variable_nameT_new[2]  = 'FRCST3D_TEMP'
variable_nameT_new[3]  = 'FRCST5D_TEMP'
variable_nameT_new[4]  = 'FRCST7D_TEMP'
variable_nameT_new[5]  = 'FRCST9D_TEMP'
variable_nameT_new[6]  = 'PERS1D_TEMP'
variable_nameT_new[7]  = 'PERS3D_TEMP'
variable_nameT_new[8]  = 'PERS5D_TEMP'
variable_nameT_new[9]  = 'PERS7D_TEMP'
variable_nameT_new[10]  = 'PERS9D_TEMP'
variable_nameT_new[11]  = 'CLIM_TEMP'

variable_nameSST_best=np.chararray(2,itemsize=25)
variable_nameSST_best[0]  = 'BEST_TEMP'
variable_nameSST_best[1]  = 'CLIM_TEMP'

variable_nameSST     = np.chararray(8,itemsize=25)
variable_nameSST[0]  = 'BEST_SST'
variable_nameSST[1]  = 'FRCST1D_SST'
variable_nameSST[2]  = 'FRCST3D_SST'
variable_nameSST[3]  = 'FRCST5D_SST'
variable_nameSST[4]  = 'PERS1D_SST'
variable_nameSST[5]  = 'PERS3D_SST'
variable_nameSST[6]  = 'PERS5D_SST'
variable_nameSST[7]  = 'CLIM_SST'

variable_nameSST_new  = np.chararray(12,itemsize=25)
variable_nameSST_new[0]  = 'BEST_SST'
variable_nameSST_new[1]  = 'FRCST1D_SST'
variable_nameSST_new[2]  = 'FRCST3D_SST'
variable_nameSST_new[3]  = 'FRCST5D_SST'
variable_nameSST_new[4]  = 'FRCST7D_SST'
variable_nameSST_new[5]  = 'FRCST9D_SST'
variable_nameSST_new[6]  = 'PERS1D_SST'
variable_nameSST_new[7]  = 'PERS3D_SST'
variable_nameSST_new[8]  = 'PERS5D_SST'
variable_nameSST_new[9]  = 'PERS7D_SST'
variable_nameSST_new[10]  = 'PERS9D_SST'
variable_nameSST_new[11]  = 'CLIM_SST'

variable_nameSLA     = np.chararray(8,itemsize=25)
variable_nameSLA[0]  = 'BEST_SLA'
variable_nameSLA[1]  = 'FRCST1D_SLA'
variable_nameSLA[2]  = 'FRCST3D_SLA'
variable_nameSLA[3]  = 'FRCST5D_SLA'
variable_nameSLA[4]  = 'PERS1D_SLA'
variable_nameSLA[5]  = 'PERS3D_SLA'
variable_nameSLA[6]  = 'PERS5D_SLA'
variable_nameSLA[7]  = 'CLIM_SLA'

variable_nameSLA_new = np.chararray(12,itemsize=25)
variable_nameSLA_new[0]  = 'BEST_SLA'
variable_nameSLA_new[1]  = 'FRCST1D_SLA'
variable_nameSLA_new[2]  = 'FRCST3D_SLA'
variable_nameSLA_new[3]  = 'FRCST5D_SLA'
variable_nameSLA_new[4]  = 'FRCST7D_SLA'
variable_nameSLA_new[5]  = 'FRCST9D_SLA'
variable_nameSLA_new[6]  = 'PERS1D_SLA'
variable_nameSLA_new[7]  = 'PERS3D_SLA'
variable_nameSLA_new[8]  = 'PERS5D_SLA'
variable_nameSLA_new[9]  = 'PERS7D_SLA'
variable_nameSLA_new[10]  = 'PERS9D_SLA'
variable_nameSLA_new[11]  = 'CLIM_SLA'

variable_nameCHL= np.chararray(2,itemsize=25)
variable_nameCHL[0]  = 'HDCT_CHL'
variable_nameCHL[1]  = 'FCST_CHL'

variable_nameS     = np.chararray(8,itemsize=25)
variable_nameS[0]  = 'BEST_PSAL'
variable_nameS[1]  = 'FRCST1D_PSAL'
variable_nameS[2]  = 'FRCST3D_PSAL'
variable_nameS[3]  = 'FRCST5D_PSAL'
variable_nameS[4]  = 'PERS1D_PSAL'
variable_nameS[5]  = 'PERS3D_PSAL'
variable_nameS[6]  = 'PERS5D_PSAL'
variable_nameS[7]  = 'CLIM_PSAL'

variable_nameS_new = np.chararray(12,itemsize=25)
variable_nameS_new[0]  = 'BEST_PSAL'
variable_nameS_new[1]  = 'FRCST1D_PSAL'
variable_nameS_new[2]  = 'FRCST3D_PSAL'
variable_nameS_new[3]  = 'FRCST5D_PSAL'
variable_nameS_new[4]  = 'FRCST7D_PSAL'
variable_nameS_new[5]  = 'FRCST9D_PSAL'
variable_nameS_new[6]  = 'PERS1D_PSAL'
variable_nameS_new[7]  = 'PERS3D_PSAL'
variable_nameS_new[8]  = 'PERS5D_PSAL'
variable_nameS_new[9]  = 'PERS7D_PSAL'
variable_nameS_new[10] = 'PERS9D_PSAL'
variable_nameS_new[11] = 'CLIM_PSAL'

## Definition des tables de profondeur
tab_prof    = np.zeros(7)
tab_prof[0] = 0.
tab_prof[1] = 5.
tab_prof[2] = 100.
tab_prof[3] = 300.
tab_prof[4] = 800.
tab_prof[5] = 2000.
tab_prof[6] = 5000.

tab_prof_2    = np.zeros(8)
tab_prof_2[0] = 0.
tab_prof_2[1] = 50.
tab_prof_2[2] = 100.
tab_prof_2[3] = 150.
tab_prof_2[4] = 200.
tab_prof_2[5] = 300.
tab_prof_2[6] = 400.
tab_prof_2[7] = 500.

tab_prof_3    = np.zeros(3)
tab_prof_3[0] = 0.
tab_prof_3[1] = 100.
tab_prof_3[2] = 500.

tab_prof_model     = np.zeros(51)
tab_prof_model[0]  = 0.4940254
tab_prof_model[1]  = 1.541375
tab_prof_model[2]  = 2.645669
tab_prof_model[3]  = 3.819495
tab_prof_model[4]  = 5.078224
tab_prof_model[5]  = 6.440614
tab_prof_model[6]  = 7.929560
tab_prof_model[7]  = 9.572997
tab_prof_model[8]  = 11.40500
tab_prof_model[9]  = 13.46714
tab_prof_model[10] = 15.81007
tab_prof_model[11] = 18.49556
tab_prof_model[12] = 21.59882
tab_prof_model[13] = 25.21141
tab_prof_model[14] = 29.44473
tab_prof_model[15] = 34.43415
tab_prof_model[16] = 40.34405
tab_prof_model[17] = 47.37369
tab_prof_model[18] = 55.76429
tab_prof_model[19] = 65.80727
tab_prof_model[20] = 77.85385
tab_prof_model[21] = 92.32607
tab_prof_model[22] = 109.7293
tab_prof_model[23] = 130.6660
tab_prof_model[24] = 155.8507
tab_prof_model[25] = 186.1256
tab_prof_model[26] = 222.4752
tab_prof_model[27] = 266.0403
tab_prof_model[28] = 318.1274
tab_prof_model[29] = 380.2130
tab_prof_model[30] = 453.9377
tab_prof_model[31] = 541.0889
tab_prof_model[32] = 643.5668
tab_prof_model[33] = 763.3331
tab_prof_model[34] = 902.3393
tab_prof_model[35] = 1062.440
tab_prof_model[36] = 1245.291
tab_prof_model[37] = 1452.251
tab_prof_model[38] = 1684.284
tab_prof_model[39] = 1941.893
tab_prof_model[40] = 2225.078
tab_prof_model[41] = 2533.336
tab_prof_model[42] = 2865.703
tab_prof_model[43] = 3220.820
tab_prof_model[44] = 3597.032
tab_prof_model[45] = 3992.484
tab_prof_model[46] = 4405.224
tab_prof_model[47] = 4833.291
tab_prof_model[48] = 5274.784
tab_prof_model[49] = 5727.917
tab_prof_model[50] = 5727.917

tab_e3t     = np.zeros(51)
tab_e3t[0]  = 1.02248397350079
tab_e3t[1]  = 1.07392811351213
tab_e3t[2]  = 1.13674814359675
tab_e3t[3]  = 1.21345584707222
tab_e3t[4]  = 1.30711575048712
tab_e3t[5]  = 1.42146584903565
tab_e3t[6]  = 1.56106425198585
tab_e3t[7]  = 1.73146709254409
tab_e3t[8]  = 1.93944403877130
tab_e3t[9]  = 2.19323886239145
tab_e3t[10] = 2.50288375576515
tab_e3t[11] = 2.88057739611743
tab_e3t[12] = 3.34113806593193
tab_e3t[13] = 3.90254431853426
tab_e3t[14] = 4.58657651299428
tab_e3t[15] = 5.41957269345142
tab_e3t[16] = 6.43331123889259
tab_e3t[17] = 7.66602969916604
tab_e3t[18] = 9.16358317214816
tab_e3t[19] = 10.9807349566401
tab_e3t[20] = 13.1825550269287
tab_e3t[21] = 15.8458755786651
tab_e3t[22] = 19.0607145156183
tab_e3t[23] = 22.9315242134296
tab_e3t[24] = 27.5780518324723
tab_e3t[25] = 33.1355086584035
tab_e3t[26] = 39.7536438697515
tab_e3t[27] = 47.5942154497487
tab_e3t[28] = 56.8262730452722
tab_e3t[29] = 67.6186565548615
tab_e3t[30] = 80.1292298269766
tab_e3t[31] = 94.4906811968493
tab_e3t[32] = 110.793290979986
tab_e3t[33] = 129.065899882335
tab_e3t[34] = 149.257319370698
tab_e3t[35] = 171.221369079087
tab_e3t[36] = 194.709234040142
tab_e3t[37] = 219.372494549893
tab_e3t[38] = 244.778740101692
tab_e3t[39] = 270.439259898308
tab_e3t[40] = 295.845505450107
tab_e3t[41] = 320.508765959858
tab_e3t[42] = 343.996630920912
tab_e3t[43] = 365.960680629302
tab_e3t[44] = 386.152100117665
tab_e3t[45] = 404.424709020014
tab_e3t[46] = 420.727318803151
tab_e3t[47] = 435.088770173023
tab_e3t[48] = 447.599343445138
tab_e3t[49] = 458.391726954728
tab_e3t[50] = 5957.95745287756

profondeur    = np.chararray(6,itemsize=25)
profondeur[0] = '0-5m'
profondeur[1] = '5-100m'
profondeur[2] = '100-500m'
profondeur[3] = '500-2000m'
profondeur[4] = '2000-5000m'
profondeur[5] = '0-6000m'

profondeur2    = np.chararray(8,itemsize=25)
profondeur2[0] = '0-50m'
profondeur2[1] = '50-100m'
profondeur2[2] = '100-150m'
profondeur2[3] = '150-200m'
profondeur2[4] = '200-300m'
profondeur2[5] = '300-400m'
profondeur2[6] = '400-500m'
profondeur2[7] = '0-500m'

#profondeur3    = np.chararray(3,itemsize=25)
#profondeur3[0] = '0-100m'
#profondeur3[1] = '100-500m'
#profondeur3[2] = '0-500m'

profondeur3    = np.chararray(5,itemsize=25)
profondeur3[0] ='0-5m'
profondeur3[1] ='5-100m'
profondeur3[2] ='100-500m'
profondeur3[3] ='500-2000m'
profondeur3[4] ='0-2000m'

profondeur_surf  = np.chararray(1,itemsize=25)
profondeur_surf[0] = '0-0m'

## Zones CLASS1
liste_zone     = np.chararray(14,itemsize=25)
liste_zone[0]  = 'ACC'
liste_zone[1]  = 'ARC'
liste_zone[2]  = 'GLO'
liste_zone[3]  = 'IND'
liste_zone[4]  = 'MED'
liste_zone[5]  = 'NAT'
liste_zone[6]  = 'NPA'
liste_zone[7]  = 'SAT'
liste_zone[8]  = 'SPA'
liste_zone[9]  = 'TAT'
liste_zone[10] = 'TPA'
liste_zone[11] = 'NORDSEA'
liste_zone[12] = 'FACADE'
liste_zone[13] = 'BALTIC'

cla_areasattr = np.chararray(14,itemsize=25)
cla_areasattr[0]  = 'Antarctic Circumpolar'
cla_areasattr[1]  = 'Arctic Ocean'
cla_areasattr[2]  = 'Iberian Biscay Irish'
cla_areasattr[3]  = 'Full Domain'
cla_areasattr[4]  = 'Indian Ocean'
cla_areasattr[5]  = 'Mediterranean Sea'
cla_areasattr[6]  = 'North Atlantic Ocean'
cla_areasattr[7]  = 'North Sea'
cla_areasattr[8]  = 'North Pacific Ocean'
cla_areasattr[9]  = 'South Atlantic Ocean'
cla_areasattr[10] = 'South Pacific Ocean'
cla_areasattr[11] = 'Tropical Atlantic Ocean'
cla_areasattr[12] = 'Tropical Pacific Ocean'
cla_areasattr[13] = 'Baltic Sea'

cla_areas2 = np.chararray(1,itemsize=25)
cla_areas2[0]  = 'GLO'
cla_areasattr2 = np.chararray(1,itemsize=25)
cla_areasattr2[0]  = 'Full Domain'

## Zones CLASS1 GLO Myo
liste_zone_GLOMyo    = np.chararray(8,itemsize=25)
liste_zone_GLOMyo[0] = 'ACC'
liste_zone_GLOMyo[1] = 'ARC'
liste_zone_GLOMyo[2] = 'GLO'
liste_zone_GLOMyo[3] = 'IND'
liste_zone_GLOMyo[4] = 'NPA'
liste_zone_GLOMyo[5] = 'SAT'
liste_zone_GLOMyo[6] = 'SPA'
liste_zone_GLOMyo[7] = 'TPA'

### Zones PSY2
liste_zone_PSY2    = np.chararray(6,itemsize=25)
liste_zone_PSY2[0] = 'NAT'
liste_zone_PSY2[1] = 'MED'
liste_zone_PSY2[2] = 'TAT'
liste_zone_PSY2[3] = 'NORDSEA'
liste_zone_PSY2[4] = 'FACADE'
liste_zone_PSY2[5] = 'ATL12'

## Zones PSY2_SHOM
liste_zone_PSY2_SHOM    = np.chararray(9,itemsize=25)
liste_zone_PSY2_SHOM[0] = 'Indien_Nord_Ouest'
liste_zone_PSY2_SHOM[7] = 'Atl_Nord_Est'
liste_zone_PSY2_SHOM[1] = 'Atl_Nord_Ouest'
liste_zone_PSY2_SHOM[1] = 'IBI36'
liste_zone_PSY2_SHOM[2] = 'Norvege'
liste_zone_PSY2_SHOM[3] = 'Atl_Trop'
liste_zone_PSY2_SHOM[4] = 'Atl_Trop_Guinee'
liste_zone_PSY2_SHOM[5] = 'Medit_Ouest'
#liste_zone_PSY2_SHOM[6] = 'Medit_Est'
liste_zone_PSY2_SHOM[6] = 'Indien_Est'
liste_zone_PSY2_SHOM[8] = 'Indien_Sud_Ouest'

## zone TEST
liste_TEST    = np.chararray(1,itemsize=25)
liste_TEST[0] = 'BALTIC'
## MODELES
listemodele    = np.chararray(4,itemsize=25)
listemodele[0] = 'PSY3V2R2'
listemodele[1] = 'PSY2V3R1'
listemodele[2] = 'WOA05'
listemodele[3] = 'FOAM'

## Zones IND
liste_zone_IND    = np.chararray(3,itemsize=25)
liste_zone_IND[0] = 'NAT'
liste_zone_IND[1] = 'MED'
liste_zone_IND[2] = 'TAT'

#Ecarts a la clim critiques
rg_EcartSalMax=1.
rg_EcartTempMax=8.
rg_EcartSLAMax=1.

cla_metricname =  np.chararray(6,itemsize=25)
cla_metricname[0] = 'number of data values'
cla_metricname[1] = 'mean of reference'
cla_metricname[2] = 'mean squared reference'
cla_metricname[3] = 'mean of product'
cla_metricname[4] = 'mean squared product'
cla_metricname[5] = 'mean squared error'
