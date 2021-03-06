###################################
# Run the design through Encounter
###################################
#Setup design and create floorplan
 set designName lfsr1
 loadConfig "./$designName.conf"
 #loadfootprint -infile ../../libs/custom.fp
 #source ../../libs/setdontuse.tcl
 #setBufFootPrint buf
 #setInvFootPrint inv
 #setDelayFootPrint buf

# Create Initial Floorplan
# -r aspect ratio, row density, core to io margins
 floorplan -s 100 100 10 10 10 10 
 redraw
 fit

Puts "####################"
Puts "###"
Puts "### Power Routing ..."
Puts "###"
Puts "####################"
 #globalNetConnect VDD -type pgpin -pin {VDD } -inst * -module {} 
 #globalNetConnect VSS -type pgpin -pin {VSS } -inst * -module {}
 globalNetConnect VDD -type tiehi
 globalNetConnect VSS -type tielo
 #globalNetConnect VDDs -type pgpin -pin {VDDs } -inst WELLTAP* -module {}
 #globalNetConnect VSSs -type pgpin -pin {VSSs } -inst WELLTAP* -module {}
 applyGlobalNets

addRing -nets {VDD VSS } -type core_rings -layer_top M1 -layer_bottom M1 -layer_right M2 -layer_left M2 -width_top 3 -width_bottom 3 -width_left 3 -width_right 3 -spacing_top 1 -spacing_bottom 1 -spacing_right 1 -spacing_left 1

#addRing -nets {VDD VSS } -type core_rings -layer_top M1 -layer_bottom M1 -layer_right M2 -layer_left M2 -width_top 1 -width_bottom 1 -width_left 1 -width_right 1 -spacing_top 1 -spacing_bottom 1 -spacing_right 1 -spacing_left 1
redraw

#	addStripe -block_ring_top_layer_limit M3 \
#			-max_same_layer_jog_length 6 \
#			-padcore_ring_bottom_layer_limit M1 \
#			-set_to_set_distance 20 \
#			-stacked_via_top_layer MQ \
#			-padcore_ring_top_layer_limit M3 \
#			-spacing 7 -merge_stripes_value 2.5 \
#			-layer M4 \
#			-block_ring_bottom_layer_limit M1 \
#			-width 3 \
#			-nets {VSS VDD } \
#			-stacked_via_bottom_layer M1 \
# 			-extend_to design_boundary -create_pins 1

#Route power nets
sroute -nets {VDD VSS} -noBlockPins -noPadRings -stopBlockPin {boundaryWithPin}
#IO file 
 loadIoFile $rda_Input(ui_io_file)
 redraw
 saveFPlan "$designName.fp"

Puts "####################"
Puts "###"
Puts "### Place Design ..."
Puts "###"
Puts "####################"
#load timing constranits
 loadTimingCon $rda_Input(ui_timingcon_file)
#add welltap
 #addWellTap -cell welltap -maxGap 16 -prefix WELLTAP
#place standard cells
 setPlaceMode -timingdriven -congHighEffort -doCongOpt -modulePlan -maxRouteLayer 5
 setOptMode -fixFanoutLoad -highEffort -moveInst -reclaimArea true
 placeDesign -inplaceOpt
 #addTieHiLo -cell "tiehi tielo"
 redraw
 saveDesign "$designName.placed.enc"
 checkPlace
 buildTimingGraph
 redraw

Puts "###################"
Puts "###"
Puts "### Pre-Route Optimization..."
Puts "###"
Puts "###################"
 #dont have to do this once you use -inplaceopt option in placeDesign
 #loadTimingCon "$designName.sdc"
 #setOptMode -fixFanoutLoad 
 #setOptMode -highEffort
 #setOptMode -moveInst
 #setOptMode -reclaimArea
 #optDesign -preCTS

Puts "##############"
Puts "###"
Puts "### Run CTS..."
Puts "###"
Puts "##############"
 #Allow CTS to recognize data
 #pins as synch pins as well
 #setCTSMode -setDPinAsSync -bottomPreferredLayer 1 -topPreferredLayer 5 -routeClkNet -leafBottomPreferredLayer 1 -leafTopPreferredLayer 5
 # Run Clock Tree Generation
 # Modify the file $designName.cts to specify input, output delays and clock timing
 #loadTimingCon "$designName.sdc"
 #createClockTreeSpec -output "$designName.cts" -bufFootprint buf -invFootprint inv
 ######### modify skew here
 #loadTimingCon $designName.sdc
 #createClockTreeSpec -output "$designName.cts" 
 specifyClockTree -file "$designName.cts.manual"
 ckSynthesis -clk clk -rguide cts.rguide -report report.ctsrpt -macromodel report.ctsmdl -forceReconvergent
 #ckSynthesis -clk clk -report report.stsrpt -rguide cts.rguide -macromodel report.ctsmdl -check -forceReconvergent -breakLoop
 # Output Results of CTS
 #trialRoute -highEffort -guide cts.rguide -maxRouteLayer 5 -minRouteLayer 1
 #setAnalysisMode -clockTree
 #buildTimingGraph
 #timeDesign -postCTS -outDir ./Timing/POST_CTS.timing 
 #setExtractRCMode -detail
 #extractRC

Puts "################################"
Puts "###"
Puts "### Optimization post CTS..."
Puts "###"
Puts "################################"
 #setOptMode -maxDensity 0.7
 #setOptMode -fixFanoutLoad
 #setOptMode -highEffort 
 #setOptMode -moveInst
 #setOptMode -reclaimArea
 #optDesign -postCTS
 #setOptMode -highEffort -fixFanoutLoad -maxDensity 0.9 -reclaimArea -setupTargetSlack 0.0 -holdTargetSlack 0.0
 #optDesign -postCTS
 #saveDesign "$designName.postCTS.enc"
 #timeDesign -postCTS -outDir "POST_CTS_IPO.timing"

#Connect all new cells to VDD/GND
 #globalNetConnect VDD -type pgpin -pin {VDD } -override
 #globalNetConnect VSS -type pgpin -pin {VSS } -override
 globalNetConnect VDD -type tiehi
 globalNetConnect VSS -type tielo
 applyGlobalNets

#Save design 
 saveDesign "$designName.opted.enc"
 savePlace "$designName.place"

Puts "################################"
Puts "###"
Puts "### Route clocks first    .... "
Puts "###"
Puts "################################"
#read timing constrain
 loadTimingCon $rda_Input(ui_timingcon_file)
#Route clock pins
 setAttribute -net clk -weight 5 -avoid_detour true -bottom_preferred_routing_layer 2 -top_preferred_routing_layer 3 -preferred_extra_space 3
 #setAttribute -net @clock -weight 5 -avoid_detour true -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 6 -preferred_extra_space 1
 #selectNet -allDefClock
 selectNet clk
 #selectNet -clock
 setNanoRouteMode -quiet routeWithTimingDriven true
 #setNanoRouteMode -quiet envNumberProcessor 8
 setNanoRouteMode -quiet route_selected_net_only true
 setNanoRouteMode -quiet routeTopRoutingLayer 3
 setNanoRouteMode -quiet routeBottomRoutingLayer 1
 globalDetailRoute
 #createRouteBlk -box 0 0 190 153 -layer 6 7
 redraw

Puts "################################"
Puts "###"
Puts "### Route other signals    .... "
Puts "###"
Puts "################################"
# Route All Nets
 setNanoRouteMode -quiet route_selected_net_only false
 setNanoRouteMode -quiet routeWithTimingDriven true
 setNanoRouteMode -quiet routeTdrEffort 10
 setNanoRouteMode -quiet drouteFixAntenna true
 setNanoRouteMode -quiet routeWithSiDriven true
 setNanoRouteMode -quiet routeSiLengthLimit 200
 setNanoRouteMode -quiet routeSiEffort high
 setNanoRouteMode -quiet routeWithViaInPin true
 setNanoRouteMode -quiet routeWithViaOnlyForStandardCellPin false
 setNanoRouteMode -quiet droutePostRouteSwapVia multiCut
 setNanoRouteMode -quiet drouteUseMultiCutViaEffort high
 #setNanoRouteMode -quiet envNumberProcessor 8
 setNanoRouteMode routeTopRoutingLayer 3
 setNanoRouteMode routeBottomRoutingLayer 1
 #setNanoRouteMode -drouteElapsedTimeLimit 2
 globalDetailRoute

 deleteAllRouteBlks
 redraw

Puts "################################"
Puts "###"
Puts "### Extract and Optimization.... "
Puts "###"
Puts "################################"
 setExtractRCMode -detail
 extractRC
 setOptMode -yieldEffort none
 setOptMode -highEffort
 #setOptMode -maxDensity 0.8
 setOptMode -drcMargin 0.0
 setOptMode -holdTargetSlack 0.0 -setupTargetSlack 0.0
 setOptMode -noSimplifyNetlist
 setOptMode -noUsefulSkew
 setOptMode -moveInst
 setOptMode -reclaimArea true
 setOptMode -fixDRC
 setOptMode -noFixCap
 optDesign -postRoute -hold

# Connect all new cells to VDD/GND
 globalNetConnect VDD -type pgpin -pin {VDD } -override
 globalNetConnect VSS -type pgpin -pin {VSS } -override
 globalNetConnect VDD -type tiehi
 globalNetConnect VSS -type tielo

#clearDrc
 verifyGeometry -allowDiffCellViols
 verifyConnectivity -type regular -error 1000 -warning 50

#Save design 
 saveDesign "$designName.routed.enc"

Puts "################################"
Puts "###"
Puts "### Add decap and fillers    .... "
Puts "###"
Puts "################################"
#Add decap
 #verifyGeometry
 #addDeCapCellCandidates HS65_50_DECAP9 4.1
 #addDeCapCellCandidates HS65_50_DECAP12 8.8
 #addDeCapCellCandidates HS65_50_DECAP16 13.7
 #addDeCapCellCandidates HS65_50_DECAP32 43.6
 #addDeCapCellCandidates HS65_50_DECAP64 105.0
 #addDeCap -totCap 2000 -cells HS65_50_DECAP9 HS65_50_DECAP12 HS65_50_DECAP16 HS65_50_DECAP32 HS65_50_DECAP64 -fixDRC
 verifyGeometry
#Add filler cells
 addFiller -cell FILL16TS FILL1TS FILL2TS FILL32TS FILL4TS FILL64TS FILL8TS -prefix IBM13RFLPVT_FILLER -fillBoundary
 verifyGeometry
 redraw

 globalNetConnect VDD -type pgpin -pin {VDD } -inst * -module {} 
 globalNetConnect VSS -type pgpin -pin {VSS } -inst * -module {}
 globalNetConnect VDD -type tiehi
 globalNetConnect VSS -type tielo

 applyGlobalNets
 clearDrc
 verifyGeometry
 verifyConnectivity -type regular -error 1000 -warning 50
 verifyProcessAntenna

Puts "################################"
Puts "###"
Puts "### Producing outputs    .... "
Puts "###"
Puts "################################"
#Save Design
 reportLeakagePower 
 reportGateCount
 saveDesign "$designName.opted.enc"
#Output LEF
 lefOut "$designName.lef" -5.5 -PGpinLayers 4 -specifyTopLayer 4 -stripePin
#Output DEF
 set dbgLefDefOutVersion 5.5
 defOut -floorplan -netlist -routing "$designName.final.def"
#Output GDSII
 streamOut "$designName.gds" -mapFile "/tools2/courses/ee6321/share/ibm13rflpvt/mapfiles/enc2gds.map" -libName ibm13rflpvt -structureName $designName -stripes 1 -units 1000 -mode ALL
#saveNetlist -excludeLeafCell "$designName.final.v"
 saveNetlist "$designName.nophycell.v" 
#Generate SDF
 extractRC -outfile "$designName.cap"
 rcOut -spef "$designName.spef"
 delayCal -sdf "$designName.sdf" -mergeSetupHold
#Report hold/setup violation
 setAnalysisMode -hold -useDetailRC
 reportViolation -outfile final_hold.tarpt
 setAnalysisMode -setup -useDetailRC
 reportViolation -outfile final_setup.tarpt
 reportCapViolation -outfile final_cap.tarpt
#Run DRC and Connection checks
 verifyGeometry
 verifyConnectivity -type all
 reportCritNet -outfile "$designName.critnet.rpt"

 #clearDrc
puts "**************************************"
puts "*                                    *"
puts "* And finally....                    *"
puts "*                                    *"
puts "* Encounter script finished          *"
puts "*                                    *"
puts "*                                    *"
puts "*                                    *"
puts "**************************************"
 exit
