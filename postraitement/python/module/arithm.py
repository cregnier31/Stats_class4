import numpy as np
import sys
import datetime
from copy import deepcopy

def fillVal2nan(data,fillVal):
    return np.ma.filled(np.ma.masked_array(data,(data==fillVal)), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanmean(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).mean(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nansum(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).sum(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanrms(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).mean(**args), fill_value=np.nan)
    return np.sqrt(out)

#--------------------------------------------------------------------------------------------------
def nanms(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).mean(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nansums(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).sum(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nanrmse(data1,data2, **args):
    data1 = np.array(data1)
    data2 = np.array(data2)
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).mean(**args), fill_value=np.nan)
    return np.sqrt(out)

#--------------------------------------------------------------------------------------------------
def nanmse(data1,data2, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).mean(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nansumse(data1,data2, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).sum(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nanstd(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).std(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanmin(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).min(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanmax(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).max(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanpearson(data1,data2):
	std1   = nanstd(data1)
	std2   = nanstd(data2)
	cov12  = nanmean((data1-nanmean(data1))*(data2 - nanmean(data2)))

	if cov12 == 0 : return 0
	if std1*std2 == 0 : return 1

	return cov12/(std1*std2)	

#--------------------------------------------------------------------------------------------------

def vectorMap(rla_fromVector,rla_toVector,rl_window) :
	""" 
	    The function 'mapVector' maps the positions of similar values
	     (identical values if 'window' is 0) in 
	    
	     Example 1:
	     ...input:
	     window     =  2
	     fromVector =  8 12 16 20
	     toVector   =  6  9 12 15
	     ...output:
	     vectorMap  =  0  2  3 NaN
	     ...explanation:
	        algorithm returns first match in [value-window, value+window]
	    
	     Example 2 (same as 1, but with org. 'toVector[3]' value discarded):
	     ...input:
	     window     =  2
	     fromVector =  8 12 16 20
	     toVector   =  6  9 15
	     ...output:
	     vectorMap  =  0 NaN 2 NaN
	    
	     Example 3 (same as 1, but with 'window' = 1):
	     ...input:
	     window     =  1
	     fromVector =  8 12 16 20
	     toVector   =  6  9 12 15
	     ...output:
	     vectorMap  =  1  2  3 NaN
	    
	     Example 4 (same as 1, but with 'window' = 0):
	     ...input:
	     window     =  0
	     fromVector =  8 12 16 20
	     toVector   =  6  9 12 15
	     ...output:
	     vectorMap  = NaN 2 NaN NaN
	"""

	rla_vectorMap = np.empty(len(rla_fromVector))
	rla_vectorMap[:] = np.nan
	
	# Check that all entries are ascending
	
	ll_fromOk = True
	n = 0
	while (n < len(rla_fromVector)-1 and ll_fromOk) :
		n += 1
		ll_fromOk = (rla_fromVector[n] > rla_fromVector[n-1])
	
	if not ll_fromOk :
		print "mapVector: 'fromVector' not ascending"
		sys.exit(1)
	
	ll_toOk = True
	n = 0
	while (n < len(rla_toVector) -1 and ll_toOk) :
		n += 1
	  	ll_toOk = (rla_toVector[n] > rla_toVector[n-1])
	
	if not ll_toOk :
		print "mapVector: 'toVector' not ascending"
		sys.exit(1)
	
	# 'window' must be non-negative, check:
	if not type(rl_window) == datetime.timedelta :
		if rl_window < 0. : 
			print("mapVector: input 'window'<0; invalid argument")
			sys.exit(1)
	
	# ranges must overlap, check:
	ll_rangeOk = (rla_toVector[0] <= rla_fromVector[-1] + rl_window) and\
	           (rla_toVector[-1] >= rla_fromVector[0] - rl_window)
	
	if not ll_rangeOk :
		print "mapVector: ranges do not overlap"
		return rla_mapVector
	
	# Good to go!
	
	
	# Find first, last relevant element in 'toVector':
	il_toFirst = 0
	while (rla_toVector[il_toFirst] < rla_fromVector[0] - rl_window) : il_toFirst += 1
	il_toLast  = len(rla_toVector) - 1
	while (rla_toVector[il_toLast] > rla_fromVector[-1] + rl_window) : il_toLast -= 1
	
	# Find first, last relevant element in 'fromVector':
	il_fromFirst = 0
	while (rla_fromVector[il_fromFirst] < rla_toVector[0] - rl_window) : il_fromFirst += 1
	il_fromLast  = len(rla_fromVector) - 1
	while (rla_fromVector[il_fromLast] > rla_toVector[-1] + rl_window) : il_fromLast -= 1
	
	#Map!
	if il_fromLast >= il_fromFirst :
		for il_fromN in range(il_fromFirst,il_fromLast+1) :
	    		il_toN  = il_toFirst
	    		while (rla_fromVector[il_fromN] >  rla_toVector[il_toN] + rl_window) : il_toN += 1
			if (rla_fromVector[il_fromN] >= rla_toVector[il_toN] - rl_window) : rla_vectorMap[il_fromN] = il_toN
	
	return rla_vectorMap

#--------------------------------------------------------------------------------------------------

def categorize(ra_Val, ra_limits, ra_catVal) :
	""" 
	> usage : values,distribution = categorize(ra_Val, ra_limits, ra_catVal)
	      where :
		- ra_Val is either a list or a numpy array of values
		- ra_limits is a list or a numpy array with the frontiers
		of X bins (so length of ra_limits is X+1)
		- ra_categorize is a list or a numpy array with the replacement values
		of the ra_Val entries that fall into the bins (so length of ra_catVal is X)

	> brief :
	 The function 'categorize' replaces entries in an input vector
	 with values provided for intervals in input values
	 (may e.g. be used to replace all values in <n*10,(n+1)*10]
	  by n*10+5 for n= 0,1,...,10),
	 and returns a list variable with two vectors:
	  $values:       a vector w/ the new values
	                  (out-of-range values returned unaltered)
	  $distribution: frequency used for each interval (count)
	
	 Example 1:
	 ...input:
	 values         =  8 12 NA  5 20 -1 22  0
	 limits         =  0  5 10 15 20
	 categoryValues =   10 20 30 40
	 ...output:
	  $values       = 20 30 NA 10 40 -1 22 0
	  $distribution =  1  1  1  1
	 ...explanation:
	    algorithm finds the index of the interval in 'limits'
	     (interval 1 is  <limits[1], limits[2]] etc.)
	     and substitutes the value with the corrresponding
	     value in categoryValue
	
	
	 Example 2 (same as 1, but with 'limits[1]' = 'limits[5]' = NA):
	 ...input:
	 values         =  8 12 NA  5 20 -1 22  0
	 limits         = NA  5 10 15 NA
	 categoryValues =   10 20 30 40
	 ...output:
	  $values       = 20 30 NA 10 40 10 40 10
	  $distribution =  3  1  1  2
	
	
	 Example 3 (same as 1, but with 'limits[1]' = NA):
	 ...input:
	 values         =  8 12 NA  5 20 -1 22  0
	 limits         = NA  5 10 15 20
	 categoryValues =   10 20 30 40
	 ...output:
	  $values       = 20 30 NA 10 40 10 22 10
	  $distribution =  3  1  1  1
	
	
	 Example 4 (same as 1, but with 'limits[5]' = NA):
	 ...input:
	 values         =  8 12 NA  5 20 -1 22  0
	 limits         =  0  5 10 15 NA
	 categoryValues =   10 20 30 40
	 ...output:
	  $values       = 20 30 NA 10 40 -1 40  0
	  $distribution =  1  1  1  2
	
	
	 Example 5: replacing all values <=10 with 0
	 ...input:
	 values         =  8 10 NA  5 20 -1 22  0
	 limits         =  NA 10
	 categoryValues =    0
	 ...output:
	  $values       =  0  0 NA  0 20  0 22  0
	  $distribution =  5
	
	
	 Example 6: same as 5, but replacing with NA
	 ...input:
	 values         =  8 10 NA  5 20 -1 22  0
	 limits         =  NA 10
	 categoryValues =   NA
	 ...output:
	  $values       = NA NA NA NA 20 NA 22 NA
	  $distribution =  5
	"""
	
	# Check that limits, categoryValues are OK
	
	nLimits     = len(ra_limits)
	nCategories = len(ra_catVal)

	#ndim of values
	ndim = np.ndim(ra_Val)
	if ndim > 2 :
		print 'input data shape unexpected (2 dims max)'
		sys.exit(1)
	

	# 'limits' must have at least two entries, check:
	if  nLimits <= 1 :
		print "Error in function 'categorize': \
			input 'limits' vector has less than two values"
		sys.exit(1)
	# There must be one more limiting value than #categories, check:
	if nLimits - nCategories != 1 :
		print "Error in function 'categorize': \
			non-matching no. of categories and limits \
			(latter must be one larger than former)"
		sys.exit(1)


	# 'limits' must be ascending, check:
	ra_limits = np.array(ra_limits)
	if (ra_limits[np.isfinite(ra_limits)] != sorted(ra_limits[np.isfinite(ra_limits)])).any() :
		print "Error in function 'categorize': input 'limits' vector is not ascending properly"
                print ra_limits, sorted(ra_limits)
		sys.exit(1)
	
	rla_newVal = deepcopy(ra_Val)
	if ndim == 1 : 
		rla_newVal,rla_distrib = categorize1D(rla_newVal,ra_catVal,ra_limits)
	elif ndim == 2 :
		if np.shape(rla_newVal)[1] == 2 and np.shape(rla_newVal)[0] != 2 :
			rla_newVal = rla_newVal.transpose()
		rla_newVal,rla_distrib = categorize2D(rla_newVal,ra_catVal,ra_limits)


	return rla_newVal,rla_distrib


def categorize1D(rla_newVal,ra_catVal,ra_limits) :

	# Initialize distribution count vector:
	nCategories = len(ra_catVal)
	rla_distrib = np.zeros(nCategories,dtype=np.int)
		
	if (not np.isnan(ra_limits[0])) and (not np.isnan(ra_limits[-1])) :
		#CASE 1 : no NaN in limits
		for n in range(len(rla_newVal)) :
			if (not np.isnan(rla_newVal[n])) and \
			   (rla_newVal[n] > ra_limits[0]) and \
			   (rla_newVal[n] <= ra_limits[-1]) :
				ij = 0
				while (rla_newVal[n] > ra_limits[ij+1]) : ij += 1
				rla_newVal[n] = ra_catVal[ij]
				rla_distrib[ij] += 1  			

	elif (not np.isnan(ra_limits[0])) and (np.isnan(ra_limits[-1])) :
		#CASE 2 : NaN in upper limits only
		for n in range(len(rla_newVal)) :
			if (not np.isnan(rla_newVal[n])) and\
			   (rla_newVal[n] > ra_limits[0]) :
				if rla_newVal[n] > ra_limits[-2] :
					rla_newVal[n] = ra_catVal[-1]
					rla_distrib[-2] += 1
				else :
					ij = 0
					while (rla_newVal[n] > ra_limits[ij+1]) : ij += 1
					rla_newVal[n] = ra_catVal[ij]
					rla_distrib[ij] += 1  			

	elif (np.isnan(ra_limits[0])) and (not np.isnan(ra_limits[-1])) :
		
		# CASE 3: NaN in lower 'limits' only
		for n in range(len(rla_newVal)) :
			if (not np.isnan(rla_newVal[n])) and\
			   (rla_newVal[n] <= ra_limits[-1]) :
				if rla_newVal[n] <= ra_limits[1] :
					rla_newVal[n] = ra_catVal[0]
					rla_distrib[0] += 1
				else :
					ij = 1
					while (rla_newVal[n] > ra_limits[ij+1]) : ij += 1
					rla_newVal[n] = ra_catVal[ij]
					rla_distrib[ij] += 1  			
				
	else :
		# CASE 4 (remaining): NaN in both 'limits'
		for n in range(len(rla_newVal)) :
			if not np.isnan(rla_newVal[n]) :
				if (rla_newVal[n] <= ra_limits[1]) :
					rla_newVal[n] = ra_catVal[0]
					rla_distrib[0] += 1  			
				elif (rla_newVal[n] > ra_limits[-2]) :
					rla_newVal[n] = ra_catVal[-2]
					rla_distrib[-1] += 1  			
				else :
					ij = 1
					while (rla_newVal[n] > ra_limits[ij+1]) : ij += 1
					rla_newVal[n] = ra_catVal[ij]
					rla_distrib[ij] += 1  			
					
	return np.array(rla_newVal),np.array(rla_distrib)
	
#--------------------------------------------------------------------------------------------------
def categorize2D(rla_newVal,ra_catVal,ra_limits) :

	# Initialize distribution count vector:
	nCategories = len(ra_catVal)
	rla_distrib = np.zeros(nCategories,dtype=np.int)

	if (not np.isnan(ra_limits[0])) and (not np.isnan(ra_limits[-1])) :
		#CASE 1 : no NaN in limits
		for ii in range(np.shape(rla_newVal)[0]) :	
			for jj in range(np.shape(rla_newVal)[1]) :
				if (not np.isnan(rla_newVal[ii,jj])) and \
				   (rla_newVal[ii,jj] > ra_limits[0]) and \
				   (rla_newVal[ii,jj] <= ra_limits[-1]) :
					ij = 0
					while (rla_newVal[ii,jj] > ra_limits[ij+1]) : ij += 1
					rla_newVal[ii,jj] = ra_catVal[ij]
					rla_distrib[ij] += 1  			

	elif (not np.isnan(ra_limits[0])) and (np.isnan(ra_limits[-1])) :
		#CASE 2 : NaN in upper 'limits' only
		for ii in range(np.shape(rla_newVal)[0]) :	
			for jj in range(np.shape(rla_newVal)[1]) :
				if (not np.isnan(rla_newVal[ii,jj])) and\
				   (rla_newVal[ii,jj] > ra_limits[0]) :
					if rla_newVal[ii,jj] > ra_limits[-2] :
						rla_newVal[ii,jj] = ra_catVal[-1]
						rla_distrib[-2] += 1
					else :
						ij = 0
						while (rla_newVal[ii,jj] > ra_limits[ij+1]) : ij += 1
						rla_newVal[ii,jj] = ra_catVal[ij]
						rla_distrib[ij] += 1  			

	elif (np.isnan(ra_limits[0])) and (not np.isnan(ra_limits[-1])) :
		# CASE 3: NaN in lower 'limits' only
		for ii in range(np.shape(rla_newVal)[0]) :	
			for jj in range(np.shape(rla_newVal)[1]) :
				if (not np.isnan(rla_newVal[ii,jj])) and\
				   (rla_newVal[ii,jj] <= ra_limits[-1]) :
					if rla_newVal[ii,jj] <= ra_limits[1] :
						rla_newVal[ii,jj] = ra_catVal[0]
						rla_distrib[0] += 1
					else :
						ij = 1
						while (rla_newVal[ii,jj] > ra_limits[ij+1]) : ij += 1
						rla_newVal[ii,jj] = ra_catVal[ij]
						rla_distrib[ij] += 1  			
					
	else :
		# CASE 4 (remaining): NaN in both 'limits'
		for ii in range(np.shape(rla_newVal)[0]) :	
			for jj in range(np.shape(rla_newVal)[1]) :
				if not np.isnan(rla_newVal[ii,jj]) :
					if (rla_newVal[ii,jj] <= ra_limits[1]) :
						rla_newVal[ii,jj] = ra_catVal[0]
						rla_distrib[0] += 1  			
					elif (rla_newVal[ii,jj] > ra_limits[-2]) :
						rla_newVal[ii,jj] = ra_catVal[-2]
						rla_distrib[-2] += 1  			
					else :
						ij = 1
						while (rla_newVal[ii,jj] > ra_limits[ij+1]) : ij += 1
						rla_newVal[ii,jj] = ra_catVal[ij]
						rla_distrib[ij] += 1  			
						
	return np.array(rla_newVal),np.array(rla_distrib)
