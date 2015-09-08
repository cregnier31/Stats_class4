### Module utilitaire
import os
def mkdir(path):
     "Create a directory, and parents if needed"
     if not os.path.exists(path):
         os.makedirs(path)

def create_path(year,QUART):
   if int(QUART) == 1 :
      date1=year+"0101"
      date2=year+"0331"
      QM="JFM"
      print "First quarter"
   elif int(QUART) == 2 :
      date1=year+"0401"
      date2=year+"0630"
      QM="AMJ"
      print "Second quarter"
   elif int(QUART) == 3 :
      date1=year+"0701"
      date2=year+"0930"
      QM="JAS"
      print "Third quarter"
   elif int(QUART) == 4 :
      date1=year+"1001"
      date2=year+"1231"
      QM="OND"
      print "Fourth quarter"
   else  :
     print "Bad choice "
     sys.exit(1)
   return date1,date2,QM
