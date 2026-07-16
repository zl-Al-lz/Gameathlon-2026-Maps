include "lib2/rm_core.xs";

/*
** Midgard | Recalibrated | 
** Treatment for Gameathlon by AL
** Date: June 16, 2026
*/

void mapOverlayRule(string ruleName = cEmptyString,  int playerID = 0, string messageText = cEmptyString, string speaker = cEmptyString, 
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
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass2, 2.0);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(160);
   rmSetMapSize(axisTiles);
   rmInitializeWater(cWaterNorseSeaSnow);

   float continentFraction = 0.5;
   float playerContinentEdgeDistMeters = 40.0;
   float placementRadiusMeters = rmFractionToAreaRadius(continentFraction) - playerContinentEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);

   // Player placement.
   rmSetTeamSpacingModifier(0.9);
   rmPlacePlayersOnCircle(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmMidgard01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreePineSnow);

   // Gameathlon stuff.
   bool isTournamentSeason = true; 

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int sharedSide = xsRandBool(0.5) ? cLocSideSame : cLocSideOpposite;

   // Override the SimLocs variation with a significantly higher value to introduce
   // much more variety without compromising the competitive treatment.
   vSimLocDefaultRadiusVar *= 1.35; // ± 7.5m → 10.1m.
   vSimLocDefaultAngleVar *= 1.7; // ± 11,25° → 19,1°.

   rmSetProgress(0.1);

   // Shared continent stuff.
   int continentClassID = rmClassCreate();

   int forceInsideContinentClass = rmCreateClassMaxDistanceConstraint(continentClassID, 0.0);

   // Player base areas.
   float playerBaseAreaSize = rmRadiusToAreaFraction(45.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, playerBaseAreaSize);
      rmAreaSetCoherence(playerBaseAreaID, 1.0);
      rmAreaAddToClass(playerBaseAreaID, continentClassID);
   }

   // Build all player areas simultaneously.
   rmAreaBuildAll();
   
   // Fake Continent.
   int fakeContinentID = rmAreaCreate("fake continent");
   rmAreaSetSize(fakeContinentID, continentFraction);
   rmAreaSetLoc(fakeContinentID, cCenterLoc);
   rmAreaSetBlobDistance(fakeContinentID, 5.0, 20.0);
   rmAreaSetBlobs(fakeContinentID, 1 * cNumberPlayers, 2 * cNumberPlayers);
   rmAreaSetEdgeSmoothDistance(fakeContinentID, 15);
   rmAreaAddConstraint(fakeContinentID, createSymmetricBoxConstraint(0.075), 0.0, 10.0);
   rmAreaAddToClass(fakeContinentID, continentClassID);
   rmAreaBuild(fakeContinentID);

   // Real continent.
   int continentID = rmAreaCreate("continent");
   rmAreaSetMix(continentID, baseMixID);
   rmAreaSetSize(continentID, 1.0);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetHeight(continentID, 0.25);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 5.0, 0.05, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 10, 10);
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 20.0);
   rmAreaAddConstraint(continentID, forceInsideContinentClass);
   rmAreaBuild(continentID);
   
   // Continent spots.
   float avoidSpotsMeters = 45.0;

   int spotAvoidPlayerLoc = createPlayerLocDistanceConstraint(60.0);
   int spotAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, smallerFractionToMeters(continentFraction * 0.7));
   int forceInsideContinentEdge = rmCreateAreaEdgeConstraint(continentID);

   int continentSpotID = rmAreaDefCreate("continent spot");
   rmAreaDefSetWaterType(continentSpotID, cWaterNorseSeaSnow);
   rmAreaDefSetSizeRange(continentSpotID, rmTilesToAreaFraction(600), rmTilesToAreaFraction(750));
   rmAreaDefSetAvoidSelfDistance(continentSpotID, avoidSpotsMeters, 10.0);
   rmAreaDefSetEdgeSmoothDistance(continentSpotID, 10);
   rmAreaDefAddConstraint(continentSpotID, spotAvoidPlayerLoc);
   rmAreaDefAddConstraint(continentSpotID, spotAvoidCenter);
   rmAreaDefAddOriginConstraint(continentSpotID, forceInsideContinentEdge); 
   if(gameIs1v1() && cMapSizeCurrent == cMapSizeStandard)
   {
      addSimAreaLocsPerPlayerPair(continentSpotID, xsRandInt(1, 2), 75.0, -1.0, avoidSpotsMeters * 1.25);

      generateLocs("spot locs");
   }
   else
   {  // Unchecked.
      rmAreaDefCreateAndBuildAreas(continentSpotID, 2 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());
   }

   // KotH.
   placeKotHObjects();

   // Player beautification
   float playerGrassBeautificationSize = rmTilesToAreaFraction(500);

   int playerBeautificationDefID = rmAreaDefCreate("player beautification ");
   rmAreaDefSetTerrainType(playerBeautificationDefID, cTerrainNorseSnowGrass2);
   rmAreaDefAddTerrainLayer(playerBeautificationDefID, cTerrainNorseSnowGrass1, 0, 1);
   rmAreaDefSetCoherence(playerBeautificationDefID, 0.15);
   rmAreaDefSetBlobs(playerBeautificationDefID, 1, 2);
   rmAreaDefSetBlobDistance(playerBeautificationDefID, 5.0, 10.0);
   rmAreaDefSetEdgeSmoothDistance(playerBeautificationDefID, 5);

   buildAreaDefUnderPlayerLocs(playerBeautificationDefID, playerGrassBeautificationSize);

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 90.0, cSettlementDist1v1, cBiasAggressive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 100.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
   }

   // Other map sizes settlements.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");

   int chickenNum = xsRandInt(4, 6);

   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   for (int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(1, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forests.
   float avoidForestMeters = 22.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(70), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater18);

   // Starting forests.
   addAreaLocsPerPlayer(forestDefID, 4, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 8.0);

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 55.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters, cBiasForward, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters);
   }
   
   // Medium gold.
   int mediumGoldID = rmObjectDefCreate("medium gold");
   rmObjectDefAddItem(mediumGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(mediumGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(mediumGoldID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(mediumGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(mediumGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(mediumGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(mediumGoldID, false, 1, 65.0, -1.0, avoidGoldMeters, cBiasVeryDefensive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(mediumGoldID, false, 1, 65.0, -1.0, avoidGoldMeters, cBiasDefensive);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   if(gameIs1v1() == true)
   {
      if(xsRandFloat(0.0, 1.0) < 0.4)
      {  // This one has higher priority to be placed if it comes in here.
         addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1, 70.0, -1.0, avoidGoldMeters, cBiasVeryAggressive, cInAreaDefault, 
                                       isTournamentSeason ? sharedSide : cLocSideRandom);
      }
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidGoldMeters, 
                                    cBiasForward, cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   int shoreHuntMinDist = rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 4.0);
   int shoreHuntMaxDist = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 16.0);

   // Shore hunt.
   if(gameIs1v1() == true)
   {
      // Currently only place this for 1v1.
      int shoreHuntID = rmObjectDefCreate("shore hunt");
      rmObjectDefAddItem(shoreHuntID, cUnitTypeWalrus, xsRandInt(3, 6));
      rmObjectDefAddConstraint(shoreHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidSettlementRange);
      // Don't use the buffer for the "range band" here, makes it less complicated.
      rmObjectDefAddConstraint(shoreHuntID, shoreHuntMinDist, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(shoreHuntID, shoreHuntMaxDist, cObjectConstraintBufferNone);
      addObjectDefPlayerLocConstraint(shoreHuntID, 60.0);
      addSimObjectLocsPerPlayerPair(shoreHuntID, false, 1, 60.0, 90.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(4, 9));
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 70.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus shore hunt.
   int bonusShoreHuntID = rmObjectDefCreate("bonus shore hunt");
   rmObjectDefAddItem(bonusShoreHuntID, cUnitTypeWalrus, xsRandInt(4, 7));
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultAvoidSettlementRange);
   // Same as above.
   rmObjectDefAddConstraint(bonusShoreHuntID, shoreHuntMinDist, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusShoreHuntID, shoreHuntMaxDist, cObjectConstraintBufferNone);
   if(gameIs1v1() == true)
   {
      rmObjectDefAddConstraint(bonusShoreHuntID, createPlayerLocDistanceConstraint(80.0));

      addSimObjectLocsPerPlayerPair(bonusShoreHuntID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);

      if(cMapSizeCurrent > cMapSizeStandard)
      {
         addObjectLocsPerPlayer(bonusShoreHuntID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidHuntMeters);
      }
   }
   else
   {
      rmObjectDefAddConstraint(bonusShoreHuntID, createPlayerLocDistanceConstraint(60.0));
      addObjectLocsPerPlayer(bonusShoreHuntID, false, 1 * getMapSizeBonusFactor(), 60.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElk, xsRandInt(4, 9));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeCaribou, xsRandInt(4, 9));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHuntMeters, cBiasNone,
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // TODO: SIMLOCS HERE?

   // Ice patches.
   int iceClassID = rmClassCreate();
   
   int avoidIcePatch = rmCreateClassDistanceConstraint(iceClassID, 1.0);

   // We build the areas in reverse order: first the inner layer (without painting it yet),
   // then the outer layer at a maximum distance from the inner one, and finally the inner layer itself.
   //
   // With the previous method, the ice area could become restricted by nearby edges generated
   // by the outer layer, sometimes preventing it from being painted and leaving only a rocky pit.
   // Building the layers in reverse avoids this limitation.

   int icePatchDefID = rmAreaDefCreate("rocky patch");
   rmAreaDefSetSizeRange(icePatchDefID, rmTilesToAreaFraction(100), rmTilesToAreaFraction(130));
   rmAreaDefAddTerrainLayer(icePatchDefID, cTerrainNorseShore1, 0, 0);
   rmAreaDefSetHeightRelative(icePatchDefID, -1.0);
   rmAreaDefAddHeightBlend(icePatchDefID, cBlendAll, cFilter3x3Gaussian, 2, 2);
   rmAreaDefSetTerrainType(icePatchDefID, cTerrainDefaultIce1);
   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidAll12);
   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidWater16);
   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidSettlementRange);
   rmAreaDefAddConstraint(icePatchDefID, createPlayerLocDistanceConstraint(60.0));
   rmAreaDefSetAvoidSelfDistance(icePatchDefID, 40.0);
   rmAreaDefSetOriginConstraintBuffer(icePatchDefID, 10.0);
   rmAreaDefAddToClass(icePatchDefID, iceClassID);

   // Create and paint the areas. We also use a receiver array for later use.
   int[] icePatchIDs = rmAreaDefCreateAndBuildAreas(icePatchDefID, 1 * cNumberPlayers * getMapAreaSizeFactor(), false);
   int numIcePatchs = icePatchIDs.size();

   // Rocky layer.
   for(int i = 0; i < numIcePatchs; i++)
   {
      int rockyLayerID = rmAreaCreate("rocky layer" + i);
      rmAreaSetLoc(rockyLayerID, rmAreaGetLoc(icePatchIDs[i]));
      rmAreaSetSize(rockyLayerID, 1.0);
      rmAreaSetTerrainType(rockyLayerID, cTerrainNorseSnowRocks2);
      rmAreaAddTerrainLayer(rockyLayerID, cTerrainNorseSnowRocks1, 0, 0);
      rmAreaAddConstraint(rockyLayerID, rmCreateAreaMaxDistanceConstraint(icePatchIDs[i], 4.0));
      rmAreaAddToClass(rockyLayerID, iceClassID);
   }

   // Build and paint all rocky layers simultaneously.
   rmAreaBuildAll();

   // Finally, paint the inner ice areas.
   rmAreaPaintMany(icePatchIDs);

   // Herdables.
   float avoidHerdMeters = 50.0;

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 50.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypePolarBear, xsRandInt(1, 2));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 70.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 60.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // Avoid the ice patchs.
   rmAreaDefAddConstraint(forestDefID, avoidIcePatch);
   rmAreaDefAddOriginConstraint(forestDefID, avoidIcePatch, 5.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(40.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(55.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 6 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   // Fish.
   // Player fish (straight behind the base from the center).
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // Go in the order we placed the players.
      int p = vDefaultTeamPlayerOrder[i];

      // Get the player starting loc ID.
      int playerLocID = rmGetPlayerLocID(p);
      // Get the player's starting pos.
      vector playerLoc = rmGetPlayerLoc(p);

      // Get the angle of the player loc.
      float minAngle = 0.95 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];
      float maxAngle = 1.05 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];

      int playerAngleConstraint = rmCreateCircularConstraint(playerLoc, cMaxFloat, minAngle, maxAngle);

      int playerFishID = rmObjectDefCreate("player fish " + p);
      rmObjectDefAddItem(playerFishID, cUnitTypeSalmon, 3, 6.0);
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 11.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 14.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, playerAngleConstraint, cObjectConstraintBufferNone);
      // We could check tile by tile towards the edge, but this is also okay.
      rmObjectDefPlaceNearLoc(playerFishID, 0, playerLoc);
   }

   // Additional fish.
   float fishDistMeters = 45.0;

   int avoidFish = rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters);

   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypeSalmon, 3, 6.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 8.0));
   rmObjectDefAddConstraint(fishID, createSymmetricBoxConstraint(rmXTileIndexToFraction(1), rmXTileIndexToFraction(1)));
   rmObjectDefAddConstraint(fishID, avoidFish);
   if(gameIs1v1())
   {
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 35.0));

      // Decrease the radial and angular variation slightly.
      float fishSimLocsRadiusVar = cSimLocDefaultRadiusVar * 0.9;
      float fishSimLocsAngularVar = cSimLocDefaultAngleVar * 0.9; 

      int[] mirroredFishLocIDs = addMirroredLocsPerPlayerPair(xsRandInt(5, 6) * getMapAreaSizeFactor(), 40.0, rmXFractionToMeters(0.85),
                                                             fishDistMeters, cBiasNone, cInAreaPlayer, sharedSide);

      // Apply established radial and angular variation.
      setLocsRadiusVariance(mirroredFishLocIDs, fishSimLocsRadiusVar);
      setLocsAngleVariance(mirroredFishLocIDs, fishSimLocsAngularVar);

      // Place the objects in the locs.
      setLocsObject(mirroredFishLocIDs, fishID, false);
   }
   else
   {
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 50.0));
      addObjectLocsPerPlayer(fishID, false, xsRandInt(5, 6) * getMapAreaSizeFactor(), 80.0, -1.0, fishDistMeters, cInAreaPlayer);
   }

   // Shattered fish.
   int shatteredFishAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters * 0.65);

   int shatteredFishID = rmObjectDefCreate("shattered fish");
   rmObjectDefAddItem(shatteredFishID, cUnitTypeSalmon, 1);
   rmObjectDefAddConstraint(shatteredFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0));
   rmObjectDefAddConstraint(shatteredFishID, createSymmetricBoxConstraint(0.02));
   rmObjectDefAddConstraint(shatteredFishID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(shatteredFishID, shatteredFishAvoidance);
   if(gameIs1v1() && (cMapSizeCurrent == cMapSizeStandard))
   {
      addSimObjectLocsPerPlayerPair(shatteredFishID, false, xsRandInt(3, 4) * getMapSizeBonusFactor(), 50.0, -1.0, 
                                    fishDistMeters * 1.35, cBiasNone, cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(shatteredFishID, false, xsRandInt(4, 5) * getMapSizeBonusFactor(), 50.0, -1.0, fishDistMeters * 1.35, 
                             cBiasNone, cInAreaPlayer);
   }

   generateLocs("fish locs");

   rmSetProgress(0.9);

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(mediumGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 9.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow2, 2.5);

   // Random tree pine snow.
   int randomTreePineSnowID = rmObjectDefCreate("random tree pine snow");
   rmObjectDefAddItem(randomTreePineSnowID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidIcePatch);
   rmObjectDefPlaceAnywhere(randomTreePineSnowID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 18;
      int plantsGroupDensity = 4;

      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantSnowBush; plantName = "plant snow bush "; break; }
         case 1: { plantID = cUnitTypePlantSnowShrub; plantName = "plant snow shrub "; break; }
         case 2: { plantID = cUnitTypePlantSnowFern; plantName = "plant snow fern "; break; }
         case 3: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant snow weeds "; break; }
         case 4: { plantID = cUnitTypePlantSnowGrass; plantName = "plant snow grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantSnowFern; plantName = "plant snow fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant snow weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidIcePatch);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

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
   rmObjectDefPlaceAnywhere(logID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefPlaceAnywhere(logGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "reed vs land");
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0, "reed near land");

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 18 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItemRange(waterReedGroupID, cUnitTypeWaterReeds, 2, 3);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedGroupID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweeds near from the shores.
   int shoreSeaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(shoreSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMaxWaterDepthConstraint(2.35));
   rmObjectDefPlaceAnywhere(shoreSeaweedID, 0, 60 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Seaweeds far from the shores.
   int deepSeaweedID = rmObjectDefCreate("deep seaweed");
   rmObjectDefAddItem(deepSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(deepSeaweedID, rmCreateMinWaterDepthConstraint(2.0));
   rmObjectDefAddConstraint(deepSeaweedID, rmCreateMaxWaterDepthConstraint(3.0));
   rmObjectDefAddConstraint(deepSeaweedID, createSymmetricBoxConstraint(rmXTileIndexToFraction(8), rmXTileIndexToFraction(8)));
   rmObjectDefPlaceAnywhere(deepSeaweedID, 0, 80.0 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Water Animals.
   int customAvoidEdge10 = createSymmetricBoxConstraint(rmXMetersToFraction(10.0), rmZMetersToFraction(10.0));
   int customAvoidEdge18 = createSymmetricBoxConstraint(rmXMetersToFraction(18.0), rmZMetersToFraction(18.0));
   int customAvoidEdge22 = createSymmetricBoxConstraint(rmXMetersToFraction(22.0), rmZMetersToFraction(22.0));
   int customAvoidEdge50 = createSymmetricBoxConstraint(rmXMetersToFraction(50.0), rmZMetersToFraction(50.0));

   // Orcas.
   int orcaAvoidOrca = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 40.0, true, "orca vs orca");
   int avoidOrca20 = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 20.0, true, "anything vs orca 20");
   int avoidOrca30 = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 30.0, true, "anything vs orca 30");

   int orcaID = rmObjectDefCreate("orca");
   rmObjectDefAddItem(orcaID, cUnitTypeOrca);
   rmObjectDefAddConstraint(orcaID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(orcaID, customAvoidEdge18);
   rmObjectDefAddConstraint(orcaID, orcaAvoidOrca);
   rmObjectDefPlaceAnywhere(orcaID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Sharks.
   int sharkAvoidShark = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 40.0, true, "shark vs shark");
   int avoidSharks20 = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 20.0, true, "anything vs shark 20");
   int avoidSharks30 = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 30.0, true, "anything vs shark 30");

   int sharkID = rmObjectDefCreate("shark");
   rmObjectDefAddItem(sharkID, cUnitTypeSharks);
   rmObjectDefAddConstraint(sharkID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(sharkID, customAvoidEdge18);
   rmObjectDefAddConstraint(sharkID, avoidOrca20);
   rmObjectDefAddConstraint(sharkID, sharkAvoidShark);
   rmObjectDefPlaceAnywhere(sharkID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Whales.
   int whaleAvoidWhale = rmCreateTypeDistanceConstraint(cUnitTypeWhale, 60.0, true, "whale vs whale");
   int whaleAvoidLand = rmCreateWaterDistanceConstraint(false, 50.0, "whale vs land");
   int avoidWhales30 = rmCreateTypeDistanceConstraint(cUnitTypeWhale, 30.0, true, "anything vs whales 30");

   int whaleID = rmObjectDefCreate("whale ");
   rmObjectDefAddItem(whaleID, cUnitTypeWhale);
   rmObjectDefAddConstraint(whaleID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(whaleID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(whaleID, whaleAvoidLand);
   rmObjectDefAddConstraint(whaleID, customAvoidEdge50);
   rmObjectDefAddConstraint(whaleID, avoidOrca20);
   rmObjectDefAddConstraint(whaleID, whaleAvoidWhale);
   rmObjectDefAddConstraint(whaleID, avoidSharks20);
   rmObjectDefPlaceAnywhere(whaleID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Snowmist.
   int snowmistID = rmObjectDefCreate("snowmist");
   rmObjectDefAddItem(snowmistID, cUnitTypeVFXSnowDriftPlain, 1);
   rmObjectDefPlaceAnywhere(snowmistID, 0, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Light snowfall.
   rmTriggerAddScriptLine("rule _snow");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trRenderSnow(1.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   // We will add a message with the player names and map seed for debugging and issue tracking.

   // Define map name.
   string MapName = "Midgard - Recalibrated";

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
   mapOverlayRule("MapOverlay", 1, concatPlayerOverlay + " | " + mapInfo, speakerID, speakerIconPath, overlaySound, -1, 
                  false, 4000, 2, false);

   rmSetProgress(1.0);
}
