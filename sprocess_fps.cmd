# File: pcap_fps.cmd
# Deposit oxide 400 nm

math coord.ucs

# Grid spacing in the growing region (in cm)
#pdbSet Oxide Grid perp.add.dist 1e-7

# Specify lines for outer boundary and to separate moving 
# boundaries from the rest of the structure
line x location= 0.0
line x location= 5.0<um>

line y location= 0.0	 spac=0.05
line y location= 1.0<um> spac=0.05
 
# --------- Silicon substrate definition ----------------
region Silicon 

# ----------- Initialize simulation ---------------------
init concentration=@Na@ field=Boron wafer.orient=100

# Global Mesh settings for automatic meshing in newly generated layers
# -------------------------------------------------------------
mgoals min.normal.size=1e-3  max.lateral.size=0.5<um> normal.growth.ratio=1.5 accuracy=1e-5

# Grid spacing in the growing region (in cm)
pdbSet Oxide Grid perp.add.dist 1e-7
pdbSet Grid NativeLayerThickness 1e-7

#----------------- Activate dopants -------------------------
diffuse temperature=1000<C> time=30.0<min> N2

deposit material= {Oxide} type=anisotropic thickness=@tox@<nm>
deposit material= {Aluminum} type=anisotropic time=0.5 rate= {1.0}


#---------------- Refinement ------------------

refinebox clear
#line clear

#Adaptive meshing
#pdbSet Grid Adaptive 1
pdbSet Diffuse Growth.Regrid.Steps 4
pdbSet Grid AdaptiveField Refine.Abs.Error 1e37
pdbSet Grid AdaptiveField Refine.Rel.Error 1e10
pdbSet Grid AdaptiveField Refine.Target.Length 100.0
pdbSet Grid SnMesh DelaunayType boxmethod

refinebox name= Oxide \
  min= "-0.5  0.0" max= "0.0   1.0" \
  xrefine= "0.02 0.06"  yrefine= "0.01" Oxide 
   
refinebox name= Sil min= {0.0 0.0} max= {1.0 1.0} xrefine= 0.05 yrefine= 0.1 silicon
  
refinebox name= SiO2_int min.normal.size= 0.1<nm> normal.growth.ratio= 1.3 interface.materials= { Oxide }
 

grid remesh

contact name="substrate" bottom Silicon
contact name="gate" x=-0.5 y=0.5 Aluminum replace point

struct smesh=n@node@

exit

