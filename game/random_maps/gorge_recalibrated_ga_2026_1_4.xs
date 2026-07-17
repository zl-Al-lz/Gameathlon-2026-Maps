include "lib2/rm_core.xs";

/*
** Gorge
** Author: AL (AoM DE XS CODE)
** Based on "Gorge" by AoE IV DE Team
** Date: January 4, 2026
** Updated: June 16, 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_sichuan_highlands_day_02_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}
vector modSwapVectorAxis(float x = 0.0, float z = 0.0, bool booleanRotation = false)
{
   // Since we cannot make random booleans on constants, we will have to pass an indicator as a parameter.
   return booleanRotation ? vectorXZ(z, x) : vectorXZ(x, z);
}

vector modVectorLerp(vector A = cInvalidVector, vector B = cInvalidVector, float t = 0.0)
{
   return A + (B - A) * t;
}

void modGetMapInfo(string ruleName = cEmptyString, int playerID = 0, string messageText = cEmptyString, string speaker = cEmptyString, 
                    string portraitStrID = cEmptyString, string sound = cEmptyString, int nextEventID = cInvalidID, 
                    bool ignoreOnAbort = false, int timeOutMs = 0, int secondsDelay = 0, bool overrideSoundLenght = false)
{
   rmTriggerAddScriptLine("rule _" + ruleName);
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   if (((xsGetTime() - (cActivationTime / 1000)) >= " + secondsDelay + "))");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      trSoundPlayDialogue(" + playerID + ", \"" + messageText + "\", \"" + speaker + "\", \"" + portraitStrID + "\", \"" + sound + "\", " + nextEventID + ", " + ignoreOnAbort + ", " + timeOutMs + ", " + overrideSoundLenght + ");");
   rmTriggerAddScriptLine("      xsDisableSelf();");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("}");
}

void sanitizeString(ref string pString)
{
   string out = "";
   string allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 (),.-_|/";

   for(int i = 0; i < xsStringLength(pString); i++)
   {
      string c = xsStringCharAt(pString, i);

      if(xsStringContains(allowed, c, true))
      {
         out += c;
      }
   }
   
   pString = out;
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrass2, 6.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrass1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassRocks1, 1.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassDirt1, 1.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassDirt2, 1.0);

   // Define forests.
   int sichuanHighlandsCustomForestID = rmCustomForestCreate("sichuan highlands forest");
   rmCustomForestSetTerrain(sichuanHighlandsCustomForestID, cTerrainChineseForestGrass1);
   rmCustomForestSetParams(sichuanHighlandsCustomForestID, 1.0, 1.0);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreePine, 1.0);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeChinesePine, 0.6);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeOak, 0.35);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeBamboo, 0.25);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeBambooSingle, 0.25);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeMetasequoia, 0.2);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeGinkgo, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseBush, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseWeeds, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseFern, 0.3);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseGrass, 0.1);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypeRockChineseTiny, 0.1);

   // Define Default Tree Type.
   float randomDefaultTreeTypeFloat = xsRandFloat(0.0, 1.0);
   int defaultTreeType = 0;
   if(randomDefaultTreeTypeFloat < 1.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreePine;
   }
   else if(randomDefaultTreeTypeFloat < 2.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeChinesePine;
   }
   else if(randomDefaultTreeTypeFloat < 3.0 / 6.0)
   {
      if(xsRandBool(0.5) == true)
      {
         defaultTreeType = cUnitTypeTreeBamboo;
      }
      else
      {
         defaultTreeType = cUnitTypeTreeBambooSingle;
      }
   }
   else if(randomDefaultTreeTypeFloat < 4.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeOak;
   }
   else if(randomDefaultTreeTypeFloat < 5.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeMetasequoia;
   }
   else
   {
      defaultTreeType = cUnitTypeTreeGinkgo;
   }

   rmSetDefaultTreeType(defaultTreeType);
   
   // Pandoras Box 2 & Gameathlon stuff.
   bool isTournamentSeason = true; 

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypeCow;

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int globalSharedSide = cLocSideSame;

   // Map stuff.
   bool swapAxis = xsRandBool(0.5);

   // Map size and terrain init.
   int axisSize = 132;
   int axisTiles = getScaledAxisTiles(axisSize);

   if(cNumberPlayers <= 4)
   {
      rmSetMapSize(axisTiles);
   }
   else
   {
      float axisMultiplier = 0.93 - (0.021 * cNumberPlayers);
      if(swapAxis)
      {
         rmSetMapSize(axisMultiplier * axisTiles, (1.0 / axisMultiplier) * axisTiles);
      }
      else
      {
         rmSetMapSize((1.0 / axisMultiplier) * axisTiles, axisMultiplier * axisTiles);
      }
   }

   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(1.0);

   // Compute the players to obtain their actual placement order.
   int[] computedPlayers = rmComputePlayersForPlacement();

   // Placement Locs.
   float startAxis = 0.225;
   float endAxis = 1.0 - startAxis;

   vector startLoc = modSwapVectorAxis(startAxis, 0.5, swapAxis);
   vector endLoc = modSwapVectorAxis(endAxis, 0.5, swapAxis);

   if(!gameIs1v1())
   {
      float distanceInMeters = (cNumberPlayers <= 4) ? 45 : 30;
      float edgeDistance = (swapAxis) ? rmXMetersToFraction(distanceInMeters) : rmZMetersToFraction(distanceInMeters);
      startLoc = modSwapVectorAxis(0.0 + edgeDistance, 0.5, swapAxis);
      endLoc = modSwapVectorAxis(1.0 - edgeDistance, 0.5, swapAxis);
   }

   if(gameIsSandbox())
   {
      rmPlacePlayer(computedPlayers[0], cCenterLoc);
   }
   else
   {
      placePlayersOnLine(startLoc, endLoc);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureChinese);

   // Lighting.
   rmSetLighting(cLightingSetPotgPotg04);

   rmSetProgress(0.1);

   // Hills stuff.
   int hillClassID = rmClassCreate();

   float ravineWidth = 103.0;

   int forceInsideHills = rmCreateClassMaxDistanceConstraint(hillClassID, 0.0);

   int hillAvoidance = rmCreateClassDistanceConstraint(hillClassID, ravineWidth);
   
   int avoidHillEdges5 = rmCreateClassDistanceConstraint(hillClassID, 5.0, cClassAreaEdgeDistance);
   int avoidHillEdges10 = rmCreateClassDistanceConstraint(hillClassID, 10.0, cClassAreaEdgeDistance);
   int avoidHillEdges15 = rmCreateClassDistanceConstraint(hillClassID, 15.0, cClassAreaEdgeDistance);
   int avoidHillEdges20 = rmCreateClassDistanceConstraint(hillClassID, 20.0, cClassAreaEdgeDistance);

   int hillAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, 70.0);

   // Hills placement.
   float hillHeight = 19.0;

   for(int i = 0; i < 2; i++)
   {
      string hillName = (i == 0) ? "top hill" : "bottom hill";

      int hillID = rmAreaCreate(hillName);
      rmAreaSetSize(hillID, 1.0);
      if(i == 0)
      {
         rmAreaSetLoc(hillID, modSwapVectorAxis(0.5, 1.0, swapAxis));
         rmAreaAddInfluenceSegment(hillID, modSwapVectorAxis(0.0, 1.0, swapAxis), vectorXZ(1.0, 1.0));
      }
      else if(i == 1)
      {
         rmAreaSetLoc(hillID, modSwapVectorAxis(0.5, 0.0, swapAxis));
         rmAreaAddInfluenceSegment(hillID, vectorXZ(0.0, 0.0), modSwapVectorAxis(1.0, 0.0, swapAxis));
      }
      rmAreaSetCoherence(hillID, 0.35);
      rmAreaSetCoherenceSquare(hillID, true);
      rmAreaSetHeight(hillID, hillHeight);
      rmAreaAddHeightBlend(hillID, cBlendEdge, cFilter5x5Gaussian, 52, 52, false, true);
      rmAreaSetEdgeSmoothDistance(hillID, 15, false);
      rmAreaAddConstraint(hillID, hillAvoidance);
      if(!gameIs1v1() || gameIsSandbox())
      {  // If more players are added, make sure there is enough space in the center.
         rmAreaAddConstraint(hillID, hillAvoidCenter);
      }
      rmAreaAddToClass(hillID, hillClassID);
   }

   // Build the hills simultaneously.
   rmAreaBuildAll();

   // Get their IDs, to use them directly with their constraints instead of having to generate them in each object iteration.
   int topHillID = rmAreaGetID("top hill");
   int forceInsideTopHill = rmCreateAreaConstraint(topHillID);

   int bottomHillID = rmAreaGetID("bottom hill");
   int forceInsideBottomHill = rmCreateAreaConstraint(bottomHillID);

   // Define the cliffs that will be placed along the edges of the hills facing each other.
   float segmentDistance = 12.0;
   float cliffSize = rmRadiusToAreaFraction(14.0);

   int cliffDefID = rmAreaDefCreate("pit cliff def");
   rmAreaDefSetMix(cliffDefID, baseMixID);
   rmAreaDefSetAvoidSelfDistance(cliffDefID, 15.0);
   rmAreaDefSetSize(cliffDefID, cliffSize);
   rmAreaDefSetCoherence(cliffDefID, 0.35);
   rmAreaDefSetCoherenceSquare(cliffDefID, true);
   rmAreaDefSetCliffType(cliffDefID, cCliffChineseGrass);
   rmAreaDefSetCliffEmbellishmentDensity(cliffDefID, 0.55);
   rmAreaDefSetCliffSideRadius(cliffDefID, 1, 2);
   rmAreaDefSetCliffSideSheernessThreshold(cliffDefID, degToRad(65));
   rmAreaDefSetEdgeSmoothDistance(cliffDefID, 2);
   rmAreaDefSetHeight(cliffDefID, hillHeight);
   rmAreaDefAddHeightBlend(cliffDefID, cBlendCliffSide, cFilter3x3Gaussian, 0, 1, true);
   rmAreaDefSetEdgePerturbDistance(cliffDefID, 0.0, 4.5);
   int blendIdx = rmAreaDefAddHeightBlend(cliffDefID, cBlendEdge, cFilter5x5Gaussian, 5, 5, false, true);
   rmAreaDefAddHeightBlendExpansionConstraint(cliffDefID, blendIdx, vDefaultAvoidImpassableLand);
   for(int i = 0; i < 2; i++)
   {
      // First, Get the area whose edge we want to extract.
      int hillID = (i == 0) ? topHillID : bottomHillID;

      // Force it inwards.
      int forceToHill = (i == 0) ? forceInsideTopHill : forceInsideBottomHill;

      // Force the location to be found on the edge.
      rmAddClosestLocConstraint(rmCreateAreaEdgeConstraint(hillID));
      vector edgeLoc = rmGetClosestLoc(cCenterLoc, ravineWidth + 30);

      // Swap the axes if necessary.
      edgeLoc = modSwapVectorAxis(edgeLoc.x, edgeLoc.z, swapAxis);

      // Override the alignment axis to 0.5 as a safety measure.
      edgeLoc = modSwapVectorAxis(0.5, edgeLoc.z, swapAxis);

      // Slightly push the found location inward, bringing it closer to the center.
      float pushMeters = (swapAxis) ? rmXMetersToFraction(2.0) : rmZMetersToFraction(2.0);
      edgeLoc = edgeLoc.translateXZ(-pushMeters, xsVectorAngleAroundY(edgeLoc, cCenterLoc));

      // Clear the constraints before proceeding to the next iteration.
      rmClearClosestLocConstraints();

      // Build the cliff at the found location.
      float segmentMeters = (swapAxis) ? rmXMetersToFraction(segmentDistance) : rmZMetersToFraction(segmentDistance);
      
      int cliffID = rmAreaDefCreateArea(cliffDefID, "cliff " + i);
      rmAreaSetLoc(cliffID, edgeLoc);

      // Create small offsets toward the center.
      if(i == 0)
      {
         if(swapAxis)
         {
            rmAreaAddInfluenceSegment(cliffID, edgeLoc, vectorXZ(edgeLoc.x - segmentMeters, edgeLoc.z));
         }
         else
         {
            rmAreaAddInfluenceSegment(cliffID, edgeLoc, vectorXZ(edgeLoc.x, edgeLoc.z - segmentMeters));
         } 
      }
      else
      {
         if(swapAxis)
         { 
            rmAreaAddInfluenceSegment(cliffID, edgeLoc, vectorXZ(edgeLoc.x + segmentMeters, edgeLoc.z));
         }
         else
         {
            rmAreaAddInfluenceSegment(cliffID, edgeLoc, vectorXZ(edgeLoc.x, edgeLoc.z + segmentMeters));
         }
      }
      // Finally, make the impassable escarpment ignore the hill so it is painted only outside of it.
      rmAreaAddCliffEdgeConstraint(cliffID, cCliffEdgeInside, forceToHill);
   }

   // Build both cliffs simultaneously.
   rmAreaBuildAll();

   // Create areas that add global noise after all ramp blending has been applied.
   int globalNoiseDefID = rmAreaDefCreate("global noise");
   rmAreaDefSetSize(globalNoiseDefID, 1.0);
   rmAreaDefSetHeightNoise(globalNoiseDefID, cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
   rmAreaDefSetAvoidSelfDistance(globalNoiseDefID, 0.1);
   rmAreaDefAddHeightBlend(globalNoiseDefID, cBlendEdge, cFilter5x5Gaussian, 4, 4); // Smooth their edges to seamlessly merge the separate noise areas.
   rmAreaDefAddHeightBlendExpansionConstraint(globalNoiseDefID, 0, vDefaultAvoidImpassableLand); // Do not apply the blend to the impassable escarpment.
   rmAreaDefAddConstraint(globalNoiseDefID, vDefaultAvoidImpassableLand);
   
   // Define the four locations from which the global noise will be generated.
   vector[] globalNoiseLocs = new vector(1, cLocCornerSouth);
   globalNoiseLocs.add(cLocCornerNorth);
   globalNoiseLocs.add(cLocCornerWest);
   globalNoiseLocs.add(cLocCornerEast);

   // Place the noise.
   for(int i = 0; i < 4; i++)
   {
      int globalNoiseID = rmAreaDefCreateArea(globalNoiseDefID);
      rmAreaSetLoc(globalNoiseID, globalNoiseLocs[i]);
   }

   // Finally, build all noise areas simultaneously.
   rmAreaBuildAll();

   // Add a few small forests around the cliffs as decoration.
   int forestClassID = rmClassCreate();

   int forestAvoidance = rmCreateClassDistanceConstraint(forestClassID, 15.0);

   int forceNearImpassableLand6 = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 6.0);

   int cliffForestDefID = rmAreaDefCreate("cliff forest");
   rmAreaDefSetSizeRange(cliffForestDefID, rmTilesToAreaFraction(10), rmTilesToAreaFraction(17));
   rmAreaDefSetForestType(cliffForestDefID, sichuanHighlandsCustomForestID);
   rmAreaDefSetAvoidSelfDistance(cliffForestDefID, 10.0);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(cliffForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 3.0));
   rmAreaDefAddConstraint(cliffForestDefID, forceNearImpassableLand6);
   rmAreaDefAddToClass(cliffForestDefID, forestClassID);
   rmAreaDefCreateAndBuildAreas(cliffForestDefID, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Each player will have one additional large forest.
   int gorgeSpecialForestDefID = rmAreaDefCreate("gorge forests");
   rmAreaDefSetForestType(gorgeSpecialForestDefID, sichuanHighlandsCustomForestID);
   rmAreaDefSetCoherence(gorgeSpecialForestDefID, 0.35);
   rmAreaDefSetEdgePerturbDistance(gorgeSpecialForestDefID, -3.5, 0.5, false);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, createPlayerLocDistanceConstraint(33.0));
   rmAreaDefAddToClass(gorgeSpecialForestDefID, forestClassID);

   // Player large forest placement.
   if(gameIs1v1())
   {  // In 1v1 games, it will be placed behind each player.
      for(int i = 1; i <= cNumberPlayers; i++)
      {
         if(gameIs1v1())
         {
            vector cornerLoc = (i == 1) ? modSwapVectorAxis(0.0, 0.5, swapAxis) : modSwapVectorAxis(1.0, 0.5, swapAxis);
            int specialForestCornerID = rmAreaDefCreateArea(gorgeSpecialForestDefID);

            rmAreaSetSize(specialForestCornerID, 0.015);
            rmAreaSetLoc(specialForestCornerID, cornerLoc);
            rmAreaBuild(specialForestCornerID);
         }
      }
   }
   else
   {  // Otherwise, one will be placed between each pair of players using interpolation.
      for(int i = 0; i < cNumberPlayers - 1; i++)
      {
         vector actualLoc = rmGetPlayerLoc(computedPlayers[i]);
         vector nextLoc = rmGetPlayerLoc(computedPlayers[i + 1]);

         vector lerpLoc = modVectorLerp(actualLoc, nextLoc, 0.5);
         
         int specialForestCornerID = rmAreaDefCreateArea(gorgeSpecialForestDefID);
         rmAreaSetLoc(specialForestCornerID, lerpLoc);
         rmAreaSetSize(specialForestCornerID, rmRadiusToAreaFraction(15));
      }
   }

   rmAreaBuildAll();

   // KotH.
   vector kotHLoc = cCenterLoc;

   if(!gameIs1v1())
   {
      kotHLoc = (xsRandBool(0.5) == true) ? modSwapVectorAxis(0.5, 0.2, swapAxis) : modSwapVectorAxis(0.5, 0.8, swapAxis);
   }

   placeKotHObjects(cUnitTypeShadePredator, kotHLoc);

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand2);
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimObjectLocsPerPlayerPair(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   }

   generateLocs("starting tower locs");

   // Settlements stuff.
   int settlementAvoidEdgeFar = createSymmetricBoxConstraint(rmXTilesToFraction(12), rmZTilesToFraction(12));

   // Settlement bias randomizer.
   int[] settlementBiasCandidates = new int(1, cBiasAggressive);
   settlementBiasCandidates.add(cBiasDefensive);
   settlementBiasCandidates.add(cBiasForward);
   settlementBiasCandidates.add(cBiasBackward);
   settlementBiasCandidates.add(cBiasAggressive | cBiasDefensive);

   // Setlements placement.
   for(int i = 0; i < 2; i++)
   {
      // Get a random bias index within the allowed ranges.
      int biasIndex = xsRandInt(0, settlementBiasCandidates.size() - 1);

      // Get the corresponding id.
      int settlementBiasID = settlementBiasCandidates[biasIndex];

      // Subsequently, remove the index to avoid repeating it in the next iteration.
      settlementBiasCandidates.removeIndex(biasIndex);
      
      // Get the temporary id of the hill.
      int hillID = (i == 0) ? topHillID : bottomHillID;

      string concatString = rmAreaGetName(hillID);

      // Force it inwards.
      int forceToHill = (i == 0) ? forceInsideTopHill : forceInsideBottomHill;

      // Settlement.
      int settlementID = rmObjectDefCreate("settlement " + " from " + concatString);
      rmObjectDefAddItem(settlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(settlementID, xsRandBool(0.5) ? vDefaultSettlementAvoidEdge : settlementAvoidEdgeFar);
      rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(settlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(settlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(settlementID, forceToHill);
      rmObjectDefAddConstraint(settlementID, avoidHillEdges10); 
      if(settlementBiasID == cBiasDefensive)
      {
         rmObjectDefAddConstraint(settlementID, createCornerDistanceConstraint(xsRandFloat(8.0, 20.0)));
      } 
      if(gameIs1v1())
      {
         if(isTournamentSeason)
         {
            addSimObjectLocsPerPlayerPair(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1 *  xsRandFloat(1.0, 1.13), 
                                          settlementBiasID, cInAreaDefault, globalSharedSide);
         }
         else
         {
            addObjectLocsPerPlayer(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1 *  xsRandFloat(1.0, 1.13), settlementBiasID);
         }

      }
      else
      {
         int allyBias = getRandomAllyBias();
         addObjectLocsPerPlayer(settlementID, false, 1, 80.0, 145.0, xsRandBool(0.5) ? cCloseSettlementDist : cFarSettlementDist, 
                                 settlementBiasID | allyBias);
      }
   }
   
   // Far settlement. Randomize both top and bottom.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1); 
      rmObjectDefAddConstraint(bonusSettlementID, settlementAvoidEdgeFar);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, forceInsideHills);
      rmObjectDefAddConstraint(bonusSettlementID, avoidHillEdges15);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);
   
   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   }
   
   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeSpottedDeer, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(2, 3));
      rmObjectDefAddItem(startingHuntID, cUnitTypeSpottedDeer, 3);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimObjectLocsPerPlayerPair(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   }
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 7), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   if(isTournamentSeason)
   {
      rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(startingHerdID, (xsRandBool(0.5) == true) ? cUnitTypeCow : cUnitTypeGoat, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");
   
   // Forest.
   float avoidForestMeters = 28.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(35), rmTilesToAreaFraction(45));
   rmAreaDefSetForestType(forestDefID, sichuanHighlandsCustomForestID);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand14);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddToClass(forestDefID, forestClassID);
   rmAreaDefAddOriginConstraint(forestDefID, rmCreateClassDistanceConstraint(forestClassID, 14.0));

   // Starting forests.
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 60.0;

   int goldAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(7), rmZTilesToFraction(7));

   for(int i = 0; i < 2; i++)
   {
      // Get the temporary id of the hill.
      int hillID = (i == 0) ? topHillID : bottomHillID;

      string concatString = rmAreaGetName(hillID);

      // Force it inwards.
      int forceToHill = (i == 0) ? forceInsideTopHill : forceInsideBottomHill;

      int goldID = rmObjectDefCreate("gold " + " from " + concatString);
      rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
      rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
      rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidImpassableLand);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidCorner32);
      rmObjectDefAddConstraint(goldID, forceToHill);
      rmObjectDefAddConstraint(goldID, avoidHillEdges10);
      rmObjectDefAddConstraint(goldID, goldAvoidEdge);
      addObjectDefPlayerLocConstraint(goldID, 55.0);
      if(gameIs1v1() && isTournamentSeason)
      {
         addSimObjectLocsPerPlayerPair(goldID, false, 2 * getMapAreaSizeFactor(), 55.0, -1.0, avoidGoldMeters, cBiasNone, 
                                       cInAreaDefault, globalSharedSide);
      }
      else
      {
         addObjectLocsPerPlayer(goldID, false, 2 * getMapAreaSizeFactor(), 55.0, -1.0, avoidGoldMeters);
      }
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeSpottedDeer, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(3, 5));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 50.0);
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 50.0, 80.0, avoidHuntMeters);
   }

   // Hill Hunt.
   int numBonusHunt = 1 * getMapAreaSizeFactor(); // TODO: 2 maybe?

   for(int i = 0; i < 2; i++)
   {
      // Get the temporary id of the hill.
      int hillID = (i == 0) ? topHillID : bottomHillID;

      string concatString = rmAreaGetName(hillID);

      // Force it inwards.
      int forceToHill = (i == 0) ? forceInsideTopHill : forceInsideBottomHill;

      for(int j = 0; j < numBonusHunt; j++)
      {
         float bonusHuntFloat = xsRandFloat(0.0, 1.0);
         int bonusHuntID = rmObjectDefCreate("bonus hunt " + " from " + concatString + " - " + j);
         if(bonusHuntFloat < 0.25)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 4));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(2, 4));
         }
         else if (bonusHuntFloat < 0.45)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if (bonusHuntFloat < 0.60)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 3));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if (bonusHuntFloat < 0.75)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         else if (bonusHuntFloat < 0.90)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 7));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         }
         else
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
         rmObjectDefAddConstraint(bonusHuntID, forceToHill);
         rmObjectDefAddConstraint(bonusHuntID, avoidHillEdges10);
         rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(75.0));
         if(gameIs1v1() && isTournamentSeason)
         {
            addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 70.0, 120.0, avoidHuntMeters, cBiasNone, cInAreaDefault, globalSharedSide);
         }
         else
         {
            addObjectLocsPerPlayer(bonusHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
         }
      }
   }

   // Other map sizes hunt.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 1 * getMapAreaSizeFactor();

      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         
         int largeMapHuntID = rmObjectDefCreate("large map hunt " + i);
         if(largeMapHuntID < 0.25)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 4));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(2, 4));
         }
         else if(largeMapHuntID < 0.45)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if(largeMapHuntID < 0.60)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if(largeMapHuntID < 0.75)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         else if(largeMapHuntID < 0.90)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 7));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 55.0;

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(8, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farBerriesID, avoidHillEdges20);
   addObjectDefPlayerLocConstraint(farBerriesID, 90.0);
   if(gameIs1v1() && isTournamentSeason)
   {
      addSimObjectLocsPerPlayerPair(farBerriesID, false, 2 * getMapSizeBonusFactor(), 90.0, -1.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 2 * getMapSizeBonusFactor(), 90.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   if(isTournamentSeason)
   {
      rmObjectDefAddItem(closeHerdID, mapHerdType, xsRandInt(2, 3), 4.0);
   }
   else
   {
      rmObjectDefAddItem(closeHerdID, xsRandBool(0.5) ? cUnitTypeCow : cUnitTypeGoat, xsRandInt(2, 3), 4.0);
   }
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   if(isTournamentSeason)
   {
      rmObjectDefAddItem(bonusHerdID, mapHerdType, 2, 3.0);
   }
   else
   {
      rmObjectDefAddItem(bonusHerdID, xsRandBool(0.5) ? cUnitTypeCow : cUnitTypeGoat, 2, 3.0);
   }
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   int bonusHerd2ID = rmObjectDefCreate("bonus herd B");
   if(isTournamentSeason)
   {
      rmObjectDefAddItem(bonusHerd2ID, mapHerdType, xsRandInt(1, 2), 3.0);
   }
   else
   {
      rmObjectDefAddItem(bonusHerd2ID, xsRandBool(0.5) ? cUnitTypeCow : cUnitTypeGoat, xsRandInt(1, 2), 3.0);
   }
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerd2ID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 55.0;

   int closePredatorID = rmObjectDefCreate("close predator ");
   rmObjectDefAddItem(closePredatorID, cUnitTypeWolf, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closePredatorID, avoidHillEdges20);
   addObjectDefPlayerLocConstraint(closePredatorID, 75.0);
   addObjectLocsPerPlayer(closePredatorID, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidPredatorMeters);

   int farPredatorID = rmObjectDefCreate("far predator ");
   rmObjectDefAddItem(farPredatorID, cUnitTypeBlackBear, 2);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farPredatorID, avoidHillEdges20);
   addObjectDefPlayerLocConstraint(farPredatorID, 85.0);
   addObjectLocsPerPlayer(farPredatorID, false, 1 * getMapAreaSizeFactor(), 85.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);

   // Relics.
   float avoidRelicMeters = 80.0;

   for(int i = 0; i < 2; i++)
   {
      // Get the temporary id of the hill.
      int hillID = (i == 0) ? topHillID : bottomHillID;

      string concatString = rmAreaGetName(hillID);

      // Force it inwards.
      int forceToHill = (i == 0) ? forceInsideTopHill : forceInsideBottomHill;

      int relicID = rmObjectDefCreate("relic " + " from " + concatString);
      rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(relicID, forceToHill);
      rmObjectDefAddConstraint(relicID, avoidHillEdges10);
      addObjectDefPlayerLocConstraint(relicID, 80.0);

      addObjectLocsPerPlayer(relicID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters, cBiasNone, cInAreaNone);
   }
   
   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.

   // Hill forests.
   float avoidHillForestMeters = 20.0;

   int hillForestDefID = rmAreaDefCreate("hill global forest");
   rmAreaDefSetSizeRange(hillForestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(55));
   rmAreaDefSetForestType(hillForestDefID, sichuanHighlandsCustomForestID);
   rmAreaDefSetAvoidSelfDistance(hillForestDefID, avoidHillForestMeters);
   rmAreaDefSetBlobs(hillForestDefID, 0, 2);
   rmAreaDefSetBlobDistance(hillForestDefID, 5.0, 10.0);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(hillForestDefID, avoidHillEdges5);
   rmAreaDefAddConstraint(hillForestDefID, forceInsideHills);
   rmAreaDefAddOriginConstraint(hillForestDefID, avoidHillEdges10, 2.0);
   rmAreaDefAddOriginConstraint(hillForestDefID, forestAvoidance);
   rmAreaDefSetOriginConstraintBuffer(hillForestDefID, 3.0);
   rmAreaDefAddToClass(hillForestDefID, forestClassID);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(45.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(hillForestDefID, 18 * getMapAreaSizeFactor());

   // Tiny Forest.
   float avoidTinyForestMeters = 38.0;

   int tinyGlobalForestDefID = rmAreaDefCreate("tiny forest");
   rmAreaDefSetSizeRange(tinyGlobalForestDefID, rmTilesToAreaFraction(10), rmTilesToAreaFraction(15));
   rmAreaDefSetForestType(tinyGlobalForestDefID, sichuanHighlandsCustomForestID);
   rmAreaDefSetAvoidSelfDistance(tinyGlobalForestDefID, avoidTinyForestMeters);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidImpassableLand12);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultForestAvoidTownCenter);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(tinyGlobalForestDefID, createPlayerLocDistanceConstraint(47.0)); 
   rmAreaDefAddOriginConstraint(tinyGlobalForestDefID, createPlayerLocDistanceConstraint(65.0));
   rmAreaDefAddToClass(tinyGlobalForestDefID, forestClassID);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // Build areas.
   rmAreaDefCreateAndBuildAreas(tinyGlobalForestDefID, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(3, 4);
   int stragglerType = 0;
   
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int playerLocID = vDefaultTeamPlayerLocOrder[i];

      for(int j = 0; j < numStragglers; j++)
      {
         // Straggler case:
         int stragglerCase = xsRandInt(0, 5);
         if(stragglerCase == 0)
         {
            stragglerType = cUnitTypeTreePine;
         }
         else if(stragglerCase == 1)
         {
            stragglerType = cUnitTypeTreeChinesePine;
         }
         else if(stragglerCase == 2)
         {
            stragglerType = cUnitTypeTreeMetasequoia;
         }
         else if(stragglerCase == 3)
         {
            stragglerType = cUnitTypeTreeGinkgo;
         }
         else if(stragglerCase == 4)
         {
            stragglerType = cUnitTypeTreeOak;
         }
         else if(stragglerCase == 5)
         {
            if(xsRandBool(0.5) == true)
            {
               stragglerType = cUnitTypeTreeBamboo;
            }
            else
            {
               stragglerType = cUnitTypeTreeBambooSingle;
            }
         }
         int startingStragglerID = rmObjectDefCreate("starting straggler" + playerLocID + " " + j);
         rmObjectDefAddItem(startingStragglerID, stragglerType, 1);
         rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll8);
         rmObjectDefPlaceAtLoc(startingStragglerID, 0, rmGetPlayerLocByID(playerLocID), cStartingStragglerMinDist,
                              cStartingStragglerMaxDist, 1, true);
      }  
   }

   rmSetProgress(0.9);  

   // Embellishment.

   // Embellishment areas.
   int avoidForest4 = rmCreateClassDistanceConstraint(forestClassID, 4.0);
   int beautificationAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 5.0);
   int beautificationAvoidGold = rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 5.0);
   int beautificationAvoidBerries = rmCreateTypeDistanceConstraint(cUnitTypeBerryBush, 5.0);
   int beautificationAvoidPlayer = createPlayerLocDistanceConstraint(15.0);

   int beautificationDefID = rmAreaDefCreate("beautification area");
   rmAreaDefSetSizeRange(beautificationDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(170));
   rmAreaDefSetAvoidSelfDistance(beautificationDefID, 20.0);
   rmAreaDefSetBlobs(beautificationDefID, 0, 2);
   rmAreaDefSetBlobDistance(beautificationDefID, 15.0, 30.0);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseGrassDirt1, 0);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseGrassDirt2, 1);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseGrassDirt3, 2);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseDirtRocks1, 3);
   rmAreaDefSetTerrainType(beautificationDefID, cTerrainChineseDirtRocks2);
   rmAreaDefAddConstraint(beautificationDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddConstraint(beautificationDefID, avoidForest4);
   rmAreaDefAddConstraint(beautificationDefID, beautificationAvoidBuilding);
   rmAreaDefAddConstraint(beautificationDefID, beautificationAvoidGold);
   rmAreaDefAddConstraint(beautificationDefID, beautificationAvoidBerries);
   rmAreaDefAddConstraint(beautificationDefID, beautificationAvoidPlayer);
   rmAreaDefAddOriginConstraint(beautificationDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddOriginConstraint(beautificationDefID, avoidForest4, 2.0);
   rmAreaDefAddOriginConstraint(beautificationDefID, beautificationAvoidBuilding, 3.0);
   rmAreaDefAddOriginConstraint(beautificationDefID, vDefaultAvoidEdge);
   rmAreaDefAddOriginConstraint(beautificationDefID, beautificationAvoidGold, 3.0);
   rmAreaDefAddOriginConstraint(beautificationDefID, beautificationAvoidBerries, 3.0);
   rmAreaDefCreateAndBuildAreas(beautificationDefID, 16 * cNumberPlayers * getMapAreaSizeFactor());

   // Areas under forests.
   int forestSurroundAreaDefID = rmAreaDefCreate("forest surround");
   rmAreaDefSetSize(forestSurroundAreaDefID, 1.0);
   rmAreaDefSetTerrainType(forestSurroundAreaDefID, cTerrainChineseGrass2);
   rmAreaDefAddTerrainLayer(forestSurroundAreaDefID, cTerrainChineseGrass1, 0);
   rmAreaDefAddConstraint(forestSurroundAreaDefID, vDefaultAvoidImpassableLand8);

   // Let extensive grasses surround the forests.
   int[] allForestIDs = rmClassGetAreas(forestClassID);
   int numForestAreas = allForestIDs.size();

   for(int i = 0; i < numForestAreas; i++)
   {
      int forestID = allForestIDs[i];

      vector forestLoc = rmAreaGetLoc(forestID);
      if(forestLoc == cInvalidVector)
      {
         continue;
      }

      int forestSurroundID = rmAreaDefCreateArea(forestSurroundAreaDefID);
      rmAreaSetLoc(forestSurroundID, forestLoc);
      rmAreaAddConstraint(forestSurroundID, rmCreateAreaMaxDistanceConstraint(forestID, 5.0));
      rmAreaAddTerrainConstraint(forestSurroundID, rmCreateAreaDistanceConstraint(forestID, 1.0));
      rmAreaBuild(forestSurroundID);
   }

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainChineseDirtRocks2, cTerrainChineseGrassDirt2, 8.0);
   buildAreaUnderObjectDef(rmObjectDefGetID("gold " + " from " + rmAreaGetName(topHillID)), cTerrainChineseDirtRocks2, 
                           cTerrainChineseGrassDirt2, 8.0);
   buildAreaUnderObjectDef(rmObjectDefGetID("gold " + " from " + rmAreaGetName(bottomHillID)), cTerrainChineseDirtRocks2, 
                           cTerrainChineseGrassDirt2, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainChineseGrass2, cTerrainChineseGrass1, 12.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainChineseGrass2, cTerrainChineseGrass1, 12.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockChineseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockChineseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   // Impassable rocks.
   int forceNearImpassableLand3 = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 3.0);

   int rockMediumID = rmObjectDefCreate("rock medium");
   rmObjectDefAddItem(rockMediumID, cUnitTypeRockChineseMedium, 1);
   rmObjectDefAddConstraint(rockMediumID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockMediumID, forceNearImpassableLand3);
   rmObjectDefPlaceAnywhere(rockMediumID, 0, 2);

   int rockLargeID = rmObjectDefCreate("rock large");
   rmObjectDefAddItem(rockLargeID, cUnitTypeRockChineseLarge, 1);
   rmObjectDefAddConstraint(rockLargeID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockLargeID, forceNearImpassableLand3);
   rmObjectDefPlaceAnywhere(rockLargeID, 0, 3);

   // Columns
   int columnsBrokenID = rmObjectDefCreate("columns broken");
   rmObjectDefAddItem(columnsBrokenID, cUnitTypeColumnsBroken, 1);
   rmObjectDefAddConstraint(columnsBrokenID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsBrokenID, forceNearImpassableLand3);
   rmObjectDefPlaceAnywhere(columnsBrokenID, 0, 3);

   int columnsID = rmObjectDefCreate("columns");
   rmObjectDefAddItem(columnsID, cUnitTypeColumns, 1);
   rmObjectDefAddConstraint(columnsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsID, forceNearImpassableLand3);
   rmObjectDefPlaceAnywhere(columnsID, 0, 3);

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseRoad2, 2.5);

   int avoidChineseDirtRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseDirtRocks1, 2.5);
   int avoidChineseDirtRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseDirtRocks2, 2.5);
   int avoidChineseGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseGrassDirt3, 2.5);
   int avoidChineseGrassDirt2Far = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseGrassDirt2, 6.0);
   int avoidChineseGrassDirt3Far = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseGrassDirt3, 6.0);

   // Random trees placement.
   for(int i = 0; i < 7; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 28 / 7;

      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreePine; treeName = "pine "; break; }
         case 1: { treeTypeID = cUnitTypeTreeChinesePine; treeName = "chinese pine "; break; }
         case 2: { treeTypeID = cUnitTypeTreeMetasequoia; treeName = "metasequoia "; break; }
         case 3: { treeTypeID = cUnitTypeTreeGinkgo; treeName = "ginkgo "; break; }
         case 4: { treeTypeID = cUnitTypeTreeOak; treeName = "oak  "; break; }
         case 5: { treeTypeID = cUnitTypeTreeBamboo; treeName = "bamboo  ";  treeDensity *= 0.5; break; }
         case 6: { treeTypeID = cUnitTypeTreeBambooSingle; treeName = "bamboo single ";  treeDensity *= 0.5; break; }
      }

      // Tree template.
      int treeDefID = rmObjectDefCreate(treeName);
      rmObjectDefAddItem(treeDefID, treeTypeID, 1);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidAll);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidCollideable);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidImpassableLand);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidWater);
      rmObjectDefAddConstraint(treeDefID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidTree);
      rmObjectDefAddConstraint(treeDefID, avoidRoad1);
      rmObjectDefAddConstraint(treeDefID, avoidRoad2);
      rmObjectDefAddConstraint(treeDefID, avoidChineseDirtRocks1);
      rmObjectDefAddConstraint(treeDefID, avoidChineseDirtRocks2);
      rmObjectDefAddConstraint(treeDefID, avoidChineseGrassDirt3);
      rmObjectDefPlaceAnywhere(treeDefID, 0, treeDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Generic Bush.
   int genericBushID = rmObjectDefCreate("generic bush");
   rmObjectDefAddItem(genericBushID, cUnitTypeBush, 1);
   rmObjectDefAddConstraint(genericBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(genericBushID, vDefaultAvoidImpassableLand2);
   rmObjectDefAddConstraint(genericBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(genericBushID, avoidRoad1);
   rmObjectDefAddConstraint(genericBushID, avoidRoad2);
   rmObjectDefAddConstraint(genericBushID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(genericBushID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(genericBushID, avoidChineseGrassDirt3);
   rmObjectDefPlaceAnywhere(genericBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Generic Bush Group.
   int genericBushGroupID = rmObjectDefCreate("generic bush group");
   rmObjectDefAddItemRange(genericBushGroupID, cUnitTypeBush, 2, 5, 0.5, 1.5);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultAvoidImpassableLand2);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(genericBushGroupID, avoidRoad1);
   rmObjectDefAddConstraint(genericBushGroupID, avoidRoad2);
   rmObjectDefAddConstraint(genericBushGroupID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(genericBushGroupID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(genericBushGroupID, avoidChineseGrassDirt3);
   rmObjectDefPlaceAnywhere(genericBushGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 50;
      int plantsGroupDensity = 10;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantChineseBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantChineseShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantChineseFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantChineseWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantChineseGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantChineseFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantChineseWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
      }
      
      // Plant template.
      int plantTypeDef = rmObjectDefCreate(plantName);
      if(i < 5)
      {
         rmObjectDefAddItem(plantTypeDef, plantID, 1);
      }
      else
      {
         rmObjectDefAddItemRange(plantTypeDef, plantID, 1, 3, 0.0, 4.0);
      }
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidImpassableLand2);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidWater); 
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad1);
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad2);
      rmObjectDefAddConstraint(plantTypeDef, avoidChineseDirtRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidChineseDirtRocks2);
      rmObjectDefAddConstraint(plantTypeDef, avoidChineseGrassDirt3);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(plantTypeDef, avoidChineseGrassDirt2Far);
         rmObjectDefAddConstraint(plantTypeDef, avoidChineseGrassDirt3Far);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Flowers.
   int flowersID = rmObjectDefCreate("flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(flowersID, avoidRoad1);
   rmObjectDefAddConstraint(flowersID, avoidRoad2);
   rmObjectDefAddConstraint(flowersID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(flowersID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(flowersID, avoidChineseGrassDirt2Far);
   rmObjectDefAddConstraint(flowersID, avoidChineseGrassDirt3Far);
   rmObjectDefPlaceAnywhere(flowersID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.
   int flowersAvoidGold = rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0);

   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 2.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);    
   rmObjectDefAddConstraint(flowersGroupID, flowersAvoidGold);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseGrassDirt2Far);
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseGrassDirt3Far);
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers.
   int meadowFlowersID = rmObjectDefCreate("meadow flowers");
   rmObjectDefAddItemRange(meadowFlowersID, cUnitTypeMeadowFlower, 1);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad2);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseGrassDirt2Far);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseGrassDirt3Far);
   rmObjectDefPlaceAnywhere(meadowFlowersID, 0, 150 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers Group.        
   int meadowFlowersGroupID = rmObjectDefCreate("Meadow flowers group");
   rmObjectDefAddItemRange(meadowFlowersGroupID, cUnitTypeMeadowFlower, 5, 8, 0.0, 0.5);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseGrassDirt2Far);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseGrassDirt3Far);
   rmObjectDefAddConstraint(meadowFlowersGroupID, flowersAvoidGold);
   rmObjectDefPlaceAnywhere(meadowFlowersGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(logID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logID, vDefaultAvoidEdge);   
   rmObjectDefAddConstraint(logID, avoidRoad1);
   rmObjectDefAddConstraint(logID, avoidRoad2);   
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidEdge);   
   rmObjectDefAddConstraint(logGroupID, avoidRoad1);
   rmObjectDefAddConstraint(logGroupID, avoidRoad2);   
   rmObjectDefPlaceAnywhere(logGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeEagle, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // We will add a message with the player names and map seed for debugging and issue tracking.

   // Define map name.
   string MapName = "Gorge - Recalibrated";

   // This array will contain, at each index, the strings to be concatenated.
   string[] playersOverlay = new string(0, cEmptyString);

   // We will begin iterating and concatenating, separating the V/s by team.
   for(int i = 1; i <= cNumberTeams; i++)
   {
      // Get the team id.
      int t = vTeamOrderPlaced[i];

      // Get the number of players on the team.
      int numPlayersInTeam = rmGetNumberPlayersOnTeam(t);
      
      for(int j = 0; j < numPlayersInTeam; j++)
      {
         // Get the player id.
         int pID = rmGetPlayerOnTeam(t, j);

         // In addition to the player's name, we will add their major god.
         int civID = kbPlayerGetCiv(pID);

         // Concatenate the player's name and their major god.
         string playerInfo = kbPlayerGetName(pID) + " " + "(" + kbCivGetName(civID) + ")";

         // If there is more than one player on the team, separate them with commas.
         if(j > 0)
         {
            playersOverlay.add(", ");
         }

         // Add the player info to the concatenation array.
         playersOverlay.add(playerInfo);

      }
      // Finally, add the V/s after finishing the iteration over the team.
      if(i != cNumberTeams)
      {
         playersOverlay.add(" V/s ");
      }
   }
   // Add the map name and its seed into a single string.
   string mapInfo = MapName + " | " + "Seed: " + xsRandGetSeed();

   // Just a message from me.
   string speakerID = "~AL~";
   string speakerIconPath = "atlantean\\static_color\\minor_gods\\oceanus_icon.png";
   string overlaySound = cEmptyString; // "ui\game_starting1.wav";

   // Get the dimension of the array.
   int numConcatStrings = playersOverlay.size();
      
   // The string will be initialized with the characters at index 0, thereby avoiding an iteration.
   string concatPlayerOverlay = playersOverlay[0];

   // Now, we will concatenate them into this same string.
   for(int i = 1; i < numConcatStrings; i++)
   {
      concatPlayerOverlay += playersOverlay[i];
   }
   // Now, we have a problem: if a player's name contains a character outside the ASCII set, the code won't compile and will break. 
   // That is why we need to sanitize the string containing corrupt characters.
   sanitizeString(concatPlayerOverlay);

   // Once sanitized, we can call the trigger.
   modGetMapInfo("MapOverlay", 1, concatPlayerOverlay + " | " + mapInfo, speakerID, speakerIconPath, overlaySound, -1, 
                  false, 4000, 2, false);

   // Lighting Override.
   lightingOverride();

   rmSetProgress(1.0);
}
