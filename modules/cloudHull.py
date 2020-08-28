import numpy as np
from scipy.spatial import Delaunay
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection

def cloudHull(rla_points) :
	#rla_points = np.multiply(360,np.random.rand(600, 2))
	tri = Delaunay(rla_points)
	
	# Make a list of line segments: 
	# edge_lines = [ ((x1_1, y1_1), (x2_1, y2_1)),
	#                 ((x1_2, y1_2), (x2_2, y2_2)),
	#                 ... ]
	edge_lines = []
	
	def add_edge(i, j):
		"""Add a line between the i-th and j-th points, if not in the list already"""
		edges = set()
		if (i, j) in edges or (j, i) in edges:
			# already added
			return
		edges.add( (i, j) )
		edge_lines.append(rla_points[ [i, j] ])
	
	
	# loop over triangles: 
	# ia, ib, ic = indices of corner points of the triangle
	for ia, ib, ic in tri.vertices:
		add_edge(ia, ib)
		add_edge(ib, ic)
		add_edge(ic, ia)
		
	# plot it: the LineCollection is just a (maybe) faster way to plot lots of
	# lines at once
	print np.shape(edge_lines)
	lines = LineCollection(edge_lines,colors='blue')
	plt.figure()
	plt.gca().add_collection(lines)
	plt.plot(rla_points[:,0], rla_points[:,1], 'o', hold=1)
	#plt.xlim(-1, 2)
	#plt.ylim(-1, 2)
	plt.ion()
	
	
	## -- the same stuff for the convex hull
	##
	edge_lines = []
	
	for ia, ib in tri.convex_hull:
	    add_edge(ia, ib)
	
	lines = LineCollection(edge_lines,colors='red')
	plt.gca().add_collection(lines)
	
	#compute area of the polygon
	area = 0.
	for triangle in tri.vertices :
		v1 = rla_points[triangle[1]]- rla_points[triangle[0]]
		v2 = rla_points[triangle[2]]- rla_points[triangle[0]]
		area += abs(np.cross(v1,v2))
	area /= 2.
	plt.title('Delaunay triangulation \n area = %f' %area)
	plt.draw()
	return edge_lines
