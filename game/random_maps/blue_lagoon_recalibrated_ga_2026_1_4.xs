include "lib2/rm_core.xs";

/*
** Blue lagoon | Recalibrated | 
** Treatment for Gameathlon by AL
** Date: June 14, 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"rm_blue_lagoon_recalibrated_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
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
   rmCustomMixSetPaintParams(baseMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 1.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptGrassRocks2, 2.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptGrassRocks1, 4.0, 2.0);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(128);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.85, 0.9));
   rmPlacePlayersOnCircle(0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmBlueLagoon01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreePalm);

   // Gameathlon stuff.
   bool isTournamentSeason = true; 

   // Randomize between two ponds per player or, if only one is generated per player, add an extra one in the center.
   int numPondsPerPlayer = xsRandInt(1, 2);

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int sharedSide = xsRandBool(0.5) ? cLocSideOpposite : cLocSideSame;

   // If the pairing is the same, as long as it is only one pond per player + the additional one, never 4 in total.
   if(sharedSide == cLocSideSame)
   {  // This is due to space and area distribution issues.
      numPondsPerPlayer = 1;
   }

   bool additionalPond = (numPondsPerPlayer == 1);
   
   // Since there are many cliffs and lagoons, the tolerance of resources on water and impassable land will be adjusted a little more.
   vDefaultFoodAvoidWater = vDefaultAvoidWater4; // 8 → 4
   vDefaultFoodAvoidImpassableLand = vDefaultAvoidImpassableLand4; // 6 → 4

   vDefaultGoldAvoidImpassableLand = vDefaultAvoidImpassableLand6; // 8 → 6

   // Override the SimLocs variation with a significantly higher value to introduce
   // much more variety without compromising the competitive treatment.
   vSimLocDefaultRadiusVar *= 1.35; // ± 7.5m → 10.1m.
   vSimLocDefaultAngleVar *= 1.7; // ± 11,25° → 19,1°.

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.05, 2, 0.5);

   // Grass area definition.
   int grassAreaDefID = rmAreaDefCreate("grass area ");
   rmAreaDefAddTerrainLayer(grassAreaDefID, cTerrainEgyptGrassDirt3, 0);
   rmAreaDefAddTerrainLayer(grassAreaDefID, cTerrainEgyptGrassDirt2, 1, 2);
   rmAreaDefAddTerrainLayer(grassAreaDefID, cTerrainEgyptGrassDirt1, 3, 4);
   rmAreaDefSetTerrainType(grassAreaDefID, cTerrainEgyptGrass1);
   rmAreaDefSetEdgeSmoothDistance(grassAreaDefID, 4, false);

   // Player beautification.
   float playerAreaSize = rmRadiusToAreaFraction(45.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaDefCreateArea(grassAreaDefID, "player beautification " + p);
      rmAreaSetLocPlayer(playerAreaID, p);
      rmAreaSetSize(playerAreaID, playerAreaSize);
   }

   // Build the areas simultaneously.
   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Pond stuff.
   int pondClassID = rmClassCreate();

   int forceInsidePondEdges = rmCreateClassMaxDistanceConstraint(pondClassID, 0.0, cClassAreaEdgeDistance);

   int pondAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(5.0), rmZMetersToFraction(5.0));
   int pondAvoidOriginEdge = createSymmetricBoxConstraint(rmXMetersToFraction(30.0), rmZMetersToFraction(30.0));

   int avoidBuildings30 = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 30.0);
   int avoidBuildings35 = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 35.0);

   // Pond definition.
   float avoidPondMeters = (numPondsPerPlayer == 2) ? 50.0 : 55.0;

   float pondMinSize = rmTilesToAreaFraction(250);
   float pondMaxSize = rmTilesToAreaFraction(300);

   int pondID = rmAreaDefCreate("pond ");
   rmAreaDefSetWaterType(pondID, cWaterEgyptWateringHole);
   rmAreaDefSetSizeRange(pondID, pondMinSize, pondMaxSize);
   rmAreaDefSetAvoidSelfDistance(pondID, avoidPondMeters, 5.0);
   rmAreaDefSetBlobs(pondID, 3, 5);
   rmAreaDefSetBlobDistance(pondID, 0.0, 10.0);
   rmAreaDefAddConstraint(pondID, pondAvoidEdge);
   rmAreaDefAddConstraint(pondID, avoidBuildings30);
   rmAreaDefAddOriginConstraint(pondID, avoidBuildings35);
   rmAreaDefAddOriginConstraint(pondID, pondAvoidOriginEdge);
   rmAreaDefSetOriginConstraintBuffer(pondID, 10.0);
   rmAreaDefAddToClass(pondID, pondClassID);

   // Center pond.
   int bonusPondID = rmAreaDefCreateArea(pondID, "bonus pond");
   if(additionalPond)
   {
      rmAreaSetSizeRange(bonusPondID, pondMinSize, pondMaxSize);

      // By default it is the center.
      vector bonusPondLoc = cCenterLoc;

      // 60% chance to override the previously established behavior.
      if(xsRandBool(0.6))
      {
         // Since it's for 1v1 and there are only two players, cPiOver2 is more than enough, there's no need to interpolate anything.
         float angleDir = xsVectorAngleAroundY(cCenterLoc, xsVectorRotateXZ(rmGetPlayerLoc(1), cPiOver2, cCenterLoc));
         bonusPondLoc = xsVectorTranslateXZ(bonusPondLoc, smallerMetersToFraction(xsRandFloat(15.0, 20.0)), angleDir);
      }

      rmAreaSetLoc(bonusPondID, bonusPondLoc);
      rmAreaBuild(bonusPondID, false); // Build but don't paint yet.
   }

   // Settlements.
   vDefaultSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(8), rmZTilesToFraction(8)); // Override.

   // Since the area has not been painted yet, there is no water to avoid, so we will use an avoid areas constraint instead.
   int settlementAvoidBonusPond = rmCreateAreaDistanceConstraint(bonusPondID, 16.0, "settlement vs bonus pond");

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidBonusPond);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidBonusPond);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 75.0, cSettlementDist1v1 * 1.15, cBiasBackward, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 65.0, 90.0, cSettlementDist1v1 * 1.15, cBiasAggressive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 65.0, 90.0, cFarSettlementDist, cBiasAggressive | allyBias);
   }
   
   // Other map sizes settlements.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner32);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Place the remaining semi-symmetrical ponds.
   if(gameIs1v1())
   {
      // Ponds will use a smaller radial and angular variation than the global one
      float simLocPondsRadiusVar = cSimLocDefaultRadiusVar * 1.25;
      float simLocPondsAngleVar = cSimLocDefaultAngleVar * 1.25;

      // Generate the mirrored locations first.
      int[] pondLocIDs = addSimLocsPerPlayerPair(numPondsPerPlayer * getMapAreaSizeFactor(), 60.0, -1.0, avoidPondMeters * 1.4, 
                                                cBiasNone, cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);

      // Apply radial and angular variation.
      setLocsRadiusVariance(pondLocIDs, simLocPondsRadiusVar);
      setLocsAngleVariance(pondLocIDs, simLocPondsAngleVar);

      // Place areas at the distorted locations.
      setLocsArea(pondLocIDs, pondID);
   }
   else
   {
      addAreaLocsPerPlayer(pondID, numPondsPerPlayer * getMapAreaSizeFactor(), 60.0, -1.0, avoidPondMeters * 1.35);
   }

   bool successfulPonds = generateLocs("pond locs", true, false, true, false);

   if(successfulPonds)
   {
      rmLocGenApply(true, false); // Same as before, create the locs, build the areas, but don't paint them.
   }

   resetLocGen();
   
   // We will add a layer of beautification to all ponds before painting them.
   int numSuccesfulPonds = rmAreaDefGetNumberCreatedAreas(pondID);

   for(int i = 0; i < numSuccesfulPonds; i++)
   {
      int tempID = rmAreaDefGetCreatedArea(pondID, i);
      vector areaLoc = rmAreaGetLoc(tempID);

      int pondBeautificationLayerID = rmAreaDefCreateArea(grassAreaDefID, "pond grass layer" + i);
      rmAreaSetSize(pondBeautificationLayerID, 1.0);
      rmAreaSetCoherence(pondBeautificationLayerID, 0.25);
      rmAreaSetLoc(pondBeautificationLayerID, areaLoc);
      rmAreaAddConstraint(pondBeautificationLayerID, rmCreateAreaMaxDistanceConstraint(tempID, 15.0));
      rmAreaBuild(pondBeautificationLayerID);
   }

   // Paint all the ponds.
   rmAreaPaintAll();

   rmSetProgress(0.4);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                           cBiasNotAggressive);
   
   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeGiraffe, 4);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Starting forests.
   int forestClassID = rmClassCreate();

   float avoidForestMeters = 28.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalmGrassMix);
   //rmAreaDefSetBlobs(forestDefID, 4, 5);
   //rmAreaDefSetBlobDistance(forestDefID, 10.0);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater12);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidImpassableLand14);
   rmAreaDefAddToClass(forestDefID, forestClassID);

   // No simlocs here in 1v1.
   addAreaLocsPerPlayer(forestDefID, 4, cStartingForestMinDist - 2.0, cStartingForestMaxDist - 2.0, avoidForestMeters * 1.3);

   // Prioritize the starting forests over the cliffs.
   generateLocs("starting forest locs");

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Cliffs.
   float avoidCliffMeters = 25.0;

   int cliffClassID = rmClassCreate();
   int cliffAvoidance = rmCreateClassDistanceConstraint(cliffClassID, avoidCliffMeters);

   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(250);

   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);
   int cliffAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0));
   int cliffAvoidPlayerLoc = createPlayerLocDistanceConstraint(50.0);
   int cliffAvoidStartingForest = rmCreateClassDistanceConstraint(forestClassID, 10.0);
   
   int numCliffsPerPlayer = 5 * cNumberPlayers * getMapAreaSizeFactor();

   for(int i = 0; i < numCliffsPerPlayer; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);
      rmAreaSetCliffType(cliffID, cCliffEgyptSand);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.2);
      rmAreaSetCliffSideRadius(cliffID, 0, 1);
      rmAreaSetCliffSideSheernessThreshold(cliffID, degToRad(45.0));
      rmAreaSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
      rmAreaSetCliffRampSteepness(cliffID, 2.25);
      rmAreaSetSizeRange(cliffID, cliffMinSize, cliffMaxSize);
      rmAreaSetCoherence(cliffID, 0.5);
      rmAreaSetHeightRelative(cliffID, 6.0);
      int cliffSideBlendIDx = rmAreaAddHeightBlend(cliffID, cBlendCliffSide, cFilter3x3Gaussian, 1);
      int cliffRampBlendIDx = rmAreaAddHeightBlend(cliffID, cBlendCliffRamp, cFilter5x5Gaussian, 8, 8, true, true);
      rmAreaAddHeightBlendExpansionConstraint(cliffID, cliffRampBlendIDx, vDefaultAvoidImpassableLand2);
      rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
      rmAreaAddConstraint(cliffID, vDefaultAvoidWater6);
      rmAreaAddConstraint(cliffID, cliffAvoidPlayerLoc);
      rmAreaAddConstraint(cliffID, cliffAvoidance);
      rmAreaAddConstraint(cliffID, cliffAvoidStartingForest);
      rmAreaAddOriginConstraint(cliffID, cliffAvoidance, 10.0);
      rmAreaAddOriginConstraint(cliffID, cliffAvoidEdge);
      rmAreaAddOriginConstraint(cliffID, vDefaultAvoidWater20);
      rmAreaSetOriginConstraintBuffer(cliffID, xsRandFloat(5.0, 8.0));
      rmAreaAddToClass(cliffID, cliffClassID);

      if(!rmAreaFindOriginLoc(cliffID))
      {  // Cut to avoid further unnecessary iterations.
         rmAreaSetFailed(cliffID);
         break;
      }

      rmAreaBuild(cliffID);
   }

   // Enable TOB conversion.
   rmSetTOBConversion(true);

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 55.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 65.0, 80.0, avoidGoldMeters, cBiasForward, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 65.0, 80.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt 1.
   float closeHunt1Float = xsRandFloat(0.0, 1.0);

   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   if(closeHunt1Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeZebra, xsRandInt(4, 6));
   }
   else if(closeHunt1Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeGazelle, xsRandInt(6, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 55.0);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(closeHunt1ID, false, 1, 55.0, 85.0, avoidHuntMeters, cBiasNone, cInAreaDefault,
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt1ID, false, 1, 55.0, 85.0, avoidHuntMeters);
   }
   
   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeElephant, 1);
   }
   else
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeRhinoceros, xsRandInt(1, 2), 2.0);
   }
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeGazelle, 2, 2.0);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 65.0);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(closeHunt2ID, false, 1, 65.0, 95.0, avoidHuntMeters, cBiasNone, cInAreaDefault,
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt2ID, false, 1, 65.0, 95.0, avoidHuntMeters);
   }
   
   // Close hunt 3.
   float closeHunt3Float = xsRandFloat(0.0, 1.0);
   int closeHunt3ID = rmObjectDefCreate("close hunt 3");
   if(closeHunt3Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGazelle, xsRandInt(0, 4));
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeZebra, xsRandInt(4, 6));
   }
   else if(closeHunt3Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGazelle, xsRandInt(0, 4));
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeZebra, xsRandInt(4, 9));
   }
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt3ID, 75.0);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(closeHunt3ID, false, 1, 75.0, 105.0, avoidHuntMeters, cBiasNone, cInAreaDefault,
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt3ID, false, 1, 75.0, 105.0, avoidHuntMeters);
   }
   
   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeElephant, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeRhinoceros, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 85.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 85.0, -1.0, avoidHuntMeters, cBiasNone, cInAreaDefault,
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 85.0, -1.0, avoidHuntMeters);
   }

   if(gameIs1v1() == false)
   {
      // Bonus hunt 2.
      int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGazelle, xsRandInt(2, 4));
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGiraffe, xsRandInt(2, 4));
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(bonusHunt2ID, 100.0);
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 100.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 7));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 9));
      }
      else if(largeMapHuntFloat < 2.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(4, 9));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(2, 6));
      }
      else if(largeMapHuntFloat < 3.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeHyena, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

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
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);
   
   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(40.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(50.0));

   rmAreaDefSetOriginConstraintBuffer(forestDefID, 2.0);
   rmAreaDefCreateAndBuildAreas(forestDefID, 9 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Areas under forests.
   int forestSurroundAreaDefID = rmAreaDefCreate("forest surround");
   rmAreaDefSetSize(forestSurroundAreaDefID, 1.0);
   rmAreaDefSetTerrainType(forestSurroundAreaDefID, cTerrainEgyptGrassDirt1);
   rmAreaDefAddTerrainLayer(forestSurroundAreaDefID, cTerrainEgyptGrassDirt2, 0);
   rmAreaDefAddConstraint(forestSurroundAreaDefID, vDefaultAvoidImpassableLand6);
   rmAreaDefAddTerrainConstraint(forestSurroundAreaDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 1.0));
   rmAreaDefAddTerrainConstraint(forestSurroundAreaDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 1.0));

   // Forests areas placement.
   int numForestAreas = rmAreaDefGetNumberCreatedAreas(forestDefID);

   for(int i = 0; i < numForestAreas; i++)
   {
      int forestID = rmAreaDefGetCreatedArea(forestDefID, i);

      vector forestLoc = rmAreaGetLoc(forestID);

      if(forestLoc == cInvalidVector)
      {
         continue;
      }

      // Build an area around the forest, but do not overpaint the original forest (or grass that is already there).
      int forestSurroundID = rmAreaDefCreateArea(forestSurroundAreaDefID);
      rmAreaSetLoc(forestSurroundID, forestLoc);
      rmAreaAddConstraint(forestSurroundID, rmCreateAreaMaxDistanceConstraint(forestID, 6.0));
      rmAreaAddTerrainConstraint(forestSurroundID, rmCreateAreaDistanceConstraint(forestID, 1.0));

      rmAreaBuild(forestSurroundID);
   }

   rmSetProgress(0.9);

   // Embellishment.
   
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass2, cTerrainEgyptGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Plant constraints.

   // Grass avoidance.
   int avoidEgyptGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 2.5);
   int avoidEgyptGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 2.5);

   int avoidEgyptGrassDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt1, 2.5);
   int avoidEgyptGrassDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt2, 2.5);
   int avoidEgyptGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt3, 2.5);

   int avoidEgyptGrassRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassRocks1, 2.5);
   int avoidEgyptGrassRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassRocks2, 2.5);

   // Sand & Dirt avoidance.
   int avoidEgyptSand1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand1, 2.5);
   int avoidEgyptSand2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand2, 2.5);
   int avoidEgyptSand3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand3, 2.5);

   int avoidEgyptDirtRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks1, 2.5);
   int avoidEgyptDirtRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks2, 2.5);

   int avoidEgyptDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt1, 2.5);
   int avoidEgyptDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt2, 2.5);
   int avoidEgyptDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt3, 2.5);

   // Road avoidance.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 2.5);
   int avoidRoad3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad3, 2.5);

   // Random tree palm.
   int randomTreePalmID = rmObjectDefCreate("random tree palm");
   rmObjectDefAddItem(randomTreePalmID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePalmID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePalmID, avoidRoad2);
   rmObjectDefPlaceAnywhere(randomTreePalmID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Random tree savannah.
   int randomTreeSavannahID = rmObjectDefCreate("random tree savannah");
   rmObjectDefAddItem(randomTreeSavannahID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeSavannahID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreeSavannahID, avoidRoad2);
   rmObjectDefPlaceAnywhere(randomTreeSavannahID, 0, 7 * cNumberPlayers * getMapAreaSizeFactor());

   // Dead plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity = 8;
      int plantsGroupDensity = xsRandInt(3, 4);
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantDeadBush; plantName = "dead plant bush "; break; }
         case 1: { plantID = cUnitTypePlantDeadShrub; plantName = " dead plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantDeadFern; plantName = "dead plant fern "; break; }
         case 3: { plantID = cUnitTypePlantDeadWeeds; plantName = "dead plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantDeadGrass; plantName = "dead plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantDeadFern; plantName = "dead plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantDeadWeeds; plantName = "dead plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad3);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrass1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrass2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt3);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassRocks2);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Grass Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity = 18;
      int plantsGroupDensity = 4;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantEgyptianBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantEgyptianShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantEgyptianFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantEgyptianGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantEgyptianFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad3);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptSand1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptSand2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptSand3);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirtRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirtRocks2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt3);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Pond bush.
   int pondBushID = rmObjectDefCreate("pond bush");
   rmObjectDefAddItemRange(pondBushID, cUnitTypePlantEgyptianBush, 1, 5, 1.0);
   rmObjectDefAddConstraint(pondBushID, forceInsidePondEdges);
   rmObjectDefPlaceAnywhere(pondBushID, 0, 5 * numSuccesfulPonds);

   // Pond fern.
   int pondFernID = rmObjectDefCreate("pond fern");
   rmObjectDefAddItemRange(pondFernID, cUnitTypePlantEgyptianFern, 1, 4, 1.0);
   rmObjectDefAddConstraint(pondFernID, forceInsidePondEdges);
   rmObjectDefPlaceAnywhere(pondFernID, 0, 5 * numSuccesfulPonds);

   // Pond grass.
   int pondGrassID = rmObjectDefCreate("pond grass");
   rmObjectDefAddItemRange(pondGrassID, cUnitTypePlantEgyptianGrass, 1, 3, 1.0);
   rmObjectDefAddConstraint(pondGrassID, forceInsidePondEdges);
   rmObjectDefPlaceAnywhere(pondGrassID, 0, 3 * numSuccesfulPonds);

   // Pond weeds.
   int pondWeedsID = rmObjectDefCreate("pond weeds");
   rmObjectDefAddItemRange(pondWeedsID, cUnitTypePlantEgyptianWeeds, 2, 5, 1.0);
   rmObjectDefAddConstraint(pondWeedsID, forceInsidePondEdges);
   rmObjectDefPlaceAnywhere(pondWeedsID, 0, 5 * numSuccesfulPonds);

   // Flowers.
   int flowersID = rmObjectDefCreate("flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersID, avoidRoad1);
   rmObjectDefAddConstraint(flowersID, avoidRoad2);
   rmObjectDefAddConstraint(flowersID, avoidRoad3);
   rmObjectDefAddConstraint(flowersID, avoidEgyptSand1);
   rmObjectDefAddConstraint(flowersID, avoidEgyptSand2);
   rmObjectDefAddConstraint(flowersID, avoidEgyptSand3);
   rmObjectDefAddConstraint(flowersID, avoidEgyptDirtRocks1);
   rmObjectDefAddConstraint(flowersID, avoidEgyptDirtRocks2);
   rmObjectDefAddConstraint(flowersID, avoidEgyptDirt1);
   rmObjectDefAddConstraint(flowersID, avoidEgyptDirt2);
   rmObjectDefAddConstraint(flowersID, avoidEgyptDirt3);
   rmObjectDefPlaceAnywhere(flowersID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad3);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptSand1);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptSand2);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptSand3);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptDirtRocks1);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptDirtRocks2);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptDirt1);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptDirt2);
   rmObjectDefAddConstraint(flowersGroupID, avoidEgyptDirt3);
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Water lilies.
   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 3.0, "lily vs land");
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "force lily near land");

   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 10 * numSuccesfulPonds);

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItemRange(waterLilyGroupID, cUnitTypeWaterLily, 2, 4, 2.0, 4.0);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 3 * numSuccesfulPonds);

   int waterLilyRedID = rmObjectDefCreate("lily red");
   rmObjectDefAddItem(waterLilyRedID, cUnitTypeWaterLilyRed, 1);
   rmObjectDefAddConstraint(waterLilyRedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedID, 0, 10 * numSuccesfulPonds);

   int waterLilyRedGroupID = rmObjectDefCreate("lily red group");
   rmObjectDefAddItemRange(waterLilyRedGroupID, cUnitTypeWaterLilyRed, 2, 4, 2.0, 4.0);
   rmObjectDefAddConstraint(waterLilyRedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedGroupID, 0, 3 * numSuccesfulPonds);

   // Papyrus.
   int papyrusAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "papyrus vs land");
   int forcePapyrusNearLand = rmCreateWaterMaxDistanceConstraint(false, 5.0, "force papyrus near land");

   int papyrusID = rmObjectDefCreate("papyrus");
   rmObjectDefAddItem(papyrusID, cUnitTypePapyrus, 1);
   rmObjectDefAddConstraint(papyrusID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusID, 0, 12 * numSuccesfulPonds);

   int papyrusGroupID = rmObjectDefCreate("papyrus group");
   rmObjectDefAddItemRange(papyrusGroupID, cUnitTypePapyrus, 3, 5);
   rmObjectDefAddConstraint(papyrusGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusGroupID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusGroupID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusGroupID, 0, 3 * numSuccesfulPonds);

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "reed vs land");
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0, "force reed near land");

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 6 * numSuccesfulPonds);

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItem(waterReedGroupID, cUnitTypeWaterReeds, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedGroupID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 2 * numSuccesfulPonds);

   // Seaweeds near from the shores.
   int shoreSeaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(shoreSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMaxWaterDepthConstraint(2.35));
   rmObjectDefPlaceAnywhere(shoreSeaweedID, 0, 8 * numSuccesfulPonds);

   // Water plants.
   int waterPlantID = rmObjectDefCreate("water plant shores");
   rmObjectDefAddItem(waterPlantID, cUnitTypeWaterPlant, 1);
   rmObjectDefAddConstraint(waterPlantID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(waterPlantID, rmCreateMaxWaterDepthConstraint(2.6));
   rmObjectDefPlaceAnywhere(waterPlantID, 0, 8 * numSuccesfulPonds);

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // We will add a message with the player names and map seed for debugging and issue tracking.

   // Define map name.
   string MapName = "Blue Lagoon - Recalibrated";

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

   // Lighting override.
   lightingOverride();

   rmSetProgress(1.0);
}
