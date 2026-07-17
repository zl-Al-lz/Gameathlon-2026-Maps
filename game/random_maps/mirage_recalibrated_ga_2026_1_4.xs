include "lib2/rm_core.xs";

/*
** Mirage | Recalibrated | 
** Treatment for Gameathlon by AL
** Date: June 14, 2026
*/

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
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 2.0);

   // Map size and terrain init.
   int maxTeamSize = getMaxTeamPlayers();
   if(gameIsFair() == false)
   {
      maxTeamSize = (cNumberPlayers + 1) / 2;
   }

   int xTiles = (180 + 10 * maxTeamSize) * sqrt(getMapAreaSizeFactor());
   int zTiles = (40 + 80 * maxTeamSize) * sqrt(getMapAreaSizeFactor());
   rmSetMapSize(xTiles, zTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   if(gameIs1v1() == true)
   {
      placePlayersOnLine(vectorXZ(0.25, 0.5), vectorXZ(0.75, 0.5));
   }
   else
   {
      int edgeDistTiles = 50;
      float edgeDistFraction = rmZTilesToFraction(edgeDistTiles);

      // TODO Could also do this if we have 2 teams instead.
      if(gameIsFair() == true)
      {
         int teamInt = xsRandInt(0, 1);
         // Players have to be placed counter-clockwise to get proper player/team angles.
         placeTeamOnLine(1 + teamInt, vectorXZ(0.25, 1.0 - edgeDistFraction), vectorXZ(0.25, edgeDistFraction));
         placeTeamOnLine(2 - teamInt, vectorXZ(0.75, edgeDistFraction), vectorXZ(0.75, 1.0 - edgeDistFraction));
      }
      else
      {
         // TODO Could also place players in two lines instead.
         rmPlacePlayersOnSquare(0.275, 0.5 - edgeDistFraction);
      }
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmMirage01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreePalm);

   // Gameathlon stuff.
   bool isTournamentSeason = true; 

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int sharedSide = xsRandBool(0.5) ? cLocSideSame : cLocSideOpposite;

   rmSetProgress(0.1);

   // Create oceans.
   float oceanAreaSize = 0.0;

   for(int i = 0; i < 2; i++)
   {
      int oceanID = rmAreaCreate("ocean " + i);
      rmAreaSetLoc(oceanID, vectorXZ(0.0 + i, 0.5));
      rmAreaSetWaterType(oceanID, cWaterEgyptSea);
      rmAreaSetEdgeSmoothDistance(oceanID, 2);
      if(gameIs1v1() == true)
      {  
         oceanAreaSize = 0.1;
         rmAreaSetSize(oceanID, oceanAreaSize);
         rmAreaAddInfluenceSegment(oceanID, vectorXZ(i, 0.35), vectorXZ(i, 0.65));
         rmAreaSetCoherence(oceanID, 0.5);
      }
      else
      {
         oceanAreaSize = 0.125;
         rmAreaSetSize(oceanID, oceanAreaSize);
         rmAreaAddInfluenceSegment(oceanID, vectorXZ(i, 0.0), vectorXZ(i, 1.0));
      }
   }

   rmAreaBuildAll();

   // Height noise.
   int heightNoiseAreaID = rmAreaCreate("height noise");
   rmAreaSetSize(heightNoiseAreaID, 1.0);
   rmAreaSetLoc(heightNoiseAreaID, cCenterLoc);
   rmAreaAddConstraint(heightNoiseAreaID, vDefaultAvoidWater20); // Don't get too close to the water.
   rmAreaSetHeightNoise(heightNoiseAreaID, cNoiseFractalSum, 6.0, 0.04, 2, 0.5);
   rmAreaSetHeightNoiseBias(heightNoiseAreaID, 1.0); // Only grow upwards.
   rmAreaAddHeightBlend(heightNoiseAreaID, cBlendAll, cFilter5x5Gaussian, 5, 5, true);
   rmAreaBuild(heightNoiseAreaID);

   rmSetProgress(0.2);

   // Beautify player areas.
   int playerAreaClassID = rmClassCreate();

   float playerAreaSize = rmRadiusToAreaFraction(35.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaCreate("player area " + p);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetLocPlayer(playerAreaID, p);
      rmAreaAddTerrainLayer(playerAreaID, cTerrainEgyptGrassDirt2, 0, 1);
      rmAreaAddTerrainLayer(playerAreaID, cTerrainEgyptGrassDirt1, 1, 2);
      rmAreaAddTerrainLayer(playerAreaID, cTerrainEgyptGrass1, 2, 4);
      rmAreaSetTerrainType(playerAreaID, cTerrainEgyptGrass2);
      rmAreaAddConstraint(playerAreaID, vDefaultAvoidWater12);
      rmAreaAddToClass(playerAreaID, playerAreaClassID);
      rmAreaBuild(playerAreaID);
   }

   rmSetProgress(0.3);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   }
   
   generateLocs("starting tower locs");

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Cliff definition.
   float avoidGorgeMeters = gameIs1v1() ? 50.0 : 35.0;

   float cliffAreaSize = rmTilesToAreaFraction(450);

   int numCliffsPerPlayer = 2;

   int cliffAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);
   int cliffOriginAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(10), rmZTilesToFraction(10));

   int cliffID = rmAreaDefCreate("cliff");
   rmAreaDefSetMix(cliffID, baseMixID);
   rmAreaDefSetCliffType(cliffID, cCliffEgyptSand);
   rmAreaDefSetCliffSideRadius(cliffID, 0, 2);
   rmAreaDefSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
   rmAreaDefSetCliffRampSteepness(cliffID, 25.0);
   rmAreaDefSetCliffEmbellishmentDensity(cliffID, 0.1);
   rmAreaDefSetSizeRange(cliffID, cliffAreaSize * 0.8, cliffAreaSize * 1.2);
   rmAreaDefSetAvoidSelfDistance(cliffID, avoidGorgeMeters);
   rmAreaDefSetHeightRelative(cliffID, -8.0);
   int cliffSideBlendIdx = rmAreaDefAddHeightBlend(cliffID, cBlendCliffSide, cFilter3x3Gaussian, 1);
   int cliffRampBlendIdx = rmAreaDefAddHeightBlend(cliffID, cBlendCliffRamp, cFilter5x5Gaussian, 10, 10, true, true);
   rmAreaDefAddHeightBlendExpansionConstraint(cliffID, cliffRampBlendIdx, vDefaultAvoidImpassableLand);
   rmAreaDefSetBlobs(cliffID, 1, 4);
   rmAreaDefSetBlobDistance(cliffID, 0.0, 15.0);
   rmAreaDefSetConstraintBuffer(cliffID, 5.0, 10.0);
   rmAreaDefSetOriginConstraintBuffer(cliffID, 20.0);
   rmAreaDefAddConstraint(cliffID, vDefaultAvoidWater18);
   rmAreaDefAddConstraint(cliffID, cliffAvoidBuilding);
   rmAreaDefAddConstraint(cliffID, createPlayerLocDistanceConstraint(55.0));
   rmAreaDefAddOriginConstraint(cliffID, cliffOriginAvoidEdge); // Only the origin vector.
   if(gameIs1v1())
   {
      int bonusCliffID = rmAreaDefCreateArea(cliffID);
      rmAreaSetLoc(bonusCliffID, cCenterLoc);
      rmAreaBuild(bonusCliffID);
   }

   // Settlements.
   int settlementAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, 40.0);

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidCenter);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidCenter);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1 * 1.15, cBiasBackward,
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);

      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 100.0, cSettlementDist1v1 * 1.15, cBiasAggressive, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      // 50% chance for inside/outside forward TCs.
      int backwardBias = (xsRandBool(0.5) == true) ? cBiasAllyInside : cBiasAllyOutside;
      int forwardBias = (xsRandBool(0.5) == true) ? cBiasAllyInside : cBiasAllyOutside;

      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | backwardBias);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 100.0, cFarSettlementDist, cBiasAggressive | forwardBias);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");


   rmSetProgress(0.4);

   // Cliff locs placement.
   if(gameIs1v1())
   {
      addSimAreaLocsPerPlayerPair(cliffID, 1, 65.0, 80.0, avoidGorgeMeters * 1.25, cBiasForward, cInAreaDefault, 
                                 isTournamentSeason ? sharedSide : cLocSideRandom);

      addSimAreaLocsPerPlayerPair(cliffID, 1, 75.0, 125.0, avoidGorgeMeters * 1.25, cBiasNotDefensive, 
                                 cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);

      if(cMapSizeCurrent > cMapSizeStandard)
      {
         addAreaLocsPerPlayer(cliffID, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGorgeMeters * 1.25);
      }

      generateLocs("gorge locs");
   }
   else
   {
      // Unchecked.
      buildAreaDefInTeamAreas(cliffID, numCliffsPerPlayer * getMapAreaSizeFactor());
   }

   // Enable TOB conversion.
   rmSetTOBConversion(true);
   
   rmSetProgress(0.5);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   }
   
   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 7), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(7, 8));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forests.
   // Mirage needs palms, not savannah trees so only place those.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalm);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater16);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidImpassableLand12);

   // Starting forests.
   addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);

   generateLocs("starting forest locs");

   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 55.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasNotDefensive, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);

      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 100.0, avoidGoldMeters, cBiasNotDefensive, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasNotDefensive);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters, cBiasForward, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters, cBiasForward);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(6, 9));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters, cBiasNotDefensive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters, cBiasNotDefensive);
   }

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeElephant, 2);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeZebra, xsRandInt(6, 9));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNotDefensive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNotDefensive);
   }

   // Bonus hunt 2.
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, 3);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGiraffe, xsRandInt(4, 6));
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNotDefensive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNotDefensive);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 1 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 4));
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 2));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(5, 12));
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

   rmSetProgress(0.7);

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters, cBiasNotDefensive);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters, cBiasNotDefensive);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters, cBiasNotDefensive);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters, cBiasNotDefensive);

   generateLocs("relic locs");

   // Fish.
   int fishID = rmObjectDefCreate("fish");
   rmObjectDefAddItem(fishID, cUnitTypeMahi, 3, 5.0);

   // Distance from the z axis (x = 0.0) as a fraction.
   float fishXEdgeDistFraction = 0.0;
   float fishZStartFraction = 0.0;
   float fishZEndFraction = 0.0;
   float fishLineVarMeters = 0.0;
   int numFish = 0;

   if(gameIs1v1() == true)
   {
      // Move slightly closer to the shore since the water doesn't cover the entire side.
      fishXEdgeDistFraction = (2.0 / 3.0) * oceanAreaSize;

      fishZStartFraction = 0.4 / getMapAreaSizeFactor();

      fishZEndFraction = 1.0 - fishZStartFraction;

      fishLineVarMeters = 0.0;
      numFish = 3 * maxTeamSize * getMapAreaSizeFactor();
   }
   else
   {
      fishXEdgeDistFraction = 0.5 * oceanAreaSize;

      fishZStartFraction = rmZMetersToFraction(rmXFractionToMeters(fishXEdgeDistFraction));
      fishZEndFraction = 1.0 - fishZStartFraction;

      fishLineVarMeters = 5.0;
      if(cNumberPlayers < 9)
      {
         numFish = xsRandInt(4, 5) * maxTeamSize * getMapAreaSizeFactor();
      }
      else
      {
         numFish = xsRandInt(3, 4) * maxTeamSize * getMapAreaSizeFactor();
      }
   }

   placeObjectDefInLine(fishID, 0, numFish, vectorXZ(fishXEdgeDistFraction, fishZStartFraction),
                                            vectorXZ(fishXEdgeDistFraction, fishZEndFraction),
                                            fishLineVarMeters);
   placeObjectDefInLine(fishID, 0, numFish, vectorXZ(1.0 - fishXEdgeDistFraction, fishZStartFraction),
                                            vectorXZ(1.0 - fishXEdgeDistFraction, fishZEndFraction),
                                            fishLineVarMeters);

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(45.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 8 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.9);

   // Beautification.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt1, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Avoid the player.
   int embellishmentAvoidPlayer = rmCreateClassDistanceConstraint(playerAreaClassID, 1.0);

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(plantBushID, embellishmentAvoidPlayer);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, embellishmentAvoidPlayer);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantDeadFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, embellishmentAvoidPlayer);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantDeadWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, embellishmentAvoidPlayer);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItemRange(rockTinyID, cUnitTypeRockEgyptTiny, 1, 2, 2.0, 4.0);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItemRange(rockSmallID, cUnitTypeRockEgyptSmall, 1, 2, 2.0, 4.0);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Dunes.
   int driftAvoidSelf = rmCreateTypeDistanceConstraint(cUnitTypeVFXSandDriftPlain, 20.0);

   int driftID = rmObjectDefCreate("drift");
   rmObjectDefAddItem(driftID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(driftID, driftAvoidSelf);
   rmObjectDefAddConstraint(driftID, embellishmentAvoidPlayer);
   rmObjectDefAddConstraint(driftID, vDefaultAvoidWater16);
   rmObjectDefPlaceAnywhere(driftID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Water embellishment - currently place nothing since we have an ocean.

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // We will add a message with the player names and map seed for debugging and issue tracking.

   // Define map name.
   string MapName = "Mirage - Recalibrated";

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

   rmSetProgress(1.0);
}
