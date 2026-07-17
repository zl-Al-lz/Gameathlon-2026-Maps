include "lib2/rm_core.xs";

/*
** Ghost Lake | Recalibrated | 
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
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 3, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowDirt1, 1.0);

   int iceMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(iceMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce1, 1.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce2, 2.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce3, 2.0);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(128);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   rmSetProgress(0.1);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.7, 0.8));
   rmPlacePlayersOnCircle(xsRandFloat(0.36, 0.375));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmGhostLake01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreePineSnow);

   // Gameathlon stuff.
   bool isTournamentSeason = true; 

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int sharedSide = xsRandBool(0.5) ? cLocSideSame : cLocSideOpposite;

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.05, 2, 0.5);

   // We will use areas instead of createPlayerLocDistanceConstraint to avoid abrupt and unnatural cuts.
   int playerAreaClassID = rmClassCreate();

   float playerAreaSize = rmRadiusToAreaFraction(42.0);

   for(int i = 1; i <= cNumberPlayers ; i++)
   {
      int playerID = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaCreate("player area " + playerID);
      rmAreaSetLocPlayer(playerAreaID, playerID, 0);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetCoherence(playerAreaID, 0.4);
      rmAreaAddToClass(playerAreaID, playerAreaClassID);
   }
   
   // Build all player areas simultaneously.
   rmAreaBuildAll();
   
   // Do not place the lake yet.

   rmSetProgress(0.2);

   // Settlements.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);

   generateLocs("starting tower locs");

   // Prioritize starting objects placement, even above the lake.

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, xsRandInt(1, 2), cStartingGoldMinDist, cStartingGoldMaxDist, cStartingGoldAvoidanceMeters);
   
   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int numChicken = xsRandInt(4, 6);

   int startingChickenID = rmObjectDefCreate("starting chicken");
   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   for (int i = 0; i < numChicken; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 5));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forests.
   float avoidForestMeters = 25.0;

   int forestClassID = rmClassCreate();

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidEdge, 1.0);
   rmAreaDefAddToClass(forestDefID, forestClassID);

   // Starting forests.
   if(gameIs1v1())
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 1, cStartingForestMinDist - 2.5, cStartingForestMaxDist - 2.5, avoidForestMeters * 1.55, 
                                 cBiasAggressive);
      addAreaLocsPerPlayer(forestDefID, 2, cStartingForestMinDist - 2.5, cStartingForestMaxDist - 2.5, avoidForestMeters * 1.55);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist - 2.5, cStartingForestMaxDist - 2.5, avoidForestMeters * 1.55);
   }
   
   generateLocs("starting forest locs");

   rmSetProgress(0.3);

   // Ghost lake stuff.
   float lakeFraction = xsRandFloat(0.18, 0.185);
   vector lakeLoc = vectorXZ(xsRandFloat(0.49, 0.51), xsRandFloat(0.49, 0.51));

   int lakeAvoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, xsRandFloat(1.0, 4.0));

   int lakeAvoidForest = rmCreateClassDistanceConstraint(forestClassID, 6.0);

   // Fake lake (It will serve as an expansion limit).
   int fakeLakeID = rmAreaCreate("fake lake");
   rmAreaSetLoc(fakeLakeID, lakeLoc);
   rmAreaSetSize(fakeLakeID, lakeFraction);
   rmAreaSetEdgeSmoothDistance(fakeLakeID, 5);
   rmAreaSetBlobs(fakeLakeID, 8, 10);
   rmAreaSetBlobDistance(fakeLakeID, rmGetMapXTiles() / 12.0, rmGetMapZTiles() / 6.0);
   rmAreaAddConstraint(fakeLakeID, lakeAvoidPlayerArea);
   rmAreaAddConstraint(fakeLakeID, lakeAvoidForest);
   rmAreaAddConstraint(fakeLakeID, createSymmetricBoxConstraint(rmXMetersToFraction(50.0)));
   rmAreaBuild(fakeLakeID);

   // Generate semi-symmetrical blobs using a simple trick. LocGen will place their origins along the edges of a fake lake,
   // then the real lake will be generated and expanded while avoiding those blobs.
   int blobsClassID = rmClassCreate();

   float avoidBlobsMeters = 55.0;

   int lakeBlobDefID = rmAreaDefCreate("lake blob");
   rmAreaDefSetSizeRange(lakeBlobDefID, rmTilesToAreaFraction(200), rmTilesToAreaFraction(250));
   rmAreaDefSetAvoidSelfDistance(lakeBlobDefID, avoidBlobsMeters);
   rmAreaDefSetEdgeSmoothDistance(lakeBlobDefID, 5);
   rmAreaDefAddOriginConstraint(lakeBlobDefID, rmCreateAreaEdgeConstraint(fakeLakeID));
   rmAreaDefAddToClass(lakeBlobDefID, blobsClassID);
   if(gameIs1v1())
   {
      // Generate the mirrored locs.
      int[] blobLocsIDs = addMirroredLocsPerPlayerPair(1 * getMapAreaSizeFactor(), 60.0, -1.0, avoidBlobsMeters);

      // Apply only angular variation. (No radius)
      setLocsAngleVariance(blobLocsIDs, vSimLocDefaultAngleVar);

      // Place the blobs.
      setLocsArea(blobLocsIDs, lakeBlobDefID);

      generateLocs("lake blob locs", false, true, false);
   }
   else
   {  // If it's not 1v1, unchecked.
      rmAreaDefCreateAndBuildAreas(lakeBlobDefID, xsRandInt(1, 2) * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Ghost lake.
   int lakeAvoidBlobs = rmCreateClassDistanceConstraint(blobsClassID, 1.0);
   int forceNearFakeLake = rmCreateAreaMaxDistanceConstraint(fakeLakeID, xsRandFloat(3.0, 7.0));

   int realGhostLakeID = rmAreaCreate("real ghost lake");
   rmAreaSetMix(realGhostLakeID, iceMixID);
   rmAreaAddTerrainLayer(realGhostLakeID, cTerrainNorseSnowRocks1, 0, 1);
   rmAreaAddTerrainLayer(realGhostLakeID, cTerrainNorseShore1, 1, 2);
   rmAreaAddTerrainLayer(realGhostLakeID, cTerrainDefaultIce1, 3, 4);
   rmAreaSetLoc(realGhostLakeID, lakeLoc);
   rmAreaSetSize(realGhostLakeID, 1.0);
   rmAreaSetHeight(realGhostLakeID, 0.0);
   rmAreaAddHeightBlend(realGhostLakeID, cBlendEdge, cFilter5x5Gaussian, 10, 10, true, true);
   rmAreaSetEdgeSmoothDistance(realGhostLakeID, 5);
   rmAreaAddConstraint(realGhostLakeID, lakeAvoidBlobs);
   rmAreaAddConstraint(realGhostLakeID, lakeAvoidForest);
   rmAreaAddConstraint(realGhostLakeID, lakeAvoidPlayerArea);
   rmAreaAddConstraint(realGhostLakeID, forceNearFakeLake); // Slight expansion variation.
   rmAreaBuild(realGhostLakeID);

   int avoidCenter8 = rmCreateAreaDistanceConstraint(realGhostLakeID, 8.0);
   int avoidCenter12 = rmCreateAreaDistanceConstraint(realGhostLakeID, 12.0);
   int avoidCenter10 = rmCreateAreaDistanceConstraint(realGhostLakeID, 10.0);
   int avoidCenter16 = rmCreateAreaDistanceConstraint(realGhostLakeID, 16.0);

   rmSetProgress(0.4);

   // Settlements.
   int settlementAvoidForests = rmCreateClassDistanceConstraint(forestClassID, 15.0);

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(firstSettlementID, avoidCenter16);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidForests);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidCenter16);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidForests);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1 * 1.15, cBiasBackward,
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideOpposite);

      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1 * 1.15, cBiasAggressive, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, avoidCenter16);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   // Since these are not areas that affect the terrain as such where the settlements are located, 
   // we can place them first without worry.
   bool successfulSettlements = generateLocs("settlement locs", true, true, true, false);

   int settlementAreaClassID = rmClassCreate();
   int avoidSettlementArea = rmCreateClassDistanceConstraint(settlementAreaClassID, 1.0);

   if(successfulSettlements)
   {
      int numSettlementsLocs = rmLocGenGetNumberLocs();

      float settlementAreaFraction = rmRadiusToAreaFraction(25.0);

      for(int i = 0; i < numSettlementsLocs; i++)
      {
         int settlementAreaID = rmAreaCreate("settlement area " + i);
         rmAreaSetLoc(settlementAreaID, rmLocGenGetLoc(i));
         rmAreaSetSize(settlementAreaID, settlementAreaFraction);
         rmAreaSetCoherence(settlementAreaID, 0.35);
         rmAreaSetEdgeSmoothDistance(settlementAreaID, 2);
         rmAreaSetEdgePerturbDistance(settlementAreaID, -1.5, 1.5, false);
         rmAreaAddToClass(settlementAreaID, settlementAreaClassID);
         rmAreaBuild(settlementAreaID);
      }

      resetLocGen();
   }

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int avoidCliffRamps = rmCreateClassDistanceConstraint(cliffClassID, 15.0, cClassAreaCliffRampDistance);

   // Scale with map size.
   float cliffMinSize = rmTilesToAreaFraction(325 * getMapAreaSizeFactor());
   float cliffMaxSize = rmTilesToAreaFraction(380 * getMapAreaSizeFactor());

   // Definition.
   float avoidCliffMeters = 45.0;

   int cliffOriginAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(6), rmZTilesToFraction(6));
   int cliffAvoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, 1.0);
   int cliffAvoidForests = rmCreateClassDistanceConstraint(forestClassID, 5.0);

   int cliffID = rmAreaDefCreate("cliff");
   rmAreaDefSetMix(cliffID, baseMixID);
   rmAreaDefSetSizeRange(cliffID, cliffMinSize, cliffMaxSize);
   rmAreaDefSetCliffType(cliffID, cCliffNorseSnow);
   rmAreaDefSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
   rmAreaDefSetCliffRampSteepness(cliffID, 2.0);
   rmAreaDefSetCliffEmbellishmentDensity(cliffID, 0.25);
   rmAreaDefSetAvoidSelfDistance(cliffID, avoidCliffMeters);
   rmAreaDefSetHeightRelative(cliffID, 7.0);
   rmAreaDefAddHeightBlend(cliffID, cBlendCliffSide, cFilter3x3Gaussian, 1);
   int cliffRampBlendIdx = rmAreaDefAddHeightBlend(cliffID, cBlendCliffRamp, cFilter5x5Gaussian, 12, 12, true, true);
   rmAreaDefAddHeightBlendExpansionConstraint(cliffID, cliffRampBlendIdx, vDefaultAvoidImpassableLand2);
   rmAreaDefSetEdgeSmoothDistance(cliffID, 10);
   rmAreaDefSetCoherence(cliffID, 0.25);
   rmAreaDefAddConstraint(cliffID, avoidSettlementArea);
   rmAreaDefAddConstraint(cliffID, avoidCenter10);
   rmAreaDefAddConstraint(cliffID, vDefaultAvoidTowerLOS);
   rmAreaDefAddConstraint(cliffID, cliffAvoidPlayerArea);
   rmAreaDefAddConstraint(cliffID, cliffAvoidForests);
   rmAreaDefAddOriginConstraint(cliffID, cliffOriginAvoidEdge);
   rmAreaDefSetOriginConstraintBuffer(cliffID, 5.0);
   rmAreaDefAddToClass(cliffID, cliffClassID);
   if(gameIs1v1())
   {
      if(xsRandBool(0.5))
      {
         addSimAreaLocsPerPlayerPair(cliffID, 1, 65.0, 85.0, avoidCliffMeters * 1.25, cBiasNone, cInAreaDefault, cLocSideRandom);

         addSimAreaLocsPerPlayerPair(cliffID, 1, 95.0, (cMapSizeCurrent > cMapSizeStandard) ? -1.0 : 125.0, avoidCliffMeters * 1.25, 
                                    cBiasNone, cInAreaDefault,  cLocSideOpposite);
      }
      else
      {
         addSimAreaLocsPerPlayerPair(cliffID, 1, 75.0, 120.0, avoidCliffMeters);
      }
      if(cMapSizeCurrent > cMapSizeStandard)
      {
         addAreaLocsPerPlayer(cliffID, 1 * getMapSizeBonusFactor() - 1, 85.0, -1.0, avoidCliffMeters);
      }  

      generateLocs("cliff locs");
   }
   else
   {
      buildAreaDefInTeamAreas(cliffID, xsRandInt(1, 2) * getMapAreaSizeFactor());
   }

   rmSetProgress(0.5);

   // Override the SimLocs variation with a significantly higher value to introduce
   // much more variety without compromising the competitive treatment.

   // The simLocs overrides for this map specifically will be set after the placement of settlements.

   vSimLocDefaultRadiusVar *= 1.35; // ± 7.5m → 10.1m.
   vSimLocDefaultAngleVar *= 1.7; // ± 11,25° → 19,1°.

   // Gold.
   int numGoldPerPlayer = xsRandInt(2, 4); // Exclude map factor here.

   float avoidGoldMeters = (numGoldPerPlayer == 2) ? 70.0 : 60.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidCenter8);
   addObjectDefPlayerLocConstraint(bonusGoldID, 68.0);
   if(gameIs1v1() == true)
   {
      // The gold mines will have their own radial and angular variation.
      int[] goldLocsIDs = addMirroredLocsPerPlayerPair(numGoldPerPlayer * getMapAreaSizeFactor(), 68.0, -1.0, avoidGoldMeters, cBiasNone, 
                                                      cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);

      // If the number of gold mines is lower, the radial and angular variation will be smaller.

      // If the quantity is at the maximum, the global radial and angular variation overridden on the map will be applied.
      float goldRadialVar = (numGoldPerPlayer == 2) ? cSimLocDefaultRadiusVar : vSimLocDefaultRadiusVar;
      float goldAngularVar = (numGoldPerPlayer == 2) ? cSimLocDefaultAngleVar : vSimLocDefaultAngleVar;

      setLocsRadiusVariance(goldLocsIDs, goldRadialVar);
      setLocsAngleVariance(goldLocsIDs, goldAngularVar);

      setLocsObject(goldLocsIDs, bonusGoldID, false);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, numGoldPerPlayer * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);

   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, 1);
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   rmObjectDefAddItem(closeHuntID, cUnitTypeAurochs, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidCenter8);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   rmObjectDefAddConstraint(closeHuntID, createPlayerLocDistanceConstraint(55.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 85.0, avoidHuntMeters);
   }

   // Far hunt.
   int numFarHuntSpawns = 0;

   int farHuntID = rmObjectDefCreate("far hunt");
   if(xsRandBool(0.6) == true)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(7, 11));
      numFarHuntSpawns = 1;
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(5, 6));
      numFarHuntSpawns = 2;
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, avoidCenter8);
   addObjectDefPlayerLocConstraint(farHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, numFarHuntSpawns, 70.0, 100.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, numFarHuntSpawns, 60.0, 100.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(3, 6));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidCenter8);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 70.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidCenter12);
   addObjectDefPlayerLocConstraint(berriesID, 60.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapAreaSizeFactor(), 60.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   int centerHerdID = rmObjectDefCreate("center herd");
   rmObjectDefAddItem(centerHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(centerHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(centerHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(centerHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(centerHerdID, rmCreateAreaConstraint(realGhostLakeID));
   rmObjectDefAddConstraint(centerHerdID, rmCreateAreaEdgeDistanceConstraint(realGhostLakeID, 16.0));
   addObjectDefPlayerLocConstraint(centerHerdID, 60.0);
   addObjectLocsPerPlayer(centerHerdID, false, 1 * getMapSizeBonusFactor(), 60.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypePolarBear, xsRandInt(1, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);

   // Statue Definition.
   int statueDefID = rmObjectDefCreate("statue def");
   rmObjectDefAddItem(statueDefID, cUnitTypeStatueMajorGod, 1);

   // Relic Definition.
   int relicDefID = rmObjectDefCreate("relic def");
   rmObjectDefAddItem(relicDefID, cUnitTypeRelic, 1);

   // Torch Definition.
   int torchDefID = rmObjectDefCreate("torch def");
   rmObjectDefAddItem(torchDefID, cUnitTypeTorch, 1);

   // Column Definition.
   int columnDefID = rmObjectDefCreate("column def");
   rmObjectDefAddItem(columnDefID, cUnitTypeColumns, 1);

   // Relic area definition.
   int relicAreaDefID = rmAreaDefCreate("relic area");
   rmAreaDefSetTerrainType(relicAreaDefID, cTerrainNorseSnowGrass2);
   rmAreaDefSetSize(relicAreaDefID, rmTilesToAreaFraction(30));
   rmAreaDefSetCoherence(relicAreaDefID, 0.5);
   rmAreaDefAddConstraint(relicAreaDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddTerrainLayer(relicAreaDefID, cTerrainNorseSnowGrass3, 1, 2);

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicLocID = rmObjectDefCreate("relic loc");
   rmObjectDefAddConstraint(relicLocID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicLocID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicLocID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicLocID, avoidCliffRamps);
   addObjectDefPlayerLocConstraint(relicLocID, 80.0);
   addObjectLocsPerPlayer(relicLocID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   // Run LocGen.
   bool successfulRelics = generateLocs("relic locs", true, false, true, false);

   // Get number of relic locations
   int numRelicLocs = rmLocGenGetNumberLocs();

   // For the tournament, we will only use these custom angles.
   float[] angleCandidates = new float(1, cPiOver2);
   angleCandidates.add(cPiOver2 * 0.45);
   
   int numAngleCandidates = angleCandidates.size();

   for(int i = 0; i < numRelicLocs; i++)
   {
      // LocGen stuff.
      vector relicLoc = rmLocGenGetLoc(i);

      // Relic stuff.
      float relicRotationAngle = angleCandidates[xsRandInt(0, numAngleCandidates - 1)];

      int relicID = rmObjectDefCreateObject(relicDefID);
      rmObjectSetItemRotation(relicID, 0, cItemRotateCustom, relicRotationAngle);
      rmObjectPlaceAtLoc(relicID, 0, relicLoc);

      // Generate the embellishment only if the relic is out of the ice.
      if(rmIsTileAcceptableForConstraint(avoidCenter12, rmXFractionToTiles(relicLoc.x), rmZFractionToTiles(relicLoc.z)))
      {
         // Statue.
         vector statueLoc = relicLoc.translateXZ(rmXTilesToFraction(1), relicRotationAngle);

         float statueAngle = xsVectorAngleAroundY(statueLoc, relicLoc);

         int statueID = rmObjectDefCreateObject(statueDefID);
         rmObjectSetItemRotation(statueID, 0, cItemRotateCustom, statueAngle + cPiOver2);
         rmObjectPlaceAtLoc(statueID, 0, statueLoc);

         // Small Torches.
         vector torchCLoc = relicLoc.translateXZ(rmXTilesToFraction(1), relicRotationAngle - cPiOver2);
         vector torchDLoc = relicLoc.translateXZ(-rmXTilesToFraction(1), relicRotationAngle - cPiOver2);

         int torchCID = rmObjectDefCreateObject(torchDefID);
         rmObjectSetItemVariation(torchCID, 0, 0);
         rmObjectPlaceAtLoc(torchCID, 0, torchCLoc);

         int torchDID = rmObjectDefCreateObject(torchDefID);
         rmObjectSetItemVariation(torchDID, 0, 0);
         rmObjectPlaceAtLoc(torchDID, 0, torchDLoc);

         // Relica area.
         int relicAreaID = rmAreaDefCreateArea(relicAreaDefID);
         rmAreaSetLoc(relicAreaID, relicLoc);
         rmAreaBuild(relicAreaID);
      }

   }

   if(successfulRelics)
   {
      // rmLocGenApply is not necessary here, since it would only be used for a dummy reference object 
      // for angle reference and placement constraints.
      resetLocGen();
   }
   
   rmSetProgress(0.8);

   // Global forests.

   // Now, they should definitely avoid the lake.
   rmAreaDefAddConstraint(forestDefID, avoidCenter12);
   
   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(40.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(60.0));
   
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.9);

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 12.0);
   buildAreaUnderObjectDef(berriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 12.0);

   // Road avoidance.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow2, 2.5);
   
   // Ice avoidance.
   int avoidIce1 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce1, 2.0);
   int avoidIce2 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce2, 2.0);
   int avoidIce3 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce3, 2.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(rockTinyID, avoidIce1);
   rmObjectDefAddConstraint(rockTinyID, avoidIce2);
   rmObjectDefAddConstraint(rockTinyID, avoidIce3);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(rockSmallID, avoidIce1);
   rmObjectDefAddConstraint(rockSmallID, avoidIce2);
   rmObjectDefAddConstraint(rockSmallID, avoidIce3);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreeID, avoidRoad2);
   rmObjectDefAddConstraint(randomTreeID, avoidIce1);
   rmObjectDefAddConstraint(randomTreeID, avoidIce2);
   rmObjectDefAddConstraint(randomTreeID, avoidIce3);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 25;
      int plantsGroupDensity = 5;

      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantSnowBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantSnowShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantSnowFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantSnowGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantSnowFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidIce1);
      rmObjectDefAddConstraint(plantTypeDef, avoidIce2);
      rmObjectDefAddConstraint(plantTypeDef, avoidIce3);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Snow VFX.
   int snowDriftPlainID = rmObjectDefCreate("snow drift plain");
   rmObjectDefAddItem(snowDriftPlainID, cUnitTypeVFXSnowDriftPlain, 1);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefPlaceAnywhere(snowDriftPlainID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // We will add a message with the player names and map seed for debugging and issue tracking.

   // Define map name.
   string MapName = "Ghost Lake - Recalibrated";

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
