# -*- Mode: Python -*-
# -*- coding: utf-8 -*-
# vi:si:et:sw=4:sts=4:ts=4
##  Classe time : conversion d'une date et jours juliens
##  et d'un jour julien en une date, plus d'autres fonctions de base
## C.REGNIER Janvier 2010 : Creation
## C.REGNIER Mars 2010    : Modifications sur la nomenclature des fonctions et sur le type de
##                          de retour des fonctions qui deviennent booléennes True or False
import sys
class Time:
        "Classe temporelle pour les Fichiers Mercator"
        
        def __init__(self):
              self.dictANA={ 14 : 'HDCT' , 13 : 'HDCT' , 12 : 'HDCT' , 11 : 'HDCT' , 10 : 'HDCT' , 9 : 'HDCT' , 8 : 'HDCT' , 7  : 'NOW',  6  : 'NOW',  5  : 'NOW',  4  : 'NOW' ,  3 : 'NOW' ,  2  : 'NOW' , 1 : 'NOW' ,  0 : 'FCST1' } 
              self.dictPRE={ 13 : 'FCST2' , 12 : 'FCST2' , 11 : 'FCST2' , 10 : 'FCST2' , 9 : 'FCST2' , 8 : 'FCST2' , 7  : 'FCST2',  6  : 'FCST1',  5  : 'FCST1',  4  : 'FCST1' ,  3 : 'FCST1' ,  2  : 'FCST1' , 1 : 'FCST1' ,  0 : 'FCST1' }      
        def an(self,date_in):
            if isinstance(date_in, str)  :
                return int(date_in[0:4])
            else : 
                print ('La valeur rentree n est pas un string')
                return 0
   
        def mois(self,date_in):
            if isinstance(date_in, str)  :
                return int(date_in[4:6])
            else : 
                print ('La valeur rentree n est pas un string')
                return 0

        def jour(self,date_in):
             if isinstance(date_in, str)  :
                 return int(date_in[6:8]) 
             else : 
                 print ('La valeur rentree n est pas un string')
                 return 0
                                        
        def d2j(self,date_in):
            if isinstance(date_in, str)  :
                if len(date_in) != 8 :
                    print ('!!Warning!! Usage yyymmdd ex: 20080101')
                    sys.exit(1)
                year=int(date_in[0:4])
                month=int(date_in[4:6])
                day=int(date_in[6:8])
                tmpmonth = (12 * year) + month - 3
                tmpyear = tmpmonth / 12
                val=(734 * tmpmonth + 15) / 24 -  2 * tmpyear + tmpyear/4 - tmpyear/100 + tmpyear/400 + day - 712164 
                return val
            else : 
                print ('La valeur rentree n est pas un string')
                return 0
                sys.exit(0)
            
        def j2d(self,date_in):
            if isinstance(date_in, str)  :
                if len(date_in) >= 8 :
                    print ('!!Warning!! Usage yyymmdd ex: 19990')
                    sys.exit(1)
            tmpday = int(date_in) + 712164
            centuries = (4 * tmpday - 1) / 146097
            tmpday = tmpday + (centuries - centuries/4)
            year = (4 * tmpday - 1) / 1461
            tmpday = tmpday -((1461 * year) / 4)
            month = (10 * tmpday - 5) / 306
            day = tmpday - (306 * month + 5) / 10
            month = month +2
            year = year+month/12
            month = month % 12 + 1
            if month < 10 :
                val1=0
                val_month=str(val1)+str(month)
            else :
                val_month=str(month)
            if day  < 10 :
                val1=0
                val_day=str(val1)+str(day)
            else :
                val_day=str(day) 
            
            val=str(year)+val_month+val_day
            return val
            
        def isHindcast(self,fic):
            if isinstance(fic, str)  :
                date_fic=fic.split('_')[2]
                date_ficj=self.d2j(date_fic)
                date_run=fic.split('_')[5].split('.')[0].split('R')[1]
                date_runj=self.d2j(date_run)
                difference=date_runj-date_ficj
                return self.dictANA.get(difference,"valeur indéterminée") == 'HDCT'
            else :
                print ('La valeur rentree n est pas un string')
                return 0
                sys.exit(0)

        def isHindcast_PGS(self,fic):
            if isinstance(fic, str)  :
                date_fic=fic.split('_')[3]
                date_ficj=self.d2j(date_fic)
                date_run=fic.split('_')[4].split('.')[0].split('R')[1]
                date_runj=self.d2j(date_run)
                difference=date_runj-date_ficj
                return self.dictANA.get(difference,"valeur indéterminée") == 'HDCT'
            else :
                print ('La valeur rentree n est pas un string')
                return 0
                sys.exit(0)

        def isNowcast(self,fic):
           if isinstance(fic, str)  :
              date_fic=fic.split('_')[2]
              date_ficj=self.d2j(date_fic)
              date_run=fic.split('_')[5].split('.')[0].split('R')[1]
              date_runj=self.d2j(date_run)
              difference=date_runj-date_ficj
              return self.dictANA.get(difference,"valeur indéterminée") == 'NOW'
           else :
              print ('La valeur rentree n est pas un string')
              return 0
              sys.exit(0)

        def isNowcast_PGS(self,fic):
           if isinstance(fic, str)  :
              date_fic=fic.split('_')[3]
              date_ficj=self.d2j(date_fic)
              date_run=fic.split('_')[4].split('.')[0].split('R')[1]
              date_runj=self.d2j(date_run)
              difference=date_runj-date_ficj
              return self.dictANA.get(difference,"valeur indéterminée") == 'NOW'
           else :
              print ('La valeur rentree n est pas un string')
              return 0
              sys.exit(0)

        def isForecast1(self,fic):
              if isinstance(fic, str)  :
                 date_fic=fic.split('_')[2]
                 date_ficj=self.d2j(date_fic)
                 date_run=fic.split('_')[5].split('.')[0].split('R')[1]
                 date_runj=self.d2j(date_run)
                 difference=date_ficj-date_runj
                 return self.dictPRE.get(difference,"valeur indéterminée") == 'FCST1'
              else :
                 print ('La valeur rentree n est pas un string')
                 return 0
                 sys.exit(0)

        def isForecast2(self,fic):
            if isinstance(fic, str)  :
               date_fic=fic.split('_')[2]
               date_ficj=self.d2j(date_fic)
               date_run=fic.split('_')[5].split('.')[0].split('R')[1]
               date_runj=self.d2j(date_run)
               difference=date_ficj-date_runj
               return self.dictPRE.get(difference,"valeur indéterminée") == 'FCST2'
            else :
                 print ('La valeur rentree n est pas un string')
                 return 0
                 sys.exit(0)

        def isPersistence(self,fic):
            if isinstance(fic, str)  :
               date_fic=fic.split('_')[2]
               date_ficj=self.d2j(date_fic)
               date_run=fic.split('_')[5].split('.')[0].split('R')[1]
               date_runj=self.d2j(date_run)
               difference=date_runj-date_ficj
               return ( difference == 0 and self.dictANA.get(difference,"valeur indéterminée") == 'FCST1')
            else :
                 print ('La valeur rentree n est pas un string')
                 return 0
                 sys.exit(0)

