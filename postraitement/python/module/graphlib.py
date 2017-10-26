"""
---------------------------------------------------------------------------
 Module pour elaborer des graphiques 
---------------------------------------------------------------------------
"""
import pylab as pl
import scipy.signal as sig
import numpy as np
import os, sys
import netCDF4

from scipy.stats import cumfreq
import datetime

import matplotlib.pyplot as plt
import matplotlib.colors as col
import matplotlib.axis as xax
import matplotlib.cm as cmx
import matplotlib.dates as mdates
from matplotlib.patches import Polygon
from mpl_toolkits.basemap import Basemap
from PIL import Image
#import Image
sys.path.append('/home/cregnier/DEV/TEP_CLASS4_GODAE/postraitement/CL4_GODAE_LIB/TOOLS_py')
import arithm
import MOcast

dirdata          = '/data/rd_exchange/lzawadzki/Kourou/data'
logo='/home/lzawadzki/Documents/Rapports/CompteRendu_Stage2012/Images/logo_mercator_ocean.png'

#------------------------------------------------------------------------------------------------------------------------------------------
def loadzones( czoneFile ) :

	try :	rla_zones = np.loadtxt(czoneFile)  #lammin,phimin,lammax,phimax
	except : 
		print 'Could not load %s' %czoneFile
		sys.exit(1)
	
	rla_lons  = np.zeros_like(rla_zones)
	rla_lats  = np.zeros_like(rla_zones)
	for (iz,rla_subzone) in enumerate(rla_zones) :
		
		rla_lons[iz,:] = [rla_subzone[0],rla_subzone[0],\
				rla_subzone[2],rla_subzone[2]]
		rla_lats[iz,:] = [rla_subzone[1],rla_subzone[3],\
				rla_subzone[3],rla_subzone[1]]
	return rla_lons,rla_lats

	

def draw_colorPolyOnMap( rla_lats, rla_lons, rla_values, vmin, vmax, m, ax,cmap='jet'):

	x, y = m( rla_lons, rla_lats )
	xy = zip(x,y)
	colorVal = vals2color(rla_values,vmin=vmin,vmax=vmax,cmap=cmap)
	poly = Polygon( xy, facecolor=colorVal, alpha=0.6 )
	plt.gca().add_patch(poly)

def vals2color(rla_values,vmax='max',vmin='min',cmap='jet') :

        if vmax == 'max' : vmax = max(rla_values)
        if vmin == 'min' : vmin = min(rla_values)
        rla_index = np.round(np.multiply(rla_values-vmin,256/(vmax-vmin)))
        cm = plt.get_cmap(cmap)
        cNorm  = col.Normalize(vmin=0, vmax=255)
        scalarMap = cmx.ScalarMappable(norm=cNorm, cmap=cm)

        colorVal = scalarMap.to_rgba(rla_index)
        return colorVal

	
#-----------------------------------------------------------------------------------------------------------------------------------------

def palettefile2cmap(file,cmap_name) :

	# read file	
	pal = np.loadtxt(file)
	read_red   = pal[:,0]
	read_green = pal[:,1]
	read_blue  = pal[:,2]

	L = read_red.shape[0]
	read_red   = read_red / (L-1)
	read_green = read_green / (L-1)
	read_blue  = read_blue / (L-1)
	
	#interval
	rl_interv = np.linspace(0.,1.,L).reshape(-1,1)
	#red
	rl_redc = np.array(read_red).reshape(-1,1)*np.ones(2,)
	rl_red = np.concatenate((rl_interv,rl_redc),axis=1)
	#green
	rl_greenc = np.array(read_green).reshape(-1,1)*np.ones(2,)
	rl_green  = np.concatenate((rl_interv,rl_greenc),axis=1)
	#blue
	rl_bluec = np.array(read_blue).reshape(-1,1)*np.ones(2,)
	rl_blue = np.concatenate((rl_interv,rl_bluec),axis=1)
	
	cdict = {'red': rl_red, 'green': rl_green, 'blue':rl_blue}
	cmap1 = col.LinearSegmentedColormap(cmap_name,cdict,N=256)
	return cmap1

#-----------------------------------------------------------------------------------------------------------------------------------------

def plotTimeSerie(rla_datetime,rla_values,
		  title=None,ylim=None,
		  scale_factor=1.,filter=False,Norder=5,
		  coPeriod=8.,linestyle='-') :
	
	if np.ndim(rla_datetime) != 1 :
		print 'datetime input dimension unexpected'
	if np.ndim(rla_values) != 1 :
		print 'values input dimension unexpected'
	
	if scale_factor != 1 :
		rla_values = np.multiply(rla_values,scale_factor)

	if type(ylim) in [np.ndarray,list,tuple] :
		if not len(ylim) == 2 :
			print 'ylim parameter filled uncorrectly : ylim = %s' %ylim
			sys.exit(1)

	rla_values = [m for (d,m) in sorted(zip(rla_datetime,rla_values))]
	rla_datetime.sort()
	rla_datetime = MOcast.chardate2datetime(rla_datetime)

	fig = plt.figure()
	fig.set_size_inches(18.5,10.5)
	ax = fig.add_subplot(111)
	plt.xticks(rotation=25)
	if len(rla_datetime) <= 15 :
		formatter = mdates.DateFormatter('%d %b %y')
		ax.xaxis.set_major_formatter(formatter)
		ax.xaxis.set_major_locator(mdates.DayLocator())
	elif len(rla_datetime) <= 31 :
		formatter = mdates.DateFormatter('%d %b %y')
		ax.xaxis.set_major_formatter(formatter)
		ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=0))
	elif len(rla_datetime) <= 366 :
		formatter = mdates.DateFormatter('%b %y')
		ax.xaxis.set_major_formatter(formatter)
		ax.xaxis.set_major_locator(mdates.MonthLocator())
	elif len(rla_datetime) >  366 :
		formatter = mdates.DateFormatter('%b %y')
		ax.xaxis.set_major_formatter(formatter)
		ax.xaxis.set_major_locator(date.YearLocator())
	ax.set_color_cycle(('g','b','r','k'))
	ax.plot_date(rla_datetime,rla_values,color='green',linestyle=linestyle,label='Original')

	if filter :
		ila_chkNaN = np.where(np.isnan(rla_values))[0]
		for il_chkNaN in ila_chkNaN :
			if type(rla_values) == np.ndarray :
				rla_values = rla_values.tolist()
			rla_values.pop(il_chkNaN)
			if type(rla_datetime) == np.ndarray :
				rla_datetime = rla_datetime.tolist()
			rla_datetime.pop(il_chkNaN)
		B,A = sig.butter(5,1/coPeriod)
		rla_filtVal = sig.filtfilt(B,A,rla_values)
		ax.plot_date(rla_datetime,rla_filtVal,color='blue',linestyle='-',label='Filtered')
	
	ax.xaxis_date()
	ax.autoscale_view()
	plt.setp( plt.gca().get_xticklabels(), rotation=45, horizontalalignment='right')
	if not title == None :
		try : ax.set_title(title)
		except : pass
	if not ylim == None :
		try : ax.set_ylim((ylim[0],ylim[1]))
		except : pass
	

	return ax

def design_mapfnc(cl_fileIn,cvar='ErrorDist',clon='longitude',clat='latitude',lonlim=[-180,180],latlim=[-90,90],clim=[0,200],colormap='cmapPerso') :
	
	nc   = netCDF4.Dataset(cl_fileIn,'r')
	lons = np.squeeze(nc.variables[clon][:])
	lats = np.squeeze(nc.variables[clat][:])
	rla_val = np.squeeze(nc.variables[cvar][:])
	if len(rla_val.shape) > 2 : 
		print 'variable %s has too many dimensions (%i)' %(cvar,len(rla_val.shape))
		sys.exit(1)
	if len(rla_val.shape) == 2 : 
		if (np.array(rla_val.shape)==1).any() :
			imaxdim= np.argsort(rla_val.shape)[-1]
		else :
			print 'variable %s has 2 dimensions of length > 1 (%s)' %(cvar,rla_val.shape)
			sys.exit(1)
		if imaxdim == 0 :
			rla_val = rla_val[:,0]
		else :
			rla_val = rla_val[0,:]
	else :
		rla_val = rla_val[:]
	
	nc.close()

	fig = plt.figure()
	ax = fig.add_subplot(111)	
	m = Basemap(llcrnrlon=lonlim[0],llcrnrlat=latlim[0],urcrnrlon=lonlim[1],urcrnrlat=latlim[1],\
            projection='cyl',ax=ax)
	parallels = np.arange(latlim[0],latlim[1],30.)
	#m.drawmapboundary(fill_color='black')
	#m.fillcontinents(color='white')
	m.bluemarble(scale=0.4)
	# labels = [left,right,top,bottom]
	m.drawparallels(parallels,labels=[False,True,True,False])
	meridians = np.arange(lonlim[0],lonlim[1],30.)
	m.drawmeridians(meridians,labels=[True,False,False,True])
	
	if colormap == 'cmapPerso' :
		cmapName = 'cmapPerso'
		cmapfile = os.path.join(dirdata,'CMAPS/palette_stddev_noextrem.txt')
		colormap = palettefile2cmap(cmapfile,cmapName)

	s = cmx.ScalarMappable(cmap=colormap)
	s.set_array(rla_val)
	s.set_clim(clim[0],clim[1])

	x, y = m(lons, lats)
        colorVal = vals2color(rla_val,vmin=clim[0],vmax=clim[1],cmap=colormap)
        im = m.scatter(x,y,color=colorVal)
	cb = plt.colorbar(s,orientation="vertical",format='%4.2f',pad=0.1,shrink=0.5)
	cb.ax.set_ylabel(cvar, fontsize=12)
        add_MOlogo(fig,logo)

	return ax,cb
#------------------------------------------------------------------------------------------------------------------------------------------
def design_diffmapfnc(cl_fileIn,cvar=['SST_OBS','SST_Hx'],clon='longitude',clat='latitude',lonlim=[-180,180],latlim=[-90,90],clim=[-50,50],colormap='cmapPerso') :
	
	nc   = netCDF4.Dataset(cl_fileIn,'r')
	lons = np.squeeze(nc.variables[clon][:])
	lats = np.squeeze(nc.variables[clat][:])
	rla_val0 = np.squeeze(nc.variables[cvar[0]][:])
	rla_val1 = np.squeeze(nc.variables[cvar[1]][:])
	if len(rla_val0.shape) > 2 : 
		print 'variable %s has too many dimensions (%i)' %(cvar[0],len(rla_val0.shape))
		sys.exit(1)
	if len(rla_val1.shape) > 2 : 
		print 'variable %s has too many dimensions (%i)' %(cvar[1],len(rla_val1.shape))
		sys.exit(1)
	if len(rla_val0.shape) == 2 : 
		if (np.array(rla_val0.shape)==1).any() :
			imaxdim= np.argsort(rla_val0.shape)[-1]
		else :
			print 'variable %s has 2 dimensions of length > 1 (%s)' %(cvar[0],rla_val0.shape)
			sys.exit(1)
		if imaxdim == 0 :
			rla_val0 = rla_val0[:,0]
		else :
			rla_val0 = rla_val0[0,:]
	else :
		rla_val0 = rla_val0[:]

	if len(rla_val1.shape) == 2 : 
		if (np.array(rla_val1.shape)==1).any() :
			imaxdim= np.argsort(rla_val1.shape)[-1]
		else :
			print 'variable %s has 2 dimensions of length > 1 (%s)' %(cvar[1],rla_val1.shape)
			sys.exit(1)
		if imaxdim == 0 :
			rla_val1 = rla_val1[:,0]
		else :
			rla_val1 = rla_val1[0,:]
	else :
		rla_val1 = rla_val1[:]
	
	nc.close()
	
	fig = plt.figure()
	ax = fig.add_subplot(111)	
	m = Basemap(\
            projection='ortho',lat_0=90,lon_0=0,resolution='l',ax=ax)
	#m = Basemap(llcrnrlon=lonlim[0],llcrnrlat=latlim[0],urcrnrlon=lonlim[1],urcrnrlat=latlim[1],\
        #    projection='cyl',ax=ax)
	#m.drawmapboundary(fill_color='black')
	#m.fillcontinents(color='white')
	m.bluemarble(scale=0.4)
	# labels = [left,right,top,bottom]
	parallels = np.arange(latlim[0],latlim[1],30.)
	m.drawparallels(parallels,labels=[False,True,True,False])
	meridians = np.arange(lonlim[0],lonlim[1],30.)
	m.drawmeridians(meridians,labels=[True,False,False,True])
	
	if colormap == 'cmapPerso' :
		cmapName = 'cmapPerso'
		cmapfile = os.path.join(dirdata,'CMAPS/palette_centree_noextrem.txt')
		colormap = palettefile2cmap(cmapfile,cmapName)
	rla_diff = rla_val0 - rla_val1
	s = cmx.ScalarMappable(cmap=colormap)
	s.set_array(rla_diff)
	s.set_clim(clim[0],clim[1])

	x, y = m(lons, lats)
        colorVal = vals2color(rla_diff,vmin=clim[0],vmax=clim[1],cmap=colormap)
        im = m.scatter(x,y,color=colorVal)
	cb = plt.colorbar(s,orientation="vertical",format='%4.2f',pad=0.1,shrink=0.5)
	cb.ax.set_ylabel('%s - %s' %(cvar[0],cvar[1]), fontsize=12)
	fig.set_size_inches(18.5,10.5)
        add_MOlogo(fig,logo)

	return ax,cb
#------------------------------------------------------------------------------------------------------------------------------------------
def add_MOlogo(fig,logo,scale=1 ) :
	im = Image.open(logo)
	height = im.size[1]
	width = im.size[0]
	## We need a float array between 0-1, rather than
	## a uint8 array between 0-255
	im=im.resize((width/scale,height/scale))
	im = np.array(im).astype(np.float) / 255
	fig.figimage(im, width/10, height/10,zorder=10)

#------------------------------------------------------------------------------------------------------------------------------------------
def make_Basemap():

	fig = plt.figure()
	m = Basemap(projection='cyl',resolution=None)
	m.drawmeridians(np.arange(m.lonmin,m.lonmax+30,60),labels=[0,0,0,1])
	m.drawparallels(np.arange(m.latmin,m.latmax+30,30),labels=[1,0,0,0])
	m.bluemarble(scale=0.5)
	fig.set_size_inches(18.5,10.5)

	return m


def design_multimapfnc(cl_fileIn,cvar='ErrorDist',clon='longitude',clat='latitude',lonlim=[-180,180],latlim=[-90,90],clim=[0,200],colormap='cmapPerso') :
	
	nc   = netCDF4.Dataset(cl_fileIn,'r')
	lons = np.squeeze(nc.variables[clon][:])
	lats = np.squeeze(nc.variables[clat][:])
	rla_val = np.squeeze(nc.variables[cvar][:])
	if len(rla_val.shape) > 2 : 
		print 'variable %s has too many dimensions (%i)' %(cvar,len(rla_val.shape))
		sys.exit(1)
	if len(rla_val.shape) == 2 : 
		if (np.array(rla_val.shape)==1).any() :
			imaxdim= np.argsort(rla_val.shape)[-1]
		else :
			print 'variable %s has 2 dimensions of length > 1 (%s)' %(cvar,rla_val.shape)
			sys.exit(1)
		if imaxdim == 0 :
			rla_val = rla_val[:,0]
		else :
			rla_val = rla_val[0,:]
	else :
		rla_val = rla_val[:]
	
	nc.close()

	fig, axes = plt.subplots(nrows=2, ncols=2)
	#fig = plt.figure()
	#ax1 = fig.add_subplot(221)	
	#ax2 = fig.add_subplot(222)	
	#ax3 = fig.add_subplot(223)	
	#ax4 = fig.add_subplot(224)	
	#axes = [ax1,ax2,ax3,ax4]
	lats0 = [90,45,-45,-90]
	lons0 = [0,0,-100,0]
	for ax,lat_0,lon_0 in zip(axes.flat,lats0,lons0) :
		m = Basemap(lat_0=lat_0,lon_0=lon_0,projection='ortho',ax=ax)
		parallels = np.arange(latlim[0],latlim[1],30.)
		#m.drawmapboundary(fill_color='black')
		#m.fillcontinents(color='white')
		m.bluemarble(scale=0.4)
		# labels = [left,right,top,bottom]
		m.drawparallels(parallels,labels=[False,True,True,False])
		meridians = np.arange(lonlim[0],lonlim[1],30.)
		m.drawmeridians(meridians,labels=[True,False,False,True])
		
		if colormap == 'cmapPerso' :
			cmapName = 'cmapPerso'
			cmapfile = os.path.join(dirdata,'CMAPS/palette_stddev_noextrem.txt')
			colormap = palettefile2cmap(cmapfile,cmapName)

		s = cmx.ScalarMappable(cmap=colormap)
		s.set_array(rla_val)
		s.set_clim(clim[0],clim[1])

		x, y = m(lons, lats)
        	colorVal = vals2color(rla_val,vmin=clim[0],vmax=clim[1],cmap=colormap)
        	im = m.scatter(x,y,color=colorVal,s=20)
	fig.subplots_adjust(right=0.8)
	cbar_ax = fig.add_axes([0.85, 0.15, 0.05, 0.7])
	cb = fig.colorbar(s,orientation="vertical",format='%4.2f',cax=cbar_ax)
	cb.ax.set_ylabel(cvar, fontsize=12)
     	#add_MOlogo(fig,logo)

