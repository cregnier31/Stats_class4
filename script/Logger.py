import logging
## Log wrapper
# Creation C.REGNIER Juillet 2014

class Logger(object):
      def __init__(self,name) :  
	 self.name=name
      def run(self,level):
	 logging.basicConfig(format='%(asctime)s %(message)s')
	 log = logging.getLogger(self.name)
         ## Level of logging output
	 if level == 0 :
            log.setLevel(logging.NOTSET)
	 elif level == 1 :
            log.setLevel(logging.DEBUG)
	 elif level == 2 :
            log.setLevel(logging.INFO)
	 elif level == 3 :
            log.setLevel(logging.WARNING)
	 elif level == 4 :
            log.setLevel(logging.ERROR)
	 elif level == 5 :
            log.setLevel(logging.CRITICAL)
	 return log
