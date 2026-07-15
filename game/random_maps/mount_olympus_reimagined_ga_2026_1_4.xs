include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

/*
** Mount Olympus (Reimagined)
** Author: AL (AoM DE XS CODE)
** Based on "Mount Olympus" by AoM Team
** Date: June 6, 2026
** Designed for Gameathlon 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"rm_mount_olympus_reimagined_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

void gaiaStoneWalls()
{
   rmTriggerAddScriptLine("rule _stonewall");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("trTechSetStatus(0, cTechStoneWall, 2);");
   rmTriggerAddScriptLine("xsDisableSelf();");
   rmTriggerAddScriptLine("}");
}

void gaiaAge4()
{
   rmTriggerAddScriptLine("rule _gaiaAge4");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("trTechSetStatus(0, cTechMythicAgeHephaestus, 2);");
   rmTriggerAddScriptLine("xsDisableSelf();");
   rmTriggerAddScriptLine("}");
}

float modGetAngularDeltaAroundLoc(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc)
{
   vector locADir = locA - referenceLoc;
   float angleA = atan2(locADir.z, locADir.x);

   vector locBDir = locB - referenceLoc;
   float angleB = atan2(locBDir.z, locBDir.x);

   return makeAngleBetweenZeroAndTwoPi(angleB - angleA);
}

float modGetFractionOfAngularDelta(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc, 
                                float fraction = 0.5)
{
   fraction = clamp(fraction, 0.0, 1.0);

   float delta = modGetAngularDeltaAroundLoc(locA, locB, referenceLoc);
   return makeAngleBetweenZeroAndTwoPi(delta * fraction);
}

vector modGetAngularInterpolatedLoc(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc, 
                           float fraction = 0.5)
{
   fraction = clamp(fraction, 0.0, 1.0);
   
   // TODO: Should we also consider the angle var?
   return xsVectorRotateXZ(locA, modGetFractionOfAngularDelta(locA, locB, referenceLoc, fraction), referenceLoc);
}

int[] generateMultiPaths(vector[] arr = default, vector referenceLoc = cCenterLoc, int pathDefID = cInvalidID, 
                        int[] constraints = default)
{
   int numLocs = arr.size();
   int[] pathIDs = new int(0, cInvalidID);
   int numConstraints = constraints.size();

   for(int i = 0; i < numLocs; i++)
   {
      int pathID = rmPathDefCreatePath(pathDefID);
      rmPathAddWaypoint(pathID, referenceLoc);
      rmPathAddWaypoint(pathID, arr[i]);
      for(int j = 0; j < numConstraints; j++)
      {
         rmPathAddConstraint(pathID, constraints[j]);
      }
      rmPathBuild(pathID);

      pathIDs.add(pathID);
   }

   return pathIDs;
}

void addMultiPathsToClass(int[] pathIDs = default, int classID = cInvalidID)
{
   int arrSize = pathIDs.size();

   for(int i = 0; i < arrSize; i++)
   {
      rmPathAddToClass(pathIDs[i], classID);
   }
}

int[] createAndPlaceObjectViaDef(int objectDefID = cInvalidID, int playerID = 0, int numObjects = 0, int[] constraints = default)
{
   int numConstraints = constraints.size();
   int[] objectsIDs = new int(0, cInvalidID);

   for(int i = 0; i < numObjects; i++)
   {
      int objectID = rmObjectDefCreateObject(objectDefID);
      for(int j = 0; j < numConstraints; j++)
      {
         rmObjectAddConstraint(objectID, constraints[j]);
      } 

      rmObjectPlaceAnywhere(objectID, 0);
         
      objectsIDs.add(objectID);
   }

   return objectsIDs;
}  

void overrideBeautificationTerrain(int areaID = cInvalidID, int overrideID = 0)
{
   if(overrideID == 0)
   {  // Grass type.
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekSnowGrassRocks1, cTerrainGreekGrassRocks1);
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekSnowGrassRocks2, cTerrainGreekGrassRocks2);
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekSnowGrass3, cTerrainGreekGrass2);
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekSnowGrass2, cTerrainGreekGrass2);
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekSnowGrass1, cTerrainGreekGrass1);
      rmAreaAddTerrainReplacement(areaID, cTerrainGreekRoadSnow, cTerrainGreekRoad1);
   }
   else
   {
      rmEchoWarning("invalid override id!");
   }
}

vector[] modCreateVectorIntervals(vector[] arrLocs = default, int jumpEvery = 0, int skipStart = 0, int skipEnd = 0)
{
   vector[] result = new vector(0, cOriginVector);

   int numLocs = arrLocs.size();

   if(numLocs <= 0 || jumpEvery <= 0)
   {
      return result;
   }

   if(skipStart < 0) skipStart = 0;
   if(skipEnd < 0) skipEnd = 0;

   int startIndex = skipStart;
   int endIndex = numLocs - 1 - skipEnd;

   if(startIndex > endIndex)
   {
      return result;
   }

   result.add(arrLocs[startIndex]);

   for(int i = startIndex + jumpEvery; i < endIndex; i += jumpEvery)
   {
      result.add(arrLocs[i]);
   }

   vector lastAdded = result[result.size() - 1];
   vector lastTile  = arrLocs[endIndex];

   if(xsVectorLength(lastAdded - lastTile) > 0.01)
   {
      result.add(lastTile);
   }

   return result;
}

// Just to test oop here.
class rampType
{
   // Atributes
   int numRamps = 0;
   float rampRadius = 0.0;
   float rampAngle = 0.0;

   int[] rampPathIDs = default;
   vector[] rampLocs = default;

   // Methods

   // Setter
   void setNumRamps(int pRamps = 0)
   {
      numRamps = pRamps;
   }

   void setRampAngle(float pAngle = 0.0)
   {
      rampAngle = pAngle;
   }

   void setRampRandAngle()
   {
      rampAngle = randRadian();
   }

   void setRampRadius(float pRadius = 0.0)
   {
      rampRadius = pRadius;
   }

   void setRampLocs()
   {
      rampLocs = placeLocationsInCircle(numRamps, rampRadius, rampAngle);
   }

   void generateRampPaths(int pathDefID = cInvalidID, vector pReferenceLoc = cCenterLoc, int[] pathConstraints = default)
   {
      rampPathIDs = generateMultiPaths(rampLocs, pReferenceLoc, pathDefID, pathConstraints);
   }

   void setClassToRampPaths(int classID = cInvalidID)
   {
      addMultiPathsToClass(rampPathIDs, classID);
   }

   // Getter.
   // These aren't used, but oh well, I decided to add them out of habit.
   int getNumRamps()
   {
      return numRamps;
   }

   float getRampRadius()
   {
      return rampRadius;
   }

   float getRampAngle()
   {
      return rampAngle;
   }

   vector[] getRampLocs()
   {
      return rampLocs;
   }

   int[] getRampPaths()
   {
      return rampPathIDs;
   }

};

class beautificationObjectType
{
   int[] beautificationIDs = default;

   void addCandidate(int id = cInvalidID)
   {
      beautificationIDs.add(id);
   }

   int getRandCandidate()
   {
      int sizeMinus1 = beautificationIDs.size() - 1;

      return beautificationIDs[xsRandInt(0, sizeMinus1)];
   }

};

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.075, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnow1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass3, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 2.0);

   int upperHillMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(upperHillMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(upperHillMixID, cTerrainGreekSnow1, 4.0);
   rmCustomMixAddPaintEntry(upperHillMixID, cTerrainGreekSnow2, 2.0);
   rmCustomMixAddPaintEntry(upperHillMixID, cTerrainGreekSnow3, 1.0);
   rmCustomMixAddPaintEntry(upperHillMixID, cTerrainGreekSnowGrass1, 2.0);

   int grassMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(grassMixID, cNoiseFractalSum, 0.3, 1);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainGreekGrass2, 3.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainGreekGrass1, 2.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainGreekGrassDirt1, 1.0);

   // Custom forest.
   int forestTypeID = rmCustomForestCreate();
   rmCustomForestSetTerrain(forestTypeID, cTerrainGreekForestSnow);
   rmCustomForestAddTreeType(forestTypeID, cUnitTypeTreePineSnow, 4.0);
   rmCustomForestAddTreeType(forestTypeID, cUnitTypeTreePine, 2.0);
   rmCustomForestAddTreeType(forestTypeID, cUnitTypeTreeOak, 1.0);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantSnowWeeds, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantSnowGrass, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantSnowBush, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypeRockGreekTiny, 0.2);

   // Map size and terrain init.
   int axisTiles = gameIs1v1() ? getScaledAxisTiles(170) : getScaledAxisTiles(165);
   rmSetMapSize(axisTiles);
   rmInitializeLand(cTerrainGreekCliff1);

   // Compute the players to obtain their actual placement order.
   int[] computedPlayers = rmComputePlayersForPlacement();

   // Player placement.
   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnCircle(0.32);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCiv(cCivZeus);

   // Lighting.
   rmSetLighting(cLightingSetRmMountOlympus01);

   // Default tree type.
   rmSetDefaultTreeType(cUnitTypeTreePine);

   // Gameathlon stuff.
   bool isTournamentSeason = true;

   // We’ll use only one shared herd for the tournament.
   int mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypeCow;

   // Make sure that settlements and gold mines share the same type of side.
   int sharedSide = cLocSideOpposite; // No side same here.

   // A much smaller simloc overwrite on this map.
   vSimLocDefaultRadiusVar *= 1.35;
   vSimLocDefaultAngleVar *= 1.45;

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 15.0, 0.1, 2, 0.5);

   rmSetProgress(0.1);

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Ramp Path Defition.
   int rampPathDefID = rmPathDefCreate("ramp path def");

   // Olympus class stuff.
   int olympusClassID = rmClassCreate("olympus class");

   int forceNearOlympusAreasXL = rmCreateClassMaxDistanceConstraint(olympusClassID, 60.0 + (4.5 * cNumberPlayers) + 
                                                                    (2.5 * getMapSizeBonusFactor()), cClassAreaDistance, 
                                                                    "force anything near olympus");

   int forceInsideOlympusAreas = rmCreateClassMaxDistanceConstraint(olympusClassID, 0.0, cClassAreaDistance, 
                                                                     "force anything inside olympus");

   int avoidOlympusClass5 = rmCreateClassDistanceConstraint(olympusClassID, 5.0, cClassAreaDistance, "anything vs olympus 5");

   // Continent Definition.
   int olympusDefID = rmAreaDefCreate("olympus definition");
   rmAreaDefSetMix(olympusDefID, baseMixID);
   rmAreaDefSetHeight(olympusDefID, 20.0);
   rmAreaDefSetHeightNoise(olympusDefID, cNoiseFractalSum, 5.0, 0.1, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(olympusDefID, 1.0); // Only grow upwards.
   rmAreaDefAddHeightBlend(olympusDefID, cBlendEdge, cFilter5x5Gaussian, 3, 3);
   rmAreaDefSetCliffType(olympusDefID, cCliffGreekGrassSnow);
   rmAreaDefSetCliffSideRadius(olympusDefID, 0, 2);
   rmAreaDefSetCliffEmbellishmentDensity(olympusDefID, 0.0);
   rmAreaDefSetCliffLayerPaint(olympusDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(olympusDefID, cCliffLayerOuterSideFar, false);
   rmAreaDefAddToClass(olympusDefID, olympusClassID);

   // Center continent.
   int continentID = rmAreaDefCreateArea(olympusDefID, "continent");
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetSize(continentID, 0.545);
   rmAreaBuild(continentID);

   // Continent constraints.
   int forceInsideContinent = rmCreateAreaConstraint(continentID, "force something within the continent");

   int forceInsideInnerContinentEdge = rmCreateAreaEdgeConstraint(continentID, "force only at the edges of the continent");

   int avoidContinent = rmCreateAreaDistanceConstraint(continentID, 1.0, "anything avoid continent");

   // Player areas.
   float playerAreaSize = rmRadiusToAreaFraction(48.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaDefCreateArea(olympusDefID, "player area " + p);
      rmAreaSetLocPlayer(playerAreaID, p);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetCoherence(playerAreaID, 0.35);
      // Ignoring the impassable escarpment within the main continent.
      rmAreaAddCliffEdgeConstraint(playerAreaID, cCliffEdgeIgnored, forceInsideContinent);
   }

   // In this way, each player will have a guaranteed margin for the placement of their resources.
   rmAreaBuildAll();

   // Plateau Template.
   int centerHillClassID = rmClassCreate("center hill class");

   int hillDefID = rmAreaDefCreate("center hill def");
   rmAreaDefSetCoherence(hillDefID, 0.25);
   rmAreaDefSetCliffEmbellishmentDensity(hillDefID, 0.45);
   rmAreaDefSetCliffSideRadius(hillDefID, 1, 1);
   rmAreaDefSetHeightNoise(hillDefID, cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(hillDefID, 1.0);
   int innerBlendID = rmAreaDefAddHeightBlend(hillDefID, cBlendCliffSide, cFilter3x3Gaussian, 1);
   int centerHillRampBlendID = rmAreaDefAddHeightBlend(hillDefID, cBlendCliffRamp, cFilter5x5Gaussian, 30, 30, true, true); 
   rmAreaDefAddHeightBlendExpansionConstraint(hillDefID, centerHillRampBlendID, vDefaultAvoidImpassableLand2);
   rmAreaDefSetEdgeSmoothDistance(hillDefID, 5);
   rmAreaDefSetEdgePerturbDistance(hillDefID, -2.0, 2.0);
   rmAreaDefAddConstraint(hillDefID, createPlayerLocDistanceConstraint(35.0));
   rmAreaDefAddToClass(hillDefID, centerHillClassID);

   // Lower hill. 
   float lowerHillSize = 0.06;

   int lowerHillID = rmAreaDefCreateArea(hillDefID, "lower hill");
   rmAreaSetMix(lowerHillID, baseMixID);
   rmAreaSetCliffType(lowerHillID, cCliffGreekGrassSnow);
   rmAreaSetCliffRampSteepness(lowerHillID, 90.0);
   rmAreaSetLoc(lowerHillID, cCenterLoc);
   rmAreaSetSize(lowerHillID, lowerHillSize);
   rmAreaSetHeightRelative(lowerHillID, 8.0);
   rmAreaSetCliffSideSheernessThreshold(lowerHillID, degToRad(60.0));
   rmAreaBuild(lowerHillID, false);

   // Hills constraints.
   int avoidHills = rmCreateAreaDistanceConstraint(lowerHillID, 1.0, "stay away from hills");

   // Upper hill.
   float upperHillSize = lowerHillSize * 0.2;

   int upperHillID = rmAreaDefCreateArea(hillDefID, "upper hill");
   rmAreaSetParent(upperHillID, lowerHillID);
   rmAreaSetCliffType(upperHillID, cCliffGreekSnow);
   rmAreaSetCliffRampSteepness(upperHillID, 70.0);
   rmAreaSetMix(upperHillID, upperHillMixID);
   rmAreaSetLoc(upperHillID, cCenterLoc);
   rmAreaSetHeightRelative(upperHillID, 6.0);
   rmAreaSetCliffSideSheernessThreshold(upperHillID, degToRad(75.0));
   rmAreaSetSize(upperHillID, upperHillSize);
   rmAreaAddConstraint(upperHillID, rmCreateAreaEdgeDistanceConstraint(lowerHillID, 15.0));
   rmAreaBuild(upperHillID, false);

   // Upper hill constraints.
   int avoidUpperHill = rmCreateAreaDistanceConstraint(upperHillID, 10.0, "stay 10 meters away from the upper hill only");

   // Hill bonus elevation.
   int continentBonusElevationID = rmAreaCreate("continent bonus elevation");
   rmAreaSetParent(continentBonusElevationID, continentID);
   rmAreaSetSize(continentBonusElevationID, 1.0);
   rmAreaSetLoc(continentBonusElevationID, cCenterLoc);
   rmAreaSetHeightRelative(continentBonusElevationID, 7.5);
   rmAreaSetHeightNoise(continentBonusElevationID, cNoiseFractalSum, 5.0, 0.1, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentBonusElevationID, 1.0); // Only grow upwards.
   rmAreaAddHeightBlend(continentBonusElevationID, cFilter5x5Box, cBlendEdge, 12, 12, true);
   rmAreaSetEdgeSmoothDistance(continentBonusElevationID, 10);
   rmAreaAddConstraint(continentBonusElevationID, createPlayerLocDistanceConstraint(25.0));  
   rmAreaAddConstraint(continentBonusElevationID, rmCreateAreaMaxDistanceConstraint(lowerHillID, 25.0));
   rmAreaBuild(continentBonusElevationID);

   // Generate the ramps for the lower hill.
   int lowerHillRampClassID = rmClassCreate("lower hill ramp class");

   rampType lowerHillRamp;
   lowerHillRamp.setNumRamps(3 * sqrt(cNumberPlayers * 2) * getMapAreaSizeFactor());
   lowerHillRamp.setRampRandAngle();
   lowerHillRamp.setRampRadius(rmFractionToAreaRadius(lowerHillSize) * 1.35);
   lowerHillRamp.setRampLocs();
   lowerHillRamp.generateRampPaths(rampPathDefID);
   lowerHillRamp.setClassToRampPaths(lowerHillRampClassID);

   // Paint the lower hill.
   rmAreaAddCliffEdgeConstraint(lowerHillID, cCliffEdgeRamp, rmCreateClassMaxDistanceConstraint(lowerHillRampClassID, 10.0));
   rmAreaPaint(lowerHillID);

   // Repeat the same process for the upper hill.
   int upperHillRampClassID = rmClassCreate("upper hill ramp class");

   rampType upperHillRamp;
   upperHillRamp.setNumRamps(2 * sqrt(cNumberPlayers * 2) * getMapAreaSizeFactor());
   upperHillRamp.setRampRandAngle();
   upperHillRamp.setRampRadius(rmFractionToAreaRadius(upperHillSize) * 1.35);
   upperHillRamp.setRampLocs();
   upperHillRamp.generateRampPaths(rampPathDefID);
   upperHillRamp.setClassToRampPaths(upperHillRampClassID);

   // Apply a layer of snow over the grass terrain to soften the transition between terrain types.
   int upperHillSnowTransitionID = rmAreaCreate("upper hill snow transition");
   rmAreaSetMix(upperHillSnowTransitionID, upperHillMixID);
   rmAreaSetSize(upperHillSnowTransitionID, 1.0);
   rmAreaAddTerrainLayer(upperHillSnowTransitionID, cTerrainGreekSnowGrass3, 0, 1);
   rmAreaAddTerrainLayer(upperHillSnowTransitionID, cTerrainGreekSnowGrass2, 2, 3);
   rmAreaAddTerrainLayer(upperHillSnowTransitionID, cTerrainGreekSnowGrass1, 4, 5);
   rmAreaAddConstraint(upperHillSnowTransitionID, rmCreateAreaMaxDistanceConstraint(upperHillID, 18.0));
   rmAreaAddConstraint(upperHillSnowTransitionID, vDefaultAvoidImpassableLand6);
   rmAreaBuild(upperHillSnowTransitionID);

   // Paint the upper hill.
   rmAreaAddCliffEdgeConstraint(upperHillID, cCliffEdgeRamp, rmCreateClassMaxDistanceConstraint(upperHillRampClassID, 5.0));
   rmAreaPaint(upperHillID);

   // Center temple.
   if(!gameIsKotH())
   {
      int centerTempleID = rmObjectDefCreate("center temple");
      rmObjectDefAddItem(centerTempleID, cUnitTypeTempleOfTheGods, 1);
      rmObjectDefPlaceAtLoc(centerTempleID, 0, cCenterLoc);
   }

   // Center torch.
   int centerTorchID = rmObjectDefCreate("center torch");
   rmObjectDefAddItem(centerTorchID, cUnitTypeTorch, 1);
   rmObjectDefSetItemVariation(centerTorchID, 0, 0);
   placeObjectDefInCircle(centerTorchID, 0, 8, 14.0, upperHillRamp.getRampAngle() + degToRad(25));

   // Bonus cliffs stuff.
   int bonusCliffClassID = rmClassCreate("bonus cliff class");

   int bonusCliffAvoidance = rmCreateClassDistanceConstraint(bonusCliffClassID, 30.0, cClassAreaDistance, "bonus cliff vs bonus cliff");

   int avoidPlayerLoc = createPlayerLocDistanceConstraint(45.0);
   int bonusCliffAvoidPlayerLoc = createPlayerLocDistanceConstraint(50.0);
   int avoidBuilding20 = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0, true, "anything vs buildings 20");

   // Bonus cliff definition.
   int bonusCliffDefID = rmAreaDefCreate("bonus cliff");
   rmAreaDefSetCliffType(bonusCliffDefID, cCliffGreekGrassSnow);
   rmAreaDefSetCliffPaintInsideAsSide(bonusCliffDefID, true);
   rmAreaDefSetCliffSideRadius(bonusCliffDefID, 0, 1);
   rmAreaDefSetCliffEmbellishmentDensity(bonusCliffDefID, 0.25);
   rmAreaDefSetHeightNoise(bonusCliffDefID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);
   rmAreaDefAddConstraint(bonusCliffDefID, bonusCliffAvoidance);
   rmAreaDefAddConstraint(bonusCliffDefID, bonusCliffAvoidPlayerLoc);
   rmAreaDefAddConstraint(bonusCliffDefID, avoidBuilding20, 2.0);
   rmAreaDefAddToClass(bonusCliffDefID, bonusCliffClassID);

   // Forest stuff.
   int forestClassID = rmClassCreate("forest class");
   int forestAvoidForest = rmCreateClassDistanceConstraint(forestClassID, 24.0, cClassAreaDistance, "forest vs forest");

   // Bonus inner cliff placement.
   float bonusInnerCliffSize = rmTilesToAreaFraction(140);

   for(int i = 0; i < cNumberPlayers; i++)
   {
      // Get the ID of the current index and the next one.
      int locAID = computedPlayers[i];
      int locBID = (i < cNumberPlayers - 1) ? computedPlayers[i + 1] : computedPlayers[0]; // If this is the last iteration, back to index 0

      // Get locs based on IDs.
      vector locA = rmGetPlayerLoc(locAID);
      vector locB = rmGetPlayerLoc(locBID);

      // Interpolate the locs using a more angular approach instead of a vector approach.
      vector loc = modGetAngularInterpolatedLoc(locA, locB, cCenterLoc, 0.5);
      if(gameIs1v1())
      {
         loc = xsVectorTranslateXZ(loc, -0.035, xsVectorAngleAroundY(loc, cCenterLoc));
      }
      
      // Bonus inner cliff.
      int bonusInnerCliffID = rmAreaDefCreateArea(bonusCliffDefID);
      rmAreaSetLoc(bonusInnerCliffID, loc);
      rmAreaSetHeightRelative(bonusInnerCliffID, -10.0);
      rmAreaSetSize(bonusInnerCliffID, bonusInnerCliffSize);
      rmAreaBuild(bonusInnerCliffID);

      // Bonus inner forest.
      int bonusInnerForestID = rmAreaCreate("bonus inner forest" + i);
      rmAreaSetParent(bonusInnerForestID, bonusInnerCliffID);
      rmAreaSetForestType(bonusInnerForestID, forestTypeID);
      rmAreaSetSize(bonusInnerForestID, 1.0);
      rmAreaAddConstraint(bonusInnerForestID, rmCreateCliffSideDistanceConstraint(bonusInnerCliffID, 1.0));
      rmAreaAddToClass(bonusInnerForestID, forestClassID);
      rmAreaBuild(bonusInnerForestID);
   }

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand6);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 120.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidAllWithFarm);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   // Olympus bonus area definition.
   int olympusBonusAreaClassID = rmClassCreate("olympus bonus area class");
   int olympusOuterBonusAreaClassID = rmClassCreate("olympus outer bonus area class only"); // Exclude the paths.

   int avoidOlympusBonusArea = rmCreateClassDistanceConstraint(olympusBonusAreaClassID, 1.0, cClassAreaDistance, 
                                                                "avoid anything within the bonus areas");
   int avoidOlympusBonusArea15 = rmCreateClassDistanceConstraint(olympusBonusAreaClassID, 15.0, cClassAreaDistance, 
                                                                 "stay 15 meters away from bonus areas");
   int avoidOlympusBonusArea20 = rmCreateClassDistanceConstraint(olympusBonusAreaClassID, 20.0, cClassAreaDistance, 
                                                                  "stay 20 meters away from bonus areas");

   int olympusBonusAreaDefID = rmAreaDefCreate("olympus bonus area def");
   rmAreaDefAddHeightBlend(olympusBonusAreaDefID, cBlendEdge, cFilter3x3Gaussian);
   rmAreaDefSetCliffType(olympusBonusAreaDefID, cCliffGreekGrassSnow);
   rmAreaDefSetCliffSideRadius(olympusBonusAreaDefID, 0, 2);
   rmAreaDefSetCliffEmbellishmentDensity(olympusBonusAreaDefID, 0.25);
   rmAreaDefSetCliffLayerPaint(olympusBonusAreaDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(olympusBonusAreaDefID, cCliffLayerOuterSideFar, false);
   rmAreaDefAddToClass(olympusBonusAreaDefID, olympusClassID);
   rmAreaDefAddToClass(olympusBonusAreaDefID, olympusBonusAreaClassID);
   rmAreaDefAddCliffEdgeConstraint(olympusBonusAreaDefID, cCliffEdgeIgnored, rmCreateClassMaxDistanceConstraint(olympusClassID, 
                                  0.0, cClassAreaCliffInsideDistance));

   // Olympus bonus path.
   int olympusBonusPathClassID = rmClassCreate("olympus bonus path class");
   int avoidOlympusPath8 = rmCreateClassDistanceConstraint(olympusBonusPathClassID, 8.0, cClassAreaDistance, 
                                                            "stay away from bonus area paths only");

   // Olympus bonus path definition.
   int olympusBonusPathDefID = rmPathDefCreate("olympus bonus path def");
   rmPathDefAddToClass(olympusBonusPathDefID, olympusBonusPathClassID);

   // Outer gold.
   float avoidOuterGoldMeters = 50.0;

   int customOuterResAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(6), rmZTilesToFraction(6)); // TODO
   int customAvoidEdge8 = createSymmetricBoxConstraint(rmXTilesToFraction(8), rmZTilesToFraction(8));

   int outerGoldID = rmObjectDefCreate("outer gold");
   rmObjectDefAddItem(outerGoldID, isTournamentSeason ? cUnitTypeMineGoldSmall : cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(outerGoldID, customOuterResAvoidEdge);
   rmObjectDefAddConstraint(outerGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(outerGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(outerGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(outerGoldID, rmCreateAreaDistanceConstraint(continentID, 1.0));
   if(isTournamentSeason && gameIs1v1())
   {
      rmObjectDefAddConstraint(outerGoldID, rmCreateAreaEdgeMaxDistanceConstraint(continentID, 8.0));
   }
   else
   {
      rmObjectDefAddConstraint(outerGoldID, rmCreateAreaEdgeMaxDistanceConstraint(continentID, 11.0 + (2.5 * sqrt(cNumberPlayers * 2)) 
                                                                                 * getMapAreaSizeFactor()));
   }
   if(gameIs1v1())
   {
      int numOuterGoldsPerPlayer = isTournamentSeason ? 1 : 2;
      addSimObjectLocsPerPlayerPair(outerGoldID, false, numOuterGoldsPerPlayer, isTournamentSeason ? 70.0 : 60.0, -1.0, avoidOuterGoldMeters, 
                                    cBiasNone, cInAreaDefault, cLocSideOpposite); // Always opposite.
   }
   else
   {
      addObjectLocsPerPlayer(outerGoldID, false, 2, 60.0, -1.0, avoidOuterGoldMeters);
   }

   bool outerGoldPlacementSucceeded = generateLocs("outer gold locs", true, false, true, false);

   // Outer gold areas.
   int goldAreaClassID = rmClassCreate("complete gold area class"); // Include path and gold area.
   int outerGoldAreaClassID = rmClassCreate("outer gold area class");  // Only gold area.

   // Keep outer gold areas from clustering too closely together.
   int avoidGoldAreas = rmCreateClassDistanceConstraint(goldAreaClassID, 25.0, cClassAreaDistance, 
                                                         "stay 25 meters away from the outer gold areas");

   // Outer gold area size.
   float outerGoldAreaMinSize = rmTilesToAreaFraction(250);
   float outerGoldAreaMaxSize = rmTilesToAreaFraction(300);

   // Stores the Mount Olympus connection points used by the gold paths. Future paths will avoid reusing these endpoints.
   vector[] pathEndPointsLocs = new vector(0, cOriginVector);

   if(outerGoldPlacementSucceeded)
   {
      // Process every outer gold location generated by LocGen.
      int numLocs = rmLocGenGetNumberLocs();

      for(int i = 0; i < numLocs; i++)
      {
         // Slightly randomize the elevation so each gold area feels less uniform.
         float goldHeight = xsRandFloat(24.0, 26.0);

         // Find a valid connection point inside Mount Olympus.
         rmAddClosestLocConstraint(forceInsideContinent);
         rmAddClosestLocConstraint(vDefaultAvoidImpassableLand16);
         rmAddClosestLocConstraint(avoidBuilding20);

         // Gold mine location generated by LocGen.
         vector loc = rmLocGenGetLoc(i);

         // Connection endpoint inside Mount Olympus.
         vector pathEndPoint = rmGetClosestLoc(loc, rmXFractionToMeters(1.0));
         
         // Prevent future relic paths from reusing the same endpoint.
         pathEndPointsLocs.add(pathEndPoint);

         // Generate the connection path between the outer gold and Mount Olympus.
         int outerGoldPathID = rmPathDefCreatePath(olympusBonusPathDefID, "outer gold path " + i);
         rmPathAddWaypoint(outerGoldPathID, loc);
         rmPathAddWaypoint(outerGoldPathID, pathEndPoint);
         rmPathSetCostNoise(outerGoldPathID, 0.0, 2.0);
         rmPathBuild(outerGoldPathID);

         // Generate the path area between the outer gold and Mount Olympus.
         int outerGoldPathAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "outer gold path area " + i);
         rmAreaSetPath(outerGoldPathAreaID, outerGoldPathID, 25.0);
         rmAreaSetHeight(outerGoldPathAreaID, goldHeight);
         rmAreaSetHeightNoise(outerGoldPathAreaID, cNoiseFractalSum, 7.5, 0.1, 1, 0.5);
         rmAreaAddHeightBlend(outerGoldPathAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(outerGoldPathAreaID, 0, vDefaultAvoidImpassableLand2);
         rmAreaAddToClass(outerGoldPathAreaID, goldAreaClassID);
         rmAreaBuild(outerGoldPathAreaID);

         // Generate the elevated area that will contain the gold mine.
         int outerGoldAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "outer gold area " + i);
         rmAreaSetLoc(outerGoldAreaID, loc);
         rmAreaSetSizeRange(outerGoldAreaID, outerGoldAreaMinSize, outerGoldAreaMaxSize);
         rmAreaSetHeight(outerGoldAreaID, xsRandFloat(goldHeight * 1.08, goldHeight * 1.2));
         rmAreaSetHeightNoise(outerGoldAreaID, cNoiseFractalSum, 7.5, 0.1, 1, 0.5);
         rmAreaAddHeightBlend(outerGoldAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaSetCoherence(outerGoldAreaID, 0.2);
         rmAreaAddToClass(outerGoldAreaID, goldAreaClassID);
         rmAreaAddToClass(outerGoldAreaID, outerGoldAreaClassID);
         rmAreaAddToClass(outerGoldAreaID, olympusOuterBonusAreaClassID);
         rmAreaBuild(outerGoldAreaID);

         // Clear closest loc constraints in each iteration. Prepare the closest-location system for the next gold mine.
         rmClearClosestLocConstraints();

      }

      // Place the gold mines.
      applyGeneratedLocs();

   }

   // Reset LocGen.
   resetLocGen();

   // Relics.
   float avoidRelicMeters = 60.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, customOuterResAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, rmCreateAreaDistanceConstraint(continentID, 6.0));
   rmObjectDefAddConstraint(relicID, rmCreateAreaEdgeMaxDistanceConstraint(continentID, 14.0 + (2.5 * sqrt(cNumberPlayers * 2)) 
                                                                           * getMapAreaSizeFactor()));
   rmObjectDefAddConstraint(relicID, avoidGoldAreas);
   addObjectDefPlayerLocConstraint(relicID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters, cBiasNone, 
                                    cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters);
   }

   bool relicPlacementSucceeded = generateLocs("relic locs", true, false, true, false);

   // Relic class.
   int relicAreaClassID = rmClassCreate(); 
   
   // Relic areas size.
   float relicAreaMinSize = rmTilesToAreaFraction(310);
   float relicAreaMaxSize = rmTilesToAreaFraction(330);

   // If the relic placement was successful, proceed with generating the areas and objects.
   if(relicPlacementSucceeded)
   {
      // Process every relic location generated by LocGen.
      int numLocs = rmLocGenGetNumberLocs();
      
      for(int i = 0; i < numLocs; i++)
      {
         // Find a valid connection point inside Mount Olympus.
         rmAddClosestLocConstraint(forceInsideContinent);
         rmAddClosestLocConstraint(vDefaultAvoidImpassableLand16);
         rmAddClosestLocConstraint(avoidBuilding20);
         rmAddClosestLocConstraint(rmCreateMultiLocDistanceConstraint(pathEndPointsLocs, 25.0));

         // Relic location generated by LocGen.
         vector loc = rmLocGenGetLoc(i);

         // Connection endpoint inside Mount Olympus.
         vector pathEndPoint = rmGetClosestLoc(loc, rmXFractionToMeters(1.0));
         
         // Prevent future relic paths from reusing the same endpoint.
         pathEndPointsLocs.add(pathEndPoint);

         // Generate the connection path between the relic and Mount Olympus.
         int relicPathID = rmPathDefCreatePath(olympusBonusPathDefID, "relic path " + i);
         rmPathAddWaypoint(relicPathID, loc);
         rmPathAddWaypoint(relicPathID, pathEndPoint);
         rmPathSetCostNoise(relicPathID, 0.0, 2.0);
         rmPathBuild(relicPathID);

         // Generate the path area between the relic and Mount Olympus.
         int relicPathAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "relic path area " + i);
         rmAreaSetPath(relicPathAreaID, relicPathID, 23.0, 3.0);
         rmAreaSetCliffSideRadius(relicPathAreaID, 1, 2);
         rmAreaSetHeight(relicPathAreaID, 25.0);
         rmAreaAddHeightBlend(relicPathAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(relicPathAreaID, 0, vDefaultAvoidImpassableLand2);
         rmAreaBuild(relicPathAreaID);

         // Generate the elevated area that will contain the relic.
         int relicAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "relic area " + i);
         rmAreaSetLoc(relicAreaID, loc);
         rmAreaSetSizeRange(relicAreaID, relicAreaMinSize, relicAreaMaxSize);
         rmAreaSetCliffSideRadius(relicAreaID, 1, 2);
         rmAreaSetHeight(relicAreaID, xsRandFloat(30.0, 32.0));
         int relicAreaBlendAllIdx = rmAreaAddHeightBlend(relicAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(relicAreaID, relicAreaBlendAllIdx, vDefaultAvoidImpassableLand);
         rmAreaAddHeightBlend(relicAreaID, cBlendCliffSide, cFilter3x3Gaussian, 1, 1, true);
         rmAreaSetCoherence(relicAreaID, 0.45);
         rmAreaAddToClass(relicAreaID, relicAreaClassID);
         rmAreaAddToClass(relicAreaID, olympusOuterBonusAreaClassID);
         rmAreaBuild(relicAreaID);
 
         // Clear closest loc constraints. Prepare the closest-location system for the next relic.
         rmClearClosestLocConstraints();
      }

      // Place the relics.
      applyGeneratedLocs();
   }

   // Reset LocGen.
   resetLocGen();

   // Beautification objects.

   // Class used to group decorative elements generated around Mount Olympus.
   int beautificationClassID = rmClassCreate();

   // Standalone decorative objects.
   int beautificationAvoidGold = rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 5.0, true, "beautification vs gold");

   // Columns.
   int columnClassID = rmClassCreate("columns class");
   int columnsAvoidance = rmCreateClassDistanceConstraint(columnClassID, 5.0, cClassAreaDistance, "columns vs columns");

   int columnsDefID = rmObjectDefCreate("column def");
   rmObjectDefAddItem(columnsDefID, cUnitTypeColumns, 1);
   rmObjectDefAddConstraint(columnsDefID, columnsAvoidance);
   rmObjectDefAddConstraint(columnsDefID, beautificationAvoidGold);
   rmObjectDefAddToClass(columnsDefID, columnClassID);

   int columnsBrokenDefID = rmObjectDefCreate("columns broken def");
   rmObjectDefAddItem(columnsBrokenDefID, cUnitTypeColumnsBroken, 1);
   rmObjectDefAddConstraint(columnsBrokenDefID, columnsAvoidance);
   rmObjectDefAddConstraint(columnsBrokenDefID, beautificationAvoidGold);
   rmObjectDefAddToClass(columnsBrokenDefID, columnClassID);

   // Flag.
   int flagDefID = rmObjectDefCreate("flag def");
   rmObjectDefAddItem(flagDefID, cUnitTypeFlag, 1);

   // Road avoidance.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad2, 2.5);
   int avoidRoad3 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoadSnow, 2.5);

   // Beautification Oak.
   int beautificationOakAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeTreeOak, 6.0, true, "oak vs oak");

   int beautificationOakDefID = rmObjectDefCreate("beautification oak");
   rmObjectDefAddItem(beautificationOakDefID, cUnitTypeTreeOak, 1);
   rmObjectDefAddConstraint(beautificationOakDefID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(beautificationOakDefID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(beautificationOakDefID, vDefaultAvoidImpassableLand);
   rmObjectDefAddConstraint(beautificationOakDefID, beautificationOakAvoidance);
   rmObjectDefAddConstraint(beautificationOakDefID, avoidRoad1);
   rmObjectDefAddConstraint(beautificationOakDefID, avoidRoad2);
   rmObjectDefAddConstraint(beautificationOakDefID, avoidRoad3);

   // Beautification flowers.
   int beautificationFlowerAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeFlowers, 5.0, true, 
                                                                     "beautification flower vs beautification flower");

   int beautificationFlowerID = rmObjectDefCreate("beautification flower");
   rmObjectDefAddItemRange(beautificationFlowerID, cUnitTypeFlowers, 1, 2, 1.0, 2.0);
   rmObjectDefAddConstraint(beautificationFlowerID, beautificationFlowerAvoidance);

   // Torch.
   int torchAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeTorch, 5.0, true, "torch vs torch");

   int torchDefID = rmObjectDefCreate("torch def");
   rmObjectDefAddItem(torchDefID, cUnitTypeTorch, 1);
   rmObjectDefAddConstraint(torchDefID, torchAvoidance);
   rmObjectDefAddConstraint(torchDefID, beautificationAvoidGold);
   
   // Temple.
   int templeDefID = rmObjectDefCreate("temple def");
   rmObjectDefAddItem(templeDefID, cUnitTypeTemple, 1);

   // Beautification random objects.

   // Type A and B candidates are primary decorative features.
   int beautificationTypeABDef = rmObjectDefCreate("beautification type AB");
   
   // Type A: Common centerpiece objects.
   beautificationObjectType beautificationObjectTypeA;
   
   beautificationObjectTypeA.addCandidate(cUnitTypeShrine);
   beautificationObjectTypeA.addCandidate(cUnitTypeStatueMajorGod);
   beautificationObjectTypeA.addCandidate(cUnitTypeSkyPassage);

   // Type B: Alternative centerpiece objects with a larger variety of statues.
   beautificationObjectType beautificationObjectTypeB;

   beautificationObjectTypeB.addCandidate(cUnitTypeStatueCyclops);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueHydra);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueNemeanLion);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueManticore);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueChimera);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueValkyrie);
   beautificationObjectTypeB.addCandidate(cUnitTypeStatueMelagius);

   // Type C: Supporting decorative objects used around the main centerpiece.
   int beautificationTypeCDef = rmObjectDefCreate("beautification type C");

   beautificationObjectType beautificationObjectTypeC;

   beautificationObjectTypeC.addCandidate(cUnitTypeTorch);
   beautificationObjectTypeC.addCandidate(cUnitTypeColumns);

   // With the mandatory LocGen locations in place, generate additional unchecked areas around them to enhance the map's appearance.
   int beautificationPathClassID = rmClassCreate("beautification path class");

   int avoidBeautificationPath = rmCreateClassDistanceConstraint(beautificationPathClassID, 2.0, cClassAreaDistance, 
                                                                 "anything vs beautification path");

   // Beautification path definition.
   int beautificationPathDefID = rmPathDefCreate("beautification path def");
   rmPathDefSetCostNoise(beautificationPathDefID, -0.5, 0.5);
   rmPathDefAddConstraint(beautificationPathDefID, vDefaultAvoidImpassableLand6);
   rmPathDefAddToClass(beautificationPathDefID, beautificationPathClassID);

   // Beautification path area definition.
   int beautificationPathAreaDefID = rmAreaDefCreate("beautification path area def");
   rmAreaDefAddConstraint(beautificationPathAreaDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddTerrainConstraint(beautificationPathAreaDefID, beautificationAvoidGold);

   // Temples.

   // Temples are placed near the continent edge but never directly on it.
   int templeAvoidContinent = rmCreateAreaDistanceConstraint(continentID, 3.0);
   int forceTempleNearContinent = rmCreateAreaMaxDistanceConstraint(continentID, 5.0);
   int templeAvoidPlayerLoc = createPlayerLocDistanceConstraint(50.0);

   // Used to prevent temples from clustering together.
   vector[] templeAvoidanceLocs = new vector(0, cOriginVector);

   float templeAreaSize = rmTilesToAreaFraction(220);

   int numTemples = cNumberPlayers * getMapAreaSizeFactor();

   for(int i = 0; i < numTemples; i++)
   {
      // Find a suitable location near the continent edge.
      rmAddClosestLocConstraint(avoidOlympusBonusArea20);
      rmAddClosestLocConstraint(templeAvoidContinent);
      rmAddClosestLocConstraint(forceTempleNearContinent);
      rmAddClosestLocConstraint(customAvoidEdge8);
      rmAddClosestLocConstraint(templeAvoidPlayerLoc);
      rmAddClosestLocConstraint(rmCreateMultiLocDistanceConstraint(templeAvoidanceLocs, 80.0));
      
      // Temple location.
      vector templeLoc = rmGetClosestLoc(cCenterLoc, -1.0);

      // Prevent future temples from reusing nearby locations. 
      templeAvoidanceLocs.add(templeLoc);

      // Clear closest loc constraints.
      rmClearClosestLocConstraints();

      // Proceed only if a valid temple location was found.
      if(xsVectorLength(templeLoc) > 0.02)
      {
         // Find a valid connection point inside Mount Olympus.
         rmAddClosestLocConstraint(forceInsideContinent);
         rmAddClosestLocConstraint(avoidBuilding20);
         rmAddClosestLocConstraint(vDefaultAvoidImpassableLand12);

         // Connection endpoint inside Mount Olympus.
         vector continentClosestLoc = rmGetClosestLoc(templeLoc, -1.0);

         // Clear closest loc constraints.
         rmClearClosestLocConstraints();

         // Generate the connection path between the temple and Mount Olympus.
         int templePathID = rmPathDefCreatePath(olympusBonusPathDefID, "temple path" + i);
         rmPathAddWaypoint(templePathID, continentClosestLoc);
         rmPathAddWaypoint(templePathID, templeLoc);
         // No cost noise here.
         rmPathBuild(templePathID);

         // Generate the path area between the temple and Mount Olympus.
         int templePathAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "temple path area " + i);
         rmAreaSetPath(templePathAreaID, templePathID, 24.0);
         rmAreaSetHeight(templePathAreaID, 25.0);
         rmAreaAddHeightBlend(templePathAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(templePathAreaID, 0, vDefaultAvoidImpassableLand2);
         rmAreaBuild(templePathAreaID);

         // Generate the elevated area that will contain the temple.
         int templeAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "temple area " + i);
         rmAreaSetLoc(templeAreaID, templeLoc);
         rmAreaSetSize(templeAreaID, templeAreaSize);
         rmAreaSetHeight(templeAreaID, 27.0);
         rmAreaSetCliffSideRadius(templeAreaID, 1, 2);
         int templeAreaBlendAllIdx = rmAreaAddHeightBlend(templeAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(templeAreaID, templeAreaBlendAllIdx, vDefaultAvoidImpassableLand);
         rmAreaAddHeightBlend(templeAreaID, cBlendCliffSide, cFilter3x3Gaussian, 1, 1, true);
         rmAreaSetCoherence(templeAreaID, 0.45);
         rmAreaAddToClass(templeAreaID, olympusOuterBonusAreaClassID);
         rmAreaBuild(templeAreaID);

         // Generate beautification path.
         int templeBeautificationPathID = rmPathDefCreatePath(beautificationPathDefID);
         rmPathAddWaypoint(templeBeautificationPathID, templeLoc);
         rmPathAddWaypoint(templeBeautificationPathID, continentClosestLoc);
         rmPathBuild(templeBeautificationPathID);

         // Generate the beautification path area.
         int beautificationPathAreaID = rmAreaDefCreateArea(beautificationPathAreaDefID);
         rmAreaSetPath(beautificationPathAreaID, templeBeautificationPathID, 0.0);
         rmAreaSetTerrainType(beautificationPathAreaID, cTerrainGreekRoadSnow);
         rmAreaBuild(beautificationPathAreaID);

         // Derive the temple orientation from the generated path.
         vector[] pathTiles = rmPathGetTiles(templePathID);
         vector referenceAngleLoc = pathTiles[pathTiles.size() - 6];
         referenceAngleLoc = rmTileIndexToFraction(referenceAngleLoc);

         float templeAngle = xsVectorAngleAroundY(referenceAngleLoc, templeLoc);

         // Place the temple.
         int templeID = rmObjectDefCreateObject(templeDefID);
         rmObjectSetItemRotation(templeID, 0, cItemRotateCustom, templeAngle);
         rmObjectPlaceAtLoc(templeID, 0, templeLoc);

         // Generate decorative objects around the temple entrance.
         int numBeautiObjects = 2;
         vector[] torchLocs = placeLocationsInCircle(numBeautiObjects, 3.5, templeAngle - cPiOver2, 0.0, 0.0, templeLoc);

         for(int j = 0; j < numBeautiObjects; j++)
         {
            vector currentBeautiLoc = torchLocs[j];
            currentBeautiLoc = xsVectorTranslateXZ(currentBeautiLoc, rmXMetersToFraction(8.0), templeAngle);

            // Place a random supporting decorative object.
            int candidateID = beautificationObjectTypeC.getRandCandidate();
            int beautificationUnitTypeID = rmObjectDefCreateObject(beautificationTypeCDef);
            rmObjectAddItem(beautificationUnitTypeID, candidateID);
            rmObjectPlaceAtLoc(beautificationUnitTypeID, 0, currentBeautiLoc);
         }
      }
   }

   // This constraint prevents height mismatches, since the area being connected to has already been painted.
   int avoidInsideOlympusAreaClass = rmCreateClassDistanceConstraint(olympusClassID, 1.0, cClassAreaCliffInsideDistance);

   // Size range for the beautification areas.
   float beautificationAreaMinSize = rmTilesToAreaFraction(120);
   float beautificationAreaMaxSize = rmTilesToAreaFraction(135);

   // Stores the connection endpoints used by beautification paths. Future paths will avoid reusing these locations.
   vector[] beautificationConnectionLocs = new vector(0, cOriginVector);

   int numBeautificationObjects = 3 * cNumberPlayers * getMapAreaSizeFactor();

   for(int i = 0; i < numBeautificationObjects; i++)
   {
      // Find a suitable location for the beautification object.
      rmAddClosestLocConstraint(rmCreateClassDistanceConstraint(olympusClassID, xsRandFloat(8.0, 15.0)));
      if(xsRandBool(0.5) == true)
      {
         rmAddClosestLocConstraint(rmCreateAreaDistanceConstraint(continentID, xsRandFloat(13.0, 20.0)));
      }
      rmAddClosestLocConstraint(customAvoidEdge8);
      rmAddClosestLocConstraint(forceNearOlympusAreasXL, 5.0);

      // Beautification location.
      vector beautificationLoc = rmGetClosestLoc(cCenterLoc, -1.0);

      // Clear the constraints before proceeding to the next search.
      rmClearClosestLocConstraints();

      // Find a suitable connection point inside the Olympus areas.
      if(xsRandFloat(0.0, 1.0) < 0.6)
      {
         rmAddClosestLocConstraint(avoidContinent);
      }
      rmAddClosestLocConstraint(forceInsideOlympusAreas);
      rmAddClosestLocConstraint(vDefaultAvoidImpassableLand6);
      
      // Prevent beautification objects from connecting to themselves.
      rmAddClosestLocConstraint(rmCreateClassDistanceConstraint(beautificationClassID, xsRandFloat(22.0, 26.0)));
      if(xsRandBool(0.5) == true)
      {  // Not guaranteed to happen every time.
         rmAddClosestLocConstraint(rmCreateMultiLocDistanceConstraint(beautificationConnectionLocs), 30.0);
      }

      // Connection endpoint.
      vector connectionLoc = rmGetClosestLoc(beautificationLoc, xsRandFloat(40.0, 50.0));

      // Prevent future paths from reusing the same endpoint. (not always)
      beautificationConnectionLocs.add(connectionLoc);

      // Clear closest loc constraints.   
      rmClearClosestLocConstraints();

      // Proceed only if both locations are valid. 
      // Note : Invalid locations would cause the connections to collapse toward a map corner.
      if(xsVectorLength(beautificationLoc) > 0.02 && xsVectorLength(connectionLoc) > 0.02)
      {   
         // Randomize the blend type used by the generated terrain.
         int blendRandType = (xsRandBool(0.5) == true) ? cBlendAll : cBlendCliffSide;

         // Generate the connection path.
         int beautificationObjectPathID = rmPathDefCreatePath(olympusBonusPathDefID);
         rmPathAddWaypoint(beautificationObjectPathID, beautificationLoc);
         rmPathAddWaypoint(beautificationObjectPathID, connectionLoc);
         rmPathSetCostNoise(beautificationObjectPathID, 0.0, 2.0);
         rmPathBuild(beautificationObjectPathID);

         // Generate the path area.
         int beautificationObjectPathAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID, "bonus object path area " + i);
         if(xsRandBool(0.5) == true)
         {
            rmAreaSetMix(beautificationObjectPathAreaID, baseMixID);
         }
         rmAreaSetPath(beautificationObjectPathAreaID, beautificationObjectPathID, xsRandFloat(23.0, 25.0));
         rmAreaSetHeight(beautificationObjectPathAreaID, 28.0);
         rmAreaSetCliffSideRadius(beautificationObjectPathAreaID, 1, 2); // Override.
         rmAreaSetHeightNoise(beautificationObjectPathAreaID, cNoiseFractalSum, 7.5, 0.1, 1, 0.5);
         rmAreaAddHeightBlend(beautificationObjectPathAreaID, blendRandType, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(beautificationObjectPathAreaID, 0, vDefaultAvoidImpassableLand2);
         rmAreaAddHeightConstraint(beautificationObjectPathAreaID, avoidInsideOlympusAreaClass);
         rmAreaBuild(beautificationObjectPathAreaID);

         // Generate the elevated area that will contain the beautification object.
         int beautificationObjectAreaID = rmAreaDefCreateArea(olympusBonusAreaDefID);
         if(xsRandBool(0.5) == true)
         {
            rmAreaSetMix(beautificationObjectAreaID, baseMixID);
         }
         rmAreaSetLoc(beautificationObjectAreaID, beautificationLoc);
         rmAreaSetSizeRange(beautificationObjectAreaID, beautificationAreaMinSize, beautificationAreaMaxSize);
         rmAreaSetHeight(beautificationObjectAreaID, xsRandFloat(30.0, 32.0));
         rmAreaSetHeightNoise(beautificationObjectAreaID, cNoiseFractalSum, 7.5, 0.1, 1, 0.5);
         rmAreaAddHeightBlend(beautificationObjectAreaID, blendRandType, cFilter5x5Box, 10);
         rmAreaAddHeightBlendExpansionConstraint(beautificationObjectAreaID, 0, vDefaultAvoidImpassableLand2);
         rmAreaSetCoherence(beautificationObjectAreaID, 0.2);
         rmAreaAddToClass(beautificationObjectAreaID, beautificationClassID);
         rmAreaBuild(beautificationObjectAreaID);

         // Generate beautification path.
         int templeBeautificationPathID = rmPathDefCreatePath(beautificationPathDefID);
         rmPathAddWaypoint(templeBeautificationPathID, beautificationLoc);
         rmPathAddWaypoint(templeBeautificationPathID, connectionLoc);
         rmPathBuild(templeBeautificationPathID);

         // Generate the beautification path area.
         int beautificationPathAreaID = rmAreaDefCreateArea(beautificationPathAreaDefID);
         rmAreaSetPath(beautificationPathAreaID, templeBeautificationPathID, 0.0);
         rmAreaSetTerrainType(beautificationPathAreaID, cTerrainGreekRoadSnow);
         rmAreaBuild(beautificationPathAreaID);
         
         // Using the angle between the two generated locations may lead to inconsistencies, 
         // as the path can deviate from a straight line.

         // Instead, derive the orientation from one of the generated path tiles.
      
         vector[] pathTiles = rmPathGetTiles(beautificationObjectPathID);
         vector referenceAngleLoc = pathTiles[pathTiles.size() - 6];
         referenceAngleLoc = rmTileIndexToFraction(referenceAngleLoc);

         // Determine the object orientation.
         float beautificatinoObjectDirAngle = xsVectorAngleAroundY(beautificationLoc, referenceAngleLoc);

         // Select a random primary beautification object.
         int beautificationUnitTypeID = (xsRandBool(0.5) == true) ? beautificationObjectTypeA.getRandCandidate() : 
                                                         beautificationObjectTypeB.getRandCandidate();

          // Place the primary beautification object.
         int beautificationObjectID = rmObjectDefCreateObject(beautificationTypeABDef);
         rmObjectAddItem(beautificationObjectID, beautificationUnitTypeID, 1);
         rmObjectSetItemRotation(beautificationObjectID, 0, cItemRotateCustom, beautificatinoObjectDirAngle - c3PiOver2);
         rmObjectPlaceAtLoc(beautificationObjectID, 0, beautificationLoc);

         // Generate supporting decorative object locations.
         int numTypeCLocs = 2;
         vector[] typeCLocs = placeLocationsInCircle(numTypeCLocs, 3.0, beautificatinoObjectDirAngle - c3PiOver2, 0.0, 0.0, 
                                                    beautificationLoc);
         
         // Select the decorative object type.
         int typeCID = beautificationObjectTypeC.getRandCandidate();
         for(int j = 0; j < numTypeCLocs; j++)
         {
            vector currentLoc = typeCLocs[j];
            currentLoc = xsVectorTranslateXZ(currentLoc, -rmXMetersToFraction(4.0), beautificatinoObjectDirAngle);

            // Place a supporting decorative object.
            int objectTypeCID = rmObjectDefCreateObject(beautificationTypeCDef);
            rmObjectAddItem(objectTypeCID, typeCID, 1);
            rmObjectSetItemVariation(objectTypeCID, 0, 0);
            rmObjectPlaceAtLoc(objectTypeCID, 0, currentLoc);

         }                                                    
      }
   }

   // Create a fake Olympus area. It will avoid bonus areas, but not bonus paths.
   int fakeOlympusID = rmAreaCreate("fake olympus");
   rmAreaSetParent(fakeOlympusID, continentID);
   rmAreaSetSize(fakeOlympusID, 1.0);
   rmAreaAddConstraint(fakeOlympusID, rmCreateCliffSideDistanceConstraint(continentID, 1.0));
   rmAreaAddConstraint(fakeOlympusID, rmCreateClassDistanceConstraint(olympusOuterBonusAreaClassID, 1.0));
   rmAreaBuild(fakeOlympusID);
   
   // This will act as a boundary. Areas generated inside bonus areas will avoid this fake Olympus.
   int avoidFakeContinent = rmCreateAreaDistanceConstraint(fakeOlympusID, 1.0);

   // Continent edge cliff.
   int numContinentEdgeCliffs = xsRandInt(3, 4) * cNumberPlayers * getMapAreaSizeFactor();
   
   int bonusCliffAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 25.0, true, "cliff vs building");
   int bonusCliffAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.35), "bonus cliff - stay away from the center");

   float bonusCliffMinSize = rmTilesToAreaFraction(70);
   float bonusCliffMaxSize = rmTilesToAreaFraction(150);

   for(int i = 0; i < numContinentEdgeCliffs; i++)
   {
      int continentEdgeCliffID = rmAreaDefCreateArea(bonusCliffDefID);
      rmAreaSetParent(continentEdgeCliffID, continentID);
      rmAreaSetSizeRange(continentEdgeCliffID, bonusCliffMinSize, bonusCliffMaxSize);
      rmAreaSetHeightRelative(continentEdgeCliffID, xsRandFloat(7.0, 12.0));
      rmAreaAddHeightBlend(continentEdgeCliffID, cBlendAll, cFilter3x3Gaussian);
      rmAreaAddCliffOuterLayerConstraint(continentEdgeCliffID, vDefaultAvoidImpassableLand);
      rmAreaAddOriginConstraint(continentEdgeCliffID, forceInsideInnerContinentEdge);
      rmAreaAddOriginConstraint(continentEdgeCliffID, bonusCliffAvoidPlayerLoc, 10.0);
      rmAreaAddConstraint(continentEdgeCliffID, avoidOlympusBonusArea, 4.0, 6.0);
      rmAreaAddConstraint(continentEdgeCliffID, bonusCliffAvoidBuilding);
      // There was a strange case where a cliff stretched almost halfway across the continent; with this, it will be fixed.
      rmAreaAddConstraint(continentEdgeCliffID, bonusCliffAvoidCenter); 
      rmAreaBuild(continentEdgeCliffID);
   }

   // Enable TOB conversion.
   rmSetTOBConversion(true);

   rmSetProgress(0.3);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   
   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(7, 8));
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6));
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forests.
   float avoidForestMeters = 25.0;

   // Starting forests.
   int startingForestDefID = rmAreaDefCreate("starting forest");
   rmAreaDefSetSizeRange(startingForestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(startingForestDefID, forestTypeID);
   rmAreaDefAddToClass(startingForestDefID, forestClassID);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidCollideable8);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidImpassableLand12);
   rmAreaDefAddConstraint(startingForestDefID, forestAvoidForest);
   rmAreaDefAddConstraint(startingForestDefID, rmCreateClassDistanceConstraint(olympusBonusPathClassID, 1.0));
   rmAreaDefAddOriginConstraint(startingForestDefID, vDefaultAvoidImpassableLand16);
   addAreaLocsPerPlayer(startingForestDefID, 3, cDefaultPlayerForestOriginMinDist, cDefaultPlayerForestOriginMaxDist, 
                        avoidForestMeters * 1.35);

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;
   
   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, avoidUpperHill);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, avoidOlympusBonusArea);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward, cInAreaDefault, 
                                          isTournamentSeason ? sharedSide : cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
      if(xsRandBool(0.5) == true)
      {
         addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
      }
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, avoidUpperHill);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidOlympusBonusArea);
   addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters, cBiasNone, 
                                    cInAreaDefault, isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");
   
   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(5, 9));
   rmObjectDefAddConstraint(closeHuntID, avoidHills);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidOlympusBonusArea);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 60.0, 90.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 60.0, 90.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHuntID = rmObjectDefCreate("far hunt");
   if(farHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeElk, xsRandInt(5, 9));
   }
   else if(farHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(5, 9));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(farHuntID, avoidHills);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, avoidOlympusBonusArea);
   addObjectDefPlayerLocConstraint(farHuntID, 75.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 80.0, 110.0, avoidHuntMeters, cBiasNone, cInAreaDefault, 
                                    isTournamentSeason ? sharedSide : cLocSideRandom);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 80.0, 110.0, avoidHuntMeters);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(7, 11));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(4, 8));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(3, 7));
         }

         rmObjectDefAddConstraint(largeMapHuntID, avoidHills);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, avoidOlympusBonusArea);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int bonusBerriesID = rmObjectDefCreate("bonus berries");
   rmObjectDefAddItem(bonusBerriesID, cUnitTypeBerryBush, xsRandInt(7, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(bonusBerriesID, avoidHills);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusBerriesID, avoidOlympusBonusArea);
   addObjectDefPlayerLocConstraint(bonusBerriesID, 65.0);
   addObjectLocsPerPlayer(bonusBerriesID, false, 2 * getMapAreaSizeFactor(), 65.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, avoidUpperHill);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidOlympusBonusArea);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, avoidUpperHill);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   //rmObjectDefAddConstraint(bonusHerdID, avoidOlympusBonusArea);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 2));
   }
   rmObjectDefAddConstraint(predatorID, avoidHills);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");
   
   rmSetProgress(0.7);

   // Global forests.

   // Main forests.
   int mainForestDefID = rmAreaDefCreate("main forest");
   rmAreaDefSetSizeRange(mainForestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(mainForestDefID, forestTypeID);
   rmAreaDefSetBlobs(mainForestDefID, 2, 5);
   rmAreaDefSetBlobDistance(mainForestDefID, 10.0);
   rmAreaDefAddToClass(mainForestDefID, forestClassID);
   rmAreaDefAddConstraint(mainForestDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(mainForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(mainForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(mainForestDefID, avoidHills);
   rmAreaDefAddConstraint(mainForestDefID, forestAvoidForest);
   rmAreaDefAddConstraint(mainForestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(mainForestDefID, avoidOlympusBonusArea);

   buildAreaDefInTeamAreas(mainForestDefID, 6 * getMapAreaSizeFactor());

   // Edge forests.
   int edgeForestDefID = rmAreaDefCreate("edge forest");
   rmAreaDefSetSizeRange(edgeForestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(60));
   rmAreaDefSetForestType(edgeForestDefID, forestTypeID);
   rmAreaDefSetBlobs(edgeForestDefID, 2, 5);
   rmAreaDefSetBlobDistance(edgeForestDefID, 10.0);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidCollideable6);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddConstraint(edgeForestDefID, avoidHills);
   rmAreaDefAddConstraint(edgeForestDefID, forestAvoidForest);
   rmAreaDefAddConstraint(edgeForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeResource, 10.0));
   rmAreaDefAddConstraint(edgeForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0));
   rmAreaDefAddConstraint(edgeForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeRelic, 10.0));
   rmAreaDefAddConstraint(edgeForestDefID, avoidOlympusPath8);
   rmAreaDefAddConstraint(edgeForestDefID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 8.0));
   rmAreaDefAddToClass(edgeForestDefID, forestClassID);

   rmAreaDefCreateAndBuildAreas(edgeForestDefID, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.8);

   // Create some outside embellishment mountains.
   int sideMountainClassID = rmClassCreate("side mountain class");
   int sideMountainAvoidSelf = rmCreateClassDistanceConstraint(sideMountainClassID, 1.0, cClassAreaDistance, "side mountain vs side mountain");
   int sideMountainAvoidContinent = rmCreateClassDistanceConstraint(olympusClassID, 2.0, cClassAreaDistance, "side mountain vs olympus");

   for(int i = 0; i < 2; i++)
   {
      for(int j = 0; j < 2; j++)
      {
         int sideMountainID = rmAreaCreate("side mountain " + i + " " + j);
         rmAreaSetLoc(sideMountainID, vectorXZ(i, j));
         rmAreaSetSize(sideMountainID, 1.0);

         rmAreaSetHeight(sideMountainID, xsRandFloat(15.0, 25.0));
         rmAreaSetHeightNoise(sideMountainID, cNoiseFractalSum, 60.0, 0.05, 5, 0.5);
         rmAreaAddHeightBlend(sideMountainID, cBlendAll, cFilter5x5Box, 2, 2);
         rmAreaAddHeightBlendExpansionConstraint(sideMountainID, 0, avoidOlympusBonusArea);
         rmAreaSetCliffType(sideMountainID, cCliffGreekGrassSnow);
         rmAreaSetCliffPaintInsideAsSide(sideMountainID, true);
         rmAreaSetCliffLayerPaint(sideMountainID, cCliffLayerOuterSideClose, false);
         rmAreaSetCliffLayerPaint(sideMountainID, cCliffLayerOuterSideFar, false);

         rmAreaAddToClass(sideMountainID, sideMountainClassID);
         rmAreaAddConstraint(sideMountainID, sideMountainAvoidSelf);
         rmAreaAddConstraint(sideMountainID, vDefaultAvoidWater);
         rmAreaAddConstraint(sideMountainID, sideMountainAvoidContinent, 0.0, 20.0);
      }
   }

   rmAreaBuildAll();

   // Alright, let's take this a step further and generate wall fragments outside the mount.
   int wallPathClassID = rmClassCreate("wall path class");
   int avoidWallPath = rmCreateClassDistanceConstraint(wallPathClassID, 5.0, cClassAreaDistance, "stay 5 meters away from wall path");

   // Wall path definition.
   int wallPathDefID = rmPathDefCreate("wall path def");
   rmPathDefSetCostNoise(wallPathDefID, -2.0, 2.0);
   rmPathDefAddConstraint(wallPathDefID, avoidOlympusClass5);
   rmPathDefAddToClass(wallPathDefID, wallPathClassID);

   // Wall path area definition.
   int wallPathAreaDefID = rmAreaDefCreate("wall path area def");
   rmAreaDefAddHeightBlend(wallPathAreaDefID, cBlendEdge, cFilter3x3Gaussian, 1);
   rmAreaDefSetHeightNoise(wallPathAreaDefID, cNoiseFractalSum, 7.0, 0.05, 2, 0.5);
   rmAreaDefAddTerrainReplacement(wallPathAreaDefID, cTerrainGreekCliff1, cTerrainGreekRoad1);
   rmAreaDefAddTerrainReplacement(wallPathAreaDefID, cTerrainGreekCliff2, cTerrainGreekRoad2);

   // Wall path area definition.
   int wallPathTerrainRestoreDefID = rmAreaDefCreate("wall path area restore terrain def");
   rmAreaDefSetSize(wallPathTerrainRestoreDefID, 1.0);
   rmAreaDefAddTerrainReplacement(wallPathTerrainRestoreDefID, cTerrainGreekRoad1, cTerrainGreekCliff1);
   rmAreaDefAddTerrainReplacement(wallPathTerrainRestoreDefID, cTerrainGreekRoad2, cTerrainGreekCliff2);

   // Wall path stuff.
   int numWallPaths = xsRandInt(3, 4) * cNumberPlayers * getMapAreaSizeFactor();
   vector[] multiWallWaypoints = new vector(0, cOriginVector);

   // The first task is to generate the paths.
   for(int i = 0; i < numWallPaths; i++)
   {
      // Define the constraints required to find the first waypoint.
      rmAddClosestLocConstraint(rmCreateMultiLocDistanceConstraint(multiWallWaypoints, 35.0));
      rmAddClosestLocConstraint(avoidOlympusClass5, 2.0);
      rmAddClosestLocConstraint(vDefaultAvoidWater);

      // First wall path waypoint.
      vector wallPathStartWaypoint = rmGetClosestLoc(cCenterLoc, -1.0);
      
      // In addition to the previous constraints, enforce a minimum distance from
      // the first waypoint when searching for the second one.
      rmAddClosestLocConstraint(rmCreateLocDistanceConstraint(wallPathStartWaypoint, 12.0));

      // Second wall path waypoint.
      vector wallPathEndWaypoint = rmGetClosestLoc(wallPathStartWaypoint, xsRandFloat(45.0, 70.0));

      // Clear constraints.
      rmClearClosestLocConstraints();

      // Proceed with path generation only when both waypoints have been successfully found.
      if((xsVectorLength(wallPathStartWaypoint) > 0.02) && (xsVectorLength(wallPathEndWaypoint) > 0.02))
      {
         // Add the retrieved locations to an array to prevent future paths from overlapping with previously generated waypoints.
         multiWallWaypoints.add(wallPathStartWaypoint);
         multiWallWaypoints.add(wallPathEndWaypoint);

         // Generate the wall path.
         int wallPathID = rmPathDefCreatePath(wallPathDefID);
         rmPathAddWaypoint(wallPathID, wallPathStartWaypoint);
         rmPathAddWaypoint(wallPathID, wallPathEndWaypoint);
         rmPathBuild(wallPathID);
      }

   }

   // Now that the paths have been created, begin placing the walls.
   int[] wallPathIDs = rmPathDefGetCreatedPaths(wallPathDefID);
   numWallPaths = wallPathIDs.size();

   for(int i = 0; i < numWallPaths; i++)
   {
      // Before placing the walls, we need to create a traversable area. Walls cannot be placed on impassable terrain, 
      // so we must temporarily make the terrain buildable.

      int wallPathAreaID = rmAreaDefCreateArea(wallPathAreaDefID);
      rmAreaSetPath(wallPathAreaID, wallPathIDs[i], 7.0);
      rmAreaSetHeight(wallPathAreaID, xsRandFloat(18.0, 26.0));
      rmAreaBuild(wallPathAreaID);

      // With the terrain fixed, scan the path tiles and use them as placement points for the wall segments.
      vector[] pathTiles = rmPathGetTiles(wallPathIDs[i]);
      int numPathTiles = pathTiles.size();

      // Optimize path processing using intervals.
      vector[] wallWaypoints = modCreateVectorIntervals(pathTiles, 4);
      int numWallWaypoints = wallWaypoints.size();

      // Convert tile indices into fraction coordinates.
      for(int j = 0; j < numWallWaypoints; j++)
      {
         vector currentIDx = wallWaypoints[j];
         wallWaypoints[j] = rmTileIndexToFraction(currentIDx);
      }

      // Place the wall segments.
      rmWallsPlace(0, wallWaypoints);

      // Restore the terrain to its original state.
      int restoreTerrainID = rmAreaDefCreateArea(wallPathTerrainRestoreDefID);
      rmAreaSetParent(restoreTerrainID, wallPathAreaID);
      rmAreaBuild(restoreTerrainID);

   }

   // Apply chaotic noise around all cliffs belonging to the Olympus class.
   int forceInsideOlympusCliffSide = rmCreateClassMaxDistanceConstraint(olympusClassID, 1.0, cClassAreaCliffSideDistance);
   int avoidOlympusCliffInside = rmCreateClassDistanceConstraint(olympusClassID, 2.5, cClassAreaCliffInsideDistance);

   int noiseCliffDefID = rmAreaDefCreate("noise cliff def");
   rmAreaDefSetSizeRange(noiseCliffDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(120));
   rmAreaDefSetCliffType(noiseCliffDefID, cCliffGreekGrassSnow);
   rmAreaDefSetCliffEmbellishmentDensity(noiseCliffDefID, 0.0);
   rmAreaDefSetCliffSideRadius(noiseCliffDefID, 0, 1);
   rmAreaDefSetCliffPaintInsideAsSide(noiseCliffDefID, true);
   rmAreaDefAddCliffOuterLayerConstraint(noiseCliffDefID, vDefaultAvoidImpassableLand);
   rmAreaDefSetCliffLayerPaint(noiseCliffDefID, cCliffLayerOuterSideFar, false);
   rmAreaDefSetAvoidSelfDistance(noiseCliffDefID, 10.0);
   rmAreaDefSetHeightNoise(noiseCliffDefID, cNoiseFractalSum, 8.0, 0.15, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(noiseCliffDefID, 1.0);
   rmAreaDefSetHeightRelative(noiseCliffDefID, 0.5);
   rmAreaDefSetBlobs(noiseCliffDefID, 2, 5);
   rmAreaDefSetBlobDistance(noiseCliffDefID, 10.0, 25.0);
   rmAreaDefAddConstraint(noiseCliffDefID, avoidHills);
   rmAreaDefAddConstraint(noiseCliffDefID, vDefaultAvoidPassableLand2);
   rmAreaDefAddConstraint(noiseCliffDefID, forceInsideOlympusCliffSide);
   rmAreaDefAddConstraint(noiseCliffDefID, avoidOlympusCliffInside);

   rmAreaDefCreateAndBuildAreas(noiseCliffDefID, 100 * cNumberPlayers * getMapAreaSizeFactor());

   // Define the beautification areas.
   int grassClassID = rmClassCreate("grass class");

   int avoidGrassClass15 = rmCreateClassDistanceConstraint(grassClassID, 15.0, cClassAreaDistance, "cliff snow patch vs grass areas");

   // Grass area beautification.
   int terrainBeautificationAreaID = rmAreaDefCreate("terrain beautification area");
   rmAreaDefSetSize(terrainBeautificationAreaID, 1.0);
   rmAreaDefSetEdgeSmoothDistance(terrainBeautificationAreaID, 2);

   // Beautification around the outer gold areas.
   int[] outerGoldAreasIDs = rmClassGetAreas(outerGoldAreaClassID);

   int numGoldOuterAreaIDs = outerGoldAreasIDs.size();

   // Rocky areas.
   float goldRockyAreaSize = rmTilesToAreaFraction(22);

   for(int i = 0; i < numGoldOuterAreaIDs; i++)
   {
      // Outer gold area location.
      vector currentLoc = rmAreaGetLoc(outerGoldAreasIDs[i]);
      
      // Generate a small rocky patch around the gold area.
      int goldRockyAreaID = rmAreaCreate("gold rocky area " + i);
      rmAreaSetLoc(goldRockyAreaID, currentLoc);
      rmAreaSetSize(goldRockyAreaID, goldRockyAreaSize);
      rmAreaSetTerrainType(goldRockyAreaID, cTerrainGreekSnowGrassRocks1);
      rmAreaAddTerrainLayer(goldRockyAreaID, cTerrainGreekSnowGrassRocks2, 0, 1);
      rmAreaAddConstraint(goldRockyAreaID, vDefaultAvoidImpassableLand4);
      rmAreaBuild(goldRockyAreaID);
   }

   for(int i = 0; i < numGoldOuterAreaIDs; i++)
   {
      // Randomly decide whether this area will receive grass beautification.
      bool isGrass = xsRandBool(0.5);

      // Outer gold area location.
      vector currentLoc = rmAreaGetLoc(outerGoldAreasIDs[i]);

      // Generate the beautification area around the gold mine.
      int beautificationGoldAreaID = rmAreaDefCreateArea(terrainBeautificationAreaID);
      rmAreaSetLoc(beautificationGoldAreaID, currentLoc);
      if(isGrass)
      {  // Override the terrain and mark the area as grassland.
         overrideBeautificationTerrain(beautificationGoldAreaID, 0);
         rmAreaAddToClass(beautificationGoldAreaID, grassClassID);
      }
      rmAreaAddConstraint(beautificationGoldAreaID, vDefaultAvoidImpassableLand);
      rmAreaAddConstraint(beautificationGoldAreaID, avoidFakeContinent);
      rmAreaBuild(beautificationGoldAreaID);

      // Generate decorative objects inside the beautification area.
      int[] localConstraints = new int(1, rmCreateAreaConstraint(beautificationGoldAreaID));
      localConstraints.add(rmCreateAreaEdgeDistanceConstraint(beautificationGoldAreaID, 3.0));
      localConstraints.add(avoidBeautificationPath);

      if(isGrass)
      {  // Place vegetation in grassy variants.
         createAndPlaceObjectViaDef(beautificationOakDefID, 0, xsRandInt(5, 6), localConstraints);
         createAndPlaceObjectViaDef(beautificationFlowerID, 0, xsRandInt(5, 7), localConstraints);
      }

      // Place small supporting decorations.
      createAndPlaceObjectViaDef(columnsBrokenDefID, 0, xsRandInt(1, 3), localConstraints);
      createAndPlaceObjectViaDef(columnsDefID, 0, xsRandInt(1, 2), localConstraints);
      createAndPlaceObjectViaDef(torchDefID, 0, xsRandInt(0, 2), localConstraints);

   }

   // Beautification around the relic areas. 
   int[] relicAreasIDs = rmClassGetAreas(relicAreaClassID);
   int numRelicAreas = relicAreasIDs.size();

   for(int i = 0; i < numRelicAreas; i++)
   {
      // Relic area location.
      vector relicLoc = rmAreaGetLoc(relicAreasIDs[i]);

      // Generate the ring used by the main decorative features.
      int numFeatureSegments = 4;
      float featureRingRadius = 8.0;
      float featureRingAngle = degToRad(90);

      vector[] featureSegmentLocs = placeLocationsInCircle(numFeatureSegments, featureRingRadius, featureRingAngle, 0.0, 0.0,
                                                           relicLoc);

      for(int j = 0; j < numFeatureSegments; j++)
      {
         vector currentSegmentLoc = featureSegmentLocs[j];

         // Generate a small formation at each segment location.
         int numObjectsPerSegment = 2;

         vector[] featureObjectLocs = placeLocationsInCircle(numObjectsPerSegment, 1.75, xsVectorAngleAroundY(relicLoc, 
                                                            currentSegmentLoc) - degToRad(90), 0.0, 0.0, currentSegmentLoc);

         for(int k = 0; k < numObjectsPerSegment; k++)
         {
            vector currentObjectLoc = featureObjectLocs[k];

            int mainFeatureID = rmObjectDefCreateObject(beautificationTypeABDef);
            rmObjectAddItem(mainFeatureID, cUnitTypeColumns, 1);

            rmObjectPlaceAtLoc(mainFeatureID, 0, currentObjectLoc);
         }
      }

      // Generate supporting decorative objects between the main feature segments.
      float supportObjectAngleOffset = featureRingAngle + (cPi / numFeatureSegments);

      float supportVariantion = xsRandInt(0, 1);
      int supportID = xsRandBool(0.5) ? cUnitTypeTorch : cUnitTypeFlag;

      for(int j = 0; j < numFeatureSegments; j++)
      {
         vector currentSegmentLoc = featureSegmentLocs[j];
         vector supportObjectLoc = xsVectorRotateXZ(currentSegmentLoc, supportObjectAngleOffset, relicLoc);

         int supportObjectID = rmObjectDefCreateObject(beautificationTypeCDef);
         rmObjectAddItem(supportObjectID, supportID, 1);
         rmObjectSetItemVariation(supportObjectID, 0, supportVariantion);
         rmObjectSetItemRotation(supportObjectID, 0, cItemRotateCustom, xsVectorAngleAroundY(currentSegmentLoc, relicLoc) - degToRad(45));
         rmObjectPlaceAtLoc(supportObjectID, 0, supportObjectLoc);
      }

      // Build the beautification path.
      for(int j = 0; j < numFeatureSegments; j++)
      {
         // Build a separate area for each connection. If multiple connections share
         // the same area, the resulting closed shape will consume the entire enclosed space.
         vector currentLoc = featureSegmentLocs[j];
         vector nextLoc = (j < numFeatureSegments - 1) ? featureSegmentLocs[j + 1] : featureSegmentLocs[0];

         int relicBeautificationPathID = rmPathDefCreatePath(beautificationPathDefID);
         rmPathAddWaypoint(relicBeautificationPathID, currentLoc);
         rmPathAddWaypoint(relicBeautificationPathID, nextLoc);
         rmPathSetCostNoise(relicBeautificationPathID, 0.0, 1.0);
         rmPathBuild(relicBeautificationPathID);

         int relicBeautificationAreaID = rmAreaDefCreateArea(beautificationPathAreaDefID);
         rmAreaSetPath(relicBeautificationAreaID, relicBeautificationPathID, 0.0);
         rmAreaSetTerrainType(relicBeautificationAreaID, cTerrainGreekRoad1);
         rmAreaBuild(relicBeautificationAreaID);

      }
   }

   // Snow cliff patchs.
   int snowCliffPatchDefID = rmAreaDefCreate("snow cliff patch def");
   rmAreaDefSetSizeRange(snowCliffPatchDefID, rmTilesToAreaFraction(150), rmTilesToAreaFraction(200));
   rmAreaDefAddTerrainReplacement(snowCliffPatchDefID, cTerrainGreekCliff1, cTerrainJapaneseCliffSnow1);
   rmAreaDefAddTerrainReplacement(snowCliffPatchDefID, cTerrainGreekCliff2, cTerrainJapaneseCliffSnow2);
   rmAreaDefSetAvoidSelfDistance(snowCliffPatchDefID, 25.0, 10.0);
   rmAreaDefSetBlobs(snowCliffPatchDefID, 2, 3);
   rmAreaDefSetBlobDistance(snowCliffPatchDefID, 15.0, 25.0);
   rmAreaDefAddConstraint(snowCliffPatchDefID, vDefaultAvoidPassableLand2);
   rmAreaDefAddConstraint(snowCliffPatchDefID, rmCreateMinHeightConstraint(15.0), 0.0, 3.0);
   rmAreaDefAddConstraint(snowCliffPatchDefID, avoidGrassClass15);
   rmAreaDefCreateAndBuildAreas(snowCliffPatchDefID, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Outer forests.
   int outerForestDefID = rmAreaDefCreate("outer forest");
   rmAreaDefSetSizeRange(outerForestDefID, rmTilesToAreaFraction(70), rmTilesToAreaFraction(150));
   rmAreaDefSetForestType(outerForestDefID, forestTypeID);
   rmAreaDefSetAvoidSelfDistance(outerForestDefID, avoidForestMeters);
   rmAreaDefSetBlobs(outerForestDefID, 2, 5);
   rmAreaDefSetBlobDistance(outerForestDefID, 10.0);
   rmAreaDefAddToClass(outerForestDefID, forestClassID);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(outerForestDefID, forestAvoidForest);
   rmAreaDefAddConstraint(outerForestDefID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0));
   rmAreaDefAddConstraint(outerForestDefID, vDefaultAvoidWater);
   rmAreaDefAddConstraint(outerForestDefID, avoidWallPath);
   
   rmAreaDefCreateAndBuildAreas(outerForestDefID, 20 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekSnowGrassRocks2, cTerrainGreekSnowGrass2, 8.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekSnowGrassRocks2, cTerrainGreekSnowGrass2, 8.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekSnowGrassRocks2, cTerrainGreekSnowGrass2, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekSnowGrass3, cTerrainGreekSnowGrass3, 10.0);
   buildAreaUnderObjectDef(bonusBerriesID, cTerrainGreekSnowGrass3, cTerrainGreekSnowGrass3, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   // Medium and large rocks.
   int forceNearImpassableLand = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 1.5);

   int rockMediumID = rmObjectDefCreate("rock medium");
   rmObjectDefAddItem(rockMediumID, cUnitTypeRockGreekMedium, 1);
   rmObjectDefAddConstraint(rockMediumID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockMediumID, forceNearImpassableLand);
   rmObjectDefPlaceAnywhere(rockMediumID, 0, 10 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   int rockLargeID = rmObjectDefCreate("rock large");
   rmObjectDefAddItem(rockLargeID, cUnitTypeRockGreekLarge, 1);
   rmObjectDefAddConstraint(rockLargeID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockLargeID, forceNearImpassableLand);
   rmObjectDefPlaceAnywhere(rockLargeID, 0, 10 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Grass Avoidance
   int avoidGreekGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrass1, 1.5);
   int avoidGreekGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrass2, 1.5);
   int avoidGreekGrassDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassDirt1, 1.5);
   int avoidGreekGrassDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassDirt2, 1.5);
   int avoidGreekGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassDirt3, 1.5);
   int avoidGreekGrassRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassRocks1, 1.5);
   int avoidGreekGrassRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassRocks2, 1.5);
   int avoidGreekSnowGrass3 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass3, 1.5);

   // Snow Avoidance
   int avoidGreekSnow1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnow1, 1.5);
   int avoidGreekSnow2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnow2, 1.5);
   int avoidGreekSnow3 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnow3, 1.5);
   int avoidGreekSnowGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass1, 1.5);
   int avoidGreekSnowGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass2, 1.5);
   int avoidGreekSnowGrassRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrassRocks1, 1.5);
   int avoidGreekSnowGrassRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrassRocks2, 1.5);
   int avoidGreekSnowRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowRocks1, 1.5);
   int avoidGreekSnowRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowRocks2, 1.5);

   // Random trees.
   int randomTreePineID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreePineID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreePineID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePineID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePineID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePineID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePineID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePineID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePineID, avoidRoad2);
   rmObjectDefAddConstraint(randomTreePineID, avoidRoad3);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnow1);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnow2);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnow3);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowGrass2);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(randomTreePineID, avoidGreekSnowRocks2);
   rmObjectDefPlaceAnywhere(randomTreePineID, 0, 7 * cNumberPlayers * getMapAreaSizeFactor());

   int randomTreePineSnowID = rmObjectDefCreate("random tree snow");
   rmObjectDefAddItem(randomTreePineSnowID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad3);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrass1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrass2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrassDirt1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrassDirt2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrassDirt3);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrassRocks1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekGrassRocks2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidGreekSnowGrass3);
   rmObjectDefPlaceAnywhere(randomTreePineSnowID, 0, 7 * cNumberPlayers * getMapAreaSizeFactor());

   // Snow Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 35;
      int plantsGroupDensity = 12;

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
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrass1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrass2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrassDirt1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrassDirt2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrassDirt3);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrassRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekGrassRocks2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowGrass3);
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
      int plantsDensity= 30;
      int plantsGroupDensity = xsRandInt(8, 10);

      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantGreekBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantGreekShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantGreekFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantGreekWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantGreekGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantGreekFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantGreekWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnow1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnow2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnow3);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowGrass1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowGrass2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowGrassRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowGrassRocks2);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidGreekSnowRocks2);
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
   rmObjectDefAddConstraint(flowersID, avoidGreekSnow1);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnow2);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnow3);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowGrass2);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(flowersID, avoidGreekSnowRocks2);
   rmObjectDefPlaceAnywhere(flowersID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnow1);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnow2);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnow3);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowGrass2);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(flowersGroupID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 12 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Gaia stuff.
   gaiaStoneWalls();

   gaiaAge4();

   // Lighting override.
   lightingOverride();

   rmSetProgress(1.0);
}
