Device pcap {

Electrode {
	{ Name="gate" Voltage=0.0 
	   #if  @pSchottky@ == 1 
		Schottky
	   #endif
	workfunction=@workf@ }
	{ Name="substrate" Voltage=0.0 }
}

File{
	Grid = "@tdr@"
    	Parameter = "@parameter@"
	Plot = "@tdrdat@"
	Current = "@plot@"
}


Physics (region="Silicon_1") {
  Recombination(
    SRH( DopingDep )
  )  
  
  HydrogenDiffusion
  	
}

Physics (region="Oxide_1") {
    EffectiveIntrinsicDensity(NoBandGapNarrowing)
    Mobility(ConstantMobility)
    
    Traps (
    (Level Donor Conc=@pTraps@ fromValBand EnergyMid=4.0 material="Oxide")  
    (Level FixedCharge Conc=@pNot@)   
    )
           
       Radiation (
    	##DoseTime=(10, @DoseTime@ )
    	DoseRate=0.0
    )	

    HydrogenDiffusion

}

#if  @pSchottky@ == 1 
    Physics(MaterialInterface = "Aluminum/Oxide") {Schottky}
#endif


Physics(MaterialInterface="Oxide/Silicon") {
	#if  @pHetero@ == 1  
		Heterointerface 
	#endif
	#if  @pThermionic@ == 1  
		eThermionic
		hThermionic
	#endif
	
	HydrogenDiffusion
	
	MSConfigs (
		MSConfig ( Name="SiH" Conc=@SiHConc@ Elimination
			State ( Name="s0" Charge=0 Hydrogen=1 ) 
			State ( Name="s1" Charge=1 Hydrogen=0 )
			State ( Name="s2" Charge=0 Hydrogen=0 )
			State ( Name="s3" Charge=-1 Hydrogen=0 )
			Transition ( Name="tVB1" CEModel("pmi_ce_msc" 0) To="s1" From="s2" Reservoirs("VB"(Particles=+1)))
			Transition ( Name="tVB2" CEModel("pmi_ce_msc" 1) To="s2" From="s1" Reservoirs("VB"(Particles=-1)))
			Transition ( Name="tCB1" CEModel("pmi_ce_msc" 2) To="s3" From="s2" Reservoirs("CB"(Particles=+1)))
			Transition ( Name="tCB2" CEModel("pmi_ce_msc" 3) To="s2" From="s3" Reservoirs("CB"(Particles=-1)))
			Transition ( Name="tH2" CEModel("pmi_ce_msc" 4) To="s0" From="s1" Reservoirs("HydrogenIon"(Particles=-1)) Reservoirs("HydrogenMolecule"(Particles=+1)) )
			Transition ( Name="tH+" CEModel("pmi_ce_msc" 5) To="s1" From="s0" Reservoirs("HydrogenIon"(Particles=+1)) Reservoirs("HydrogenMolecule"(Particles=-1)) )
			Transition ( Name="tH+2" CEModel("pmi_ce_msc" 6) To="s0" From="s3" Reservoirs("HydrogenIon"(Particles=+1))  )
		)
	)	
	
}



Plot{
  RadiationGeneration
  eDensity hDensity
  TotalCurrent/Vector eCurrent/Vector hCurrent/Vector
  eMobility hMobility
  eVelocity hVelocity
  eQuasiFermi hQuasiFermi
  eTemperature Temperature * hTemperature
  ElectricField/Vector Potential SpaceCharge
  Doping DonorConcentration AcceptorConcentration
  SRH Band2Band * Auger
  AvalancheGeneration eAvalancheGeneration hAvalancheGeneration
  eGradQuasiFermi/Vector hGradQuasiFermi/Vector
  eEparallel hEparallel eENormal hENormal
  BandGap EffectiveBandGap
  BandGapNarrowing
  Affinity
  ConductionBand ValenceBand
  eQuantumPotential
  eBarrierTunneling hBarrierTunneling * BarrierTunneling
  eTrappedCharge  hTrappedCharge
  eGapStatesRecombination hGapStatesRecombination
  eDirectTunnel hDirectTunnel
  InsulatorElectricField SemiconductorElectricField
   Nonlocal
}
}


Math {

#if  @pTunneling@ == 1 

 Nonlocal "NLM" ( 
    RegionInterface= "Oxide_1/Silicon_1"
    Length= @NLM_length@       
    Permeation= 0.0
  )

#endif	  
  
  CNormPrint
  Extrapolate
  Derivatives
  Avalderivatives
  RelErrControl
  Digits= 5
  Notdamped= 100
  Iterations= 200
  DirectCurrent
  ExitOnFailure
  CheckUndefinedModels
  Number_of_Threads= 32
  CurrentPlot (IntegrationUnit = cm)
}


File {
	Output = "@log@"
	ACExtract = "n@node@"
}

System {
	pcap trans (gate=g substrate=s)
        Vsource_pset vg (g 0) {dc=0}
	Vsource_pset vs (s 0) {dc=0}
}

CurrentPlot { 

eQuasiFermi(Average(Material="Oxide"))
hQuasiFermi(Average(Material="Oxide"))
eTrappedCharge(Average(Material="Oxide"))
hTrappedCharge(Average(Material="Oxide"))
RadiationGeneration(Average(Material="Oxide"))
eGapStatesRecombination(Average(Material="Oxide"))
hGapStatesRecombination(Average(Material="Oxide"))
HydrogenIon(Average(Material="Oxide"))
HydrogenIon(Average(RegionInterface="Oxide_1/Silicon_1"))
HydrogenIon(Integral(RegionInterface="Oxide_1/Silicon_1"))

}



Solve {
  Coupled ( Iterations= 100 LineSearchDamping= 1e-8 ){ Poisson } 
  Coupled { Poisson Electron Hole }
  Coupled { Poisson Electron Hole HydrogenIon HydrogenAtom HydrogenMolecule }

  Save ( FilePrefix= "n@node@_init" )
  Plot ( FilePrefix= "n@node@_PEH" )
  
  Transient(
	InitialTime = 0 FinalTime=@DoseTime@
	MinStep = 1e-10 MaxStep = 500
	Bias{ region = "Oxide_1"
	Model = "RadiationBeam" Parameter = "DoseRate"
	Value = (38.6 at 10)
     }
   ){
   	
   	Coupled { Poisson Electron Hole HydrogenIon HydrogenAtom HydrogenMolecule }
	Plot ( FilePrefix="n@node@" Time=( 1; 5; 10; 20; 30; 40; 50; 100; 200; 300; 400; 500; 600; 700; 800; 900; 1000; 1100; 1200; 1300; 1400; @DoseTime@ )  NoOverwrite )
	
   } 
   
   Set (Traps(Frozen))
   
 }
   
 Solve {  
 
   Quasistationary (
	-DoZero
	InitialStep = 1e-9 MinStep = 1e-60 MaxStep = 1
	Decrement = 1.4
	Goal { Model = "RadiationBeam" Parameter = "DoseRate" Value = 0 }
	)
	{ Coupled {Poisson Electron Hole HydrogenAtom HydrogenMolecule } } 
 
Quasistationary (
			MaxStep=0.01 InitialStep=0.001 MinStep=0.000001
			Goal{ Parameter=vg.dc Voltage=-12.0 }
		) 
		{
			ACCoupled(
			StartFrequency=1e6 EndFrequency=1e6
			NumberOfPoints=1 Decade
			Node(g s)
			ACMethod=Blocked ACSubMethod("1d")=ParDiSo
			)
			{Poisson Electron Hole Circuit Contact HydrogenAtom HydrogenMolecule}
	                 } 
	                 
Quasistationary (
			MaxStep=0.01 InitialStep=0.001 MinStep=0.000001
			Goal{ Parameter=vg.dc Voltage=4.0 }
		) 
		{
			ACCoupled(
			StartFrequency=1e6 EndFrequency=1e6
			NumberOfPoints=1 Decade
			Node(g s)
			ACMethod=Blocked ACSubMethod("1d")=ParDiSo
			)
			{Poisson Electron Hole Circuit Contact HydrogenAtom HydrogenMolecule}
	                 } 
}


