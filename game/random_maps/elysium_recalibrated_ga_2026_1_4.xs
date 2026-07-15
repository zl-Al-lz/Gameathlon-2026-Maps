include "lib2/rm_core.xs";

/*
** Elysium | Recalibrated | 
** Treatment for Gameathlon by AL
** Date: June 15, 2026
*/

int[] modAddMirroredLocsInLocs(vector firstLoc = cInvalidVector, vector oppositeLoc = cInvalidVector, int numLocs = 0, 
                              float radialMinDist = 0.0, float radialMaxDist = 0.0, float locDist = 0.0, int bias = cBiasNone,
                              int side = cLocSideRandom)
{
   int[] locsIDs = new int(0, cInvalidID);

   for(int i = 0; i < numLocs; i++)
   {
      // Define radial randomizer.
      int rrID = rmLocGenCreateRadiusRandomizer();
      rmLocGenSetRadiusRandomizerRadius(rrID, radialMinDist, radialMaxDist); 

      // Define angular randomizer.
      int arID = rmLocGenCreateAngleRandomizer();
      addSectorBiases(arID, bias);
      
      // Generate the simlocs.
      int loc1ID = createSimpleLocAtOrigin(firstLoc, locDist, rrID, arID);
      int loc2ID = createSimpleLocAtOrigin(oppositeLoc, locDist, rrID, arID);

      switch(side)
      {
         case cLocSideRandom:
         {
            // Randomize the side for both.
            rmLocGenSetLocAngleParams(loc1ID, true, false);
            rmLocGenSetLocAngleParams(loc2ID, true, false);
            break;
         }
         case cLocSideOpposite:
         {
            // Don't randomize the side (this is default, but do it anyway for readability).
            rmLocGenSetLocAngleParams(loc1ID, false, false);
            rmLocGenSetLocAngleParams(loc2ID, false, false);
            break;
         }
         case cLocSideSame:
         {
            // Don't randomize the side, and rotate the second loc clockwise.
            rmLocGenSetLocAngleParams(loc1ID, false, false);
            rmLocGenSetLocAngleParams(loc2ID, false, true);
            break;
         }
         default:
         {
            rmEchoWarning("Invalid sim loc side type!");
            return locsIDs;
            break;
         }
      }

      locsIDs.add(loc1ID);
      locsIDs.add(loc2ID);
   
   }

   return locsIDs;
}

int[] modAddMirroredLocsFromIDs(int[] ids = default, int numMinLocs = 0, int numMaxLocs = 0, float radialMinDist = 0.0, float radialMaxDist = 0.0,
                                float locDist = 0.0, int bias = cBiasNone, int side = cLocSideRandom,
                                vector(int) getLocForID = [] (int id = cInvalidID) -> vector { return cInvalidVector; }, 
                                int(int) getOwnerForID = [] (int id = cInvalidID) -> int { return 0; })
{
   int numIDs = ids.size();

   int[] allLocsIDs = new int(0, cInvalidID);

   for(int i = 0; i < numIDs; i += 2)
   {
      // Get the paired ids.
      int currentID = ids[i];
      int oppositeID = ids[i + 1];

      // Get their locations.
      vector currentLoc = getLocForID(currentID);
      vector oppositeLoc = getLocForID(oppositeID);

      // Get their owner ids.
      int ownerID = getOwnerForID(currentID);
      int oppositeOwnerID = getOwnerForID(oppositeID);

      // Get their forward angles.
      float ownerForwardAngle = vDefaultPlayerLocForwardAngles[rmGetPlayerLocID(ownerID, 0)];

      float oppositeForwardAngle = vDefaultPlayerLocForwardAngles[rmGetPlayerLocID(oppositeOwnerID, 0)];

      // Generate the mirrored locations.
      int[] mirroredLocIDs = modAddMirroredLocsInLocs(currentLoc, oppositeLoc, xsRandInt(numMinLocs, numMaxLocs), radialMinDist, 
                                                      radialMaxDist, locDist,bias, side);

      // Assign owner ids and forward angles.
      int numMirroredLocs = mirroredLocIDs.size();

      for(int j = 0; j < numMirroredLocs; j += 2)
      {
         int currentLocID = mirroredLocIDs[j];
         int oppositeLocID = mirroredLocIDs[j + 1];

         rmLocGenSetLocOwner(currentLocID, ownerID);
         rmLocGenSetLocForwardAngle(currentLocID, ownerForwardAngle);

         rmLocGenSetLocOwner(oppositeLocID, oppositeOwnerID);
         rmLocGenSetLocForwardAngle(oppositeLocID, oppositeForwardAngle);

         allLocsIDs.add(currentLocID);
         allLocsIDs.add(oppositeLocID);
      }
   }

   return allLocsIDs;
}

bool modIsAngleInRange(float angle = 0.0, float minAngle = 0.0, float maxAngle = 0.0)
{
   angle = makeAngleBetweenZeroAndTwoPi(angle);
   minAngle = makeAngleBetweenZeroAndTwoPi(minAngle);
   maxAngle = makeAngleBetweenZeroAndTwoPi(maxAngle);

   if (minAngle <= maxAngle)
      return angle >= minAngle && angle <= maxAngle;

   // Wrapped interval.
   return angle >= minAngle || angle <= maxAngle;
}

bool isAngleInRangeAbsolute(float angle = 0.0, float minAngle = 0.0, float maxAngle = 0.0, bool absolute = false)
{
   if(modIsAngleInRange(angle, minAngle, maxAngle))
      return true;

   if(absolute)
      return modIsAngleInRange(angle + cPi, minAngle, maxAngle);

    return false;
}

float modTruncateAngleAround(float angle = 0.0, float centerAngle = 0.0, float forbiddenRadius = 0.0, float truncationRadius = 0.0,
                           bool absolute = false)
{
   bool flip = false;

   angle = makeAngleBetweenZeroAndTwoPi(angle);
   centerAngle = makeAngleBetweenZeroAndTwoPi(centerAngle);

   // If using absolute mode, work on the opposite side if applicable.
   if(absolute)
   {
      if(!modIsAngleInRange(angle, centerAngle - forbiddenRadius, centerAngle + forbiddenRadius))
      {
         float opposite = makeAngleBetweenZeroAndTwoPi(angle + cPi);

         if(modIsAngleInRange(opposite, centerAngle - forbiddenRadius, centerAngle + forbiddenRadius))
         {
            angle = opposite;
            flip = true;
         }
      }
   }

   // If it doesn't fall into the fobidden zone, do nothing.
   if(!modIsAngleInRange(angle, centerAngle - forbiddenRadius, centerAngle + forbiddenRadius))
   {
      if(flip)
         return makeAngleBetweenZeroAndTwoPi(angle - cPi);

      return angle;
   }

   float minForbidden = centerAngle - forbiddenRadius;
   float maxForbidden = centerAngle + forbiddenRadius;

   float t = (angle - minForbidden) / (maxForbidden - minForbidden);
   
   // Redistribute to left or right.
   if(t < 0.5)
   {
      angle = centerAngle - truncationRadius + (t * 2.0) * (truncationRadius - forbiddenRadius);
   }
   else
   {
      angle = centerAngle + forbiddenRadius + ((t - 0.5) * 2.0) * (truncationRadius - forbiddenRadius);
   }

   if(flip)
      angle -= cPi;

   return makeAngleBetweenZeroAndTwoPi(angle);
}

float modTruncateMultiAngles(float angle = 0.0, float[] forbiddenAngles = default, float minMultiplier = 0.9, 
                          float maxMultiplier = 1.1, bool absolute = false)
{
   float currentAngle = 0.0;
   float forbiddenRadius = 0.0;
   float truncationRadius = 0.0;

   int numAngles = forbiddenAngles.size();

   for(int i = 0; i < numAngles; i++)
   {
      currentAngle = forbiddenAngles[i];

      forbiddenRadius = currentAngle * (maxMultiplier - 1.0);
      truncationRadius = forbiddenRadius;

      angle = modTruncateAngleAround(angle, currentAngle, forbiddenRadius, truncationRadius, absolute);
   }

   return angle;
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 3, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt2, 2.0);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(134);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   rmSetTeamSpacingModifier(0.875);

   // Placement stuff.
   float playerPlacementFraction = 0.365;
   float playerPlacementAngle = randRadian();

   // If it's 1v1, we'll truncate some angles to avoid completely collapsed positions.
   if(gameIs1v1() && (cMapSizeCurrent == cMapSizeStandard))
   {
      // Establish the angles we will prohibit.
      float[] forbbidenAngles = new float(1, cPi);
      forbbidenAngles.add(cTwoPi);
      forbbidenAngles.add(cPiOver2);
      forbbidenAngles.add(c3PiOver2);

      int numForbiddenAngles = forbbidenAngles.size();
      
      for(int i = 0; i < numForbiddenAngles; i++)
      {
         float currentAngle = forbbidenAngles[i];
         
         // Compare the randomized angle to see if it falls within the range of any of the forbidden angles.
         if(modIsAngleInRange(playerPlacementAngle, currentAngle * 0.87, currentAngle * 1.13) == true)
         {
            playerPlacementAngle = modTruncateMultiAngles(playerPlacementAngle, forbbidenAngles, 0.8, 1.2);
            if(xsRandBool(0.5) == true)
            {
               // Randomize with its inverted position.
               playerPlacementAngle = -playerPlacementAngle;
            }

            // If the angle was found and truncated, cut here and avoid further unnecessary iterations.
            break;
         }
      }
   }

   rmPlacePlayersOnCircle(playerPlacementFraction, 0.0, 0.0, playerPlacementAngle);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Override the SimLocs variation with a significantly higher value to introduce
   // much more variety without compromising the competitive treatment.
   vSimLocDefaultRadiusVar *= 1.35; // ± 7.5m → 10.1m.
   vSimLocDefaultAngleVar *= 1.7; // ± 11,25° → 19,1°.

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmElysium01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreeOlive);

   // Gameathlon stuff.
   bool isTournamentSeason = true; 

   // Ensure that settlements, gold mines, hunts and areas share the same side.
   int sharedSide = cLocSideOpposite; // Always on the opposite side of this map, this is intentional. Due to space limitations.

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.075, 1, 0.5);

   rmSetProgress(0.1);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   
   generateLocs("starting tower locs");

   // Settlements.
   int settlementAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.25));

   int firstSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(10), rmZTilesToFraction(10));
   int secondSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(12), rmZTilesToFraction(12));

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, firstSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidCenter);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, secondSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidCenter, cObjectConstraintBufferNone, 5.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1 * 1.25, cBiasDefensive, 
                                    cInAreaDefault, sharedSide);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1 * 1.3, cBiasAggressive,
                                    cInAreaDefault, sharedSide);
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
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner32);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.2);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(7, 8));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(7, 8));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.3);

   // Ponds.
   int pondClassID = rmClassCreate();

   float pondMinAreaSize = rmRadiusToAreaFraction(18.0);
   float pondMaxAreaSize = rmRadiusToAreaFraction(20.0);

   int pondDefID = rmAreaDefCreate("pond ");
   rmAreaDefSetSizeRange(pondDefID, pondMinAreaSize, pondMaxAreaSize);
   rmAreaDefSetWaterType(pondDefID, cWaterAtlanteanShallow);
   //rmAreaDefSetBlobs(pondDefID, 3, 4);
   //rmAreaDefSetBlobDistance(pondDefID, 1.0, 5.0);
   rmAreaDefSetCoherence(pondDefID, 0.75);
   rmAreaDefAddConstraint(pondDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(pondDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddToClass(pondDefID, pondClassID);

   // Tiny elevation for the gold.
   int pondElevDefID = rmAreaDefCreate("pond elev ");
   rmAreaDefSetSizeRange(pondElevDefID, 0.05 * pondMinAreaSize, 0.05 * pondMaxAreaSize);
   rmAreaDefSetTerrainType(pondElevDefID, cTerrainAtlanteanDirtRocks1);
   rmAreaDefSetHeightRelative(pondElevDefID, 0.5);
   rmAreaDefAddHeightBlend(pondElevDefID, cBlendAll, cFilter3x3Gaussian, 1);

   // Pond dirt area.
   int pondDirtAreaDefID = rmAreaDefCreate("pond dirt area ");
   rmAreaDefSetSize(pondDirtAreaDefID, 1.0);
   rmAreaDefSetTerrainType(pondDirtAreaDefID, cTerrainAtlanteanGrassDirt3);
   rmAreaDefAddTerrainLayer(pondDirtAreaDefID, cTerrainAtlanteanGrassDirt1, 0, 1);
   rmAreaDefAddTerrainLayer(pondDirtAreaDefID, cTerrainAtlanteanGrassDirt2, 1, 2);

   // Gold.
   int simsGoldsClassID = rmClassCreate();
   int asymmetricGoldClassID = rmClassCreate();

   // These will be surrounded by forest groups afterwards, so more avoidance than usual.
   int goldAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeAbstractSettlement, 28.0);
   int goldAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(9), rmZTilesToFraction(9));
   int goldAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, 30.0); // Let's avoid strangling the center.

   float avoidGoldMeters = 70.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, goldAvoidSettlement);
   rmObjectDefAddConstraint(closeGoldID, goldAvoidEdge);
   addObjectDefPlayerLocConstraint(closeGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      rmObjectDefAddConstraint(closeGoldID, goldAvoidCenter);
      rmObjectDefAddToClass(closeGoldID, simsGoldsClassID);

      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 65.0, 70.0, avoidGoldMeters, cBiasVeryDefensive, cInAreaDefault, sharedSide);
   }
   else
   {
      rmObjectDefAddToClass(closeGoldID, asymmetricGoldClassID);
      addObjectLocsPerPlayer(closeGoldID, false, 1, 65.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, goldAvoidSettlement);
   rmObjectDefAddConstraint(bonusGoldID, goldAvoidEdge);
   addObjectDefPlayerLocConstraint(bonusGoldID, 67.0);
   if(gameIs1v1() == true)
   {
      rmObjectDefAddToClass(bonusGoldID, simsGoldsClassID);

      // Force them to be close to each other to avoid situations where we have a completely clear field.
      setLocPairBindingDistanceRange(80.0, 100.0);

      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1, 67.0, -1.0, avoidGoldMeters, cBiasAggressive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);

      // Reset BindingDist.
      setLocPairBindingDistance();

      addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);

      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1, 75.0, 120.0, avoidGoldMeters, cBiasNotAggressive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);


      addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1, 75.0, -1.0, avoidGoldMeters, cBiasDeadAhead, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      int numGold = (cNumberPlayers < 9) ? 3 : 2;
      rmObjectDefAddToClass(bonusGoldID, asymmetricGoldClassID);
      addObjectLocsPerPlayer(bonusGoldID, false, numGold * getMapSizeBonusFactor(), 75.0, -1.0, avoidGoldMeters);
   }

   // Far gold (1v1 only)
   int farGoldID = rmObjectDefCreate("far gold");
   rmObjectDefAddItem(farGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidCorner32);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farGoldID, goldAvoidSettlement);
   rmObjectDefAddConstraint(farGoldID, goldAvoidEdge);
   rmObjectDefAddToClass(farGoldID, asymmetricGoldClassID);
   addObjectDefPlayerLocConstraint(farGoldID, 75.0);
   if(cMapSizeCurrent > cMapSizeStandard && gameIs1v1())
   {
      addObjectLocsPerPlayer(farGoldID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   // Don't place and reset yet.
   bool successfulGolds = generateLocs("gold locs", true, false, false, false);

   if(successfulGolds)
   {
      int numGoldLocs = rmLocGenGetNumberLocs();

      for(int i = 0; i < numGoldLocs; i++)
      {
         // Get the current LocGenID location.
         vector locGenLoc = rmLocGenGetLoc(i);

         // Build the pond.
         int pondID = rmAreaDefCreateArea(pondDefID);
         rmAreaSetLoc(pondID, locGenLoc);
         rmAreaBuild(pondID, false);

         // Dirt area.
         int pondDirtAreaID = rmAreaDefCreateArea(pondDirtAreaDefID);
         rmAreaSetLoc(pondDirtAreaID, locGenLoc);
         rmAreaAddConstraint(pondDirtAreaID, rmCreateAreaMaxDistanceConstraint(pondID, 10.0));
         rmAreaBuild(pondDirtAreaID);

         rmAreaPaint(pondID);

         // Build the elevation.
         int pondElevID = rmAreaDefCreateArea(pondElevDefID);
         rmAreaSetParent(pondElevID, pondID);
         rmAreaSetLoc(pondElevID, locGenLoc);
         rmAreaBuild(pondElevID);
      }

      // Place the gold mines.
      applyGeneratedLocs();
      
      // Reset LocGen.
      resetLocGen();

      // Do not place the forests yet.
   }
   
   rmSetProgress(0.4);

   // Generic forest stuff.
   int forestClassID = rmClassCreate();

   // Gold forest constraints.
   int goldForestAvoidWater = rmCreateWaterDistanceConstraint(true, 3.0);

   // Start placing the forests around the mines.
   int numMinGoldForests = 3;
   int numMaxGoldForests = 4;

   float goldForestMinDist = 15.0;
   float goldForestMaxDist = 20.0;

   float avoidGoldForestMeters = 15.0;

   int goldForestDefID = rmAreaDefCreate("gold forest ");
   rmAreaDefSetForestType(goldForestDefID, cForestAtlanteanLush);
   rmAreaDefSetSizeRange(goldForestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(50));
   rmAreaDefSetAvoidSelfDistance(goldForestDefID, avoidGoldForestMeters);
   rmAreaDefSetCoherence(goldForestDefID, 0.15);
   rmAreaDefAddConstraint(goldForestDefID, goldForestAvoidWater);
   rmAreaDefAddConstraint(goldForestDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(goldForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddOriginConstraint(goldForestDefID, vDefaultAvoidEdge);
   rmAreaDefAddToClass(goldForestDefID, forestClassID);
   if(gameIs1v1())
   {
      int[] simsGoldIDs = rmClassGetObjects(simsGoldsClassID);

      int[] mirroredLocIDs = modAddMirroredLocsFromIDs(simsGoldIDs, numMinGoldForests, numMaxGoldForests, goldForestMinDist, goldForestMaxDist, 
                                                      avoidGoldForestMeters * 1.35, cBiasNone, isTournamentSeason ? sharedSide : cLocSideRandom,
                                                      [](int id = cInvalidID) -> vector
                                                      {
                                                         return rmObjectGetLoc(id);
                                                      },
                                                      [](int id = cInvalidID) -> int
                                                      {
                                                         return rmObjectGetOwnerID(id);
                                                      });

      // Apply radial and angular variation.
      setLocsRadiusVariance(mirroredLocIDs, vSimLocDefaultRadiusVar);
      setLocsAngleVariance(mirroredLocIDs, vSimLocDefaultAngleVar);

      // place the forests at the generated locations.
      setLocsArea(mirroredLocIDs, goldForestDefID);
   }
   
   // Asymmetric gold.
   int[] asymmetricGoldIDs = rmClassGetObjects(asymmetricGoldClassID);
   int numAsymmetricGolds = asymmetricGoldIDs.size();

   for(int i = 0; i < numAsymmetricGolds; i++)
   {
      addAreaLocsAtOrigin(goldForestDefID, xsRandInt(numMinGoldForests, numMaxGoldForests), rmObjectGetLoc(asymmetricGoldIDs[i]), 
                           goldForestMinDist, goldForestMaxDist, avoidGoldForestMeters * 1.3);
   }

   generateLocs("gold forests locs");

   rmSetProgress(0.5);

   // Starting Forests.
   float avoidForestMeters = 30.0;

   int forestAvoidance = rmCreateClassDistanceConstraint(forestClassID, avoidGoldForestMeters * 1.15);
   int forestOriginAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 15.0);

   float startingForestMinSize = rmTilesToAreaFraction(95);
   float startingForestMaxSize = rmTilesToAreaFraction(100);

   int largeStartingForestDefID = rmAreaDefCreate("large starting forest");
   rmAreaDefSetSizeRange(largeStartingForestDefID, startingForestMinSize, startingForestMaxSize);
   rmAreaDefSetForestType(largeStartingForestDefID, cForestAtlanteanLush);
   rmAreaDefSetAvoidSelfDistance(largeStartingForestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(largeStartingForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(largeStartingForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(largeStartingForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(largeStartingForestDefID, forestAvoidance);
   rmAreaDefAddOriginConstraint(largeStartingForestDefID, forestOriginAvoidPond);
   rmAreaDefAddOriginConstraint(largeStartingForestDefID, forestAvoidance, 4.0);
   rmAreaDefAddOriginConstraint(largeStartingForestDefID, vDefaultAvoidEdge, 6.0);

   int smallStartingForestDefID = rmAreaDefCreate("small starting forest");
   rmAreaDefSetSizeRange(smallStartingForestDefID, startingForestMinSize * 0.5, startingForestMinSize * 0.5);
   rmAreaDefSetForestType(smallStartingForestDefID, cForestAtlanteanLush);
   rmAreaDefSetAvoidSelfDistance(smallStartingForestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(smallStartingForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(smallStartingForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(smallStartingForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(smallStartingForestDefID, forestAvoidance);
   rmAreaDefAddOriginConstraint(smallStartingForestDefID, forestAvoidance, 8.0);
   rmAreaDefAddOriginConstraint(smallStartingForestDefID, vDefaultAvoidEdge, 2.0);

   // Forest placement.
   addAreaLocsPerPlayer(largeStartingForestDefID, 2, cStartingForestMinDist - 3.0, cStartingForestMaxDist, 
                                 avoidForestMeters * 1.5, cBiasBackward);

   addAreaLocsPerPlayer(smallStartingForestDefID, 1, cStartingForestMinDist - 3.0, cStartingForestMaxDist + 3.0, 
                              avoidForestMeters * 1.35, cBiasVeryAggressive);

   generateLocs("starting forest locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(7, 10));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(7, 10));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 60.0, 0.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGazelle, xsRandInt(7, 10));
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 75.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 2.
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   rmObjectDefAddItem(bonusHunt2ID, cUnitTypeDeer, xsRandInt(7, 10));
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 77.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 77.0, -1.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 77.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 3.
   int bonusHunt3ID = rmObjectDefCreate("bonus hunt 3");
   rmObjectDefAddItem(bonusHunt3ID, cUnitTypeCrownedCrane, xsRandInt(7, 10));
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt3ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(5, 11));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(2, 5));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 8));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
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
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(berriesID, false, 1, 70.0, 100.0, avoidBerriesMeters);
      addObjectLocsPerPlayer(berriesID, false, 1, 70.0, -1.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(berriesID, false, 2, 70.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // This map doesn't have predators (yes this is intentional in case you came here to check).

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOlive);

   rmSetProgress(0.8);

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainAtlanteanGrassRocks1, cTerrainAtlanteanGrass1, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrass1, 10.0);

   rmSetProgress(0.9);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockAtlanteanTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockAtlanteanSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainAtlanteanRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainAtlanteanRoad2, 2.5);

   // Random trees placement.
   for(int i = 0; i < 3; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 18 / 2;
      if(i == 2)
      {
         treeDensity = xsRandInt(4, 5);
      }
      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreePalm; treeName = "palm "; break; }
         case 1: { treeTypeID = cUnitTypeTreeOlive; treeName = "olive "; break; }
         case 2: { treeTypeID = cUnitTypeTreeOak; treeName = "oak "; break; }
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
      rmObjectDefPlaceAnywhere(treeDefID, 0, treeDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 30;
      int plantsGroupDensity = 10;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantAtlanteanBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantAtlanteanShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantAtlanteanFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantAtlanteanWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantAtlanteanGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantAtlanteanFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantAtlanteanWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Flowers.
   int flowersID = rmObjectDefCreate("Flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersID, avoidRoad1);
   rmObjectDefAddConstraint(flowersID, avoidRoad2);
   rmObjectDefPlaceAnywhere(flowersID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);   
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Water stuff.
   int waterEmbellishmentAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0);

   int waterReedsID = rmObjectDefCreate("water reeds");
   rmObjectDefAddItemRange(waterReedsID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedsID, waterEmbellishmentAvoidLand);
   rmObjectDefPlaceAnywhere(waterReedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
 
   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
