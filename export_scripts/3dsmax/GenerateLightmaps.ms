/*
TO DO:
-fixing default values menu
-fixing calculate good proportion
-fixing slow down in calculate good proportion
*/

lightmapPath = undefined


--This function checks whether a new unwrap should be created for channel 2 and does so if necessary.
--	Param obj: the object to work on.
--	Param createUnwrap: whether to add a new unwrap modifier if an unwrap existed already.
--	Param collapseAfterUnwrap: whether to collapse the modifier-stack after adding the unwrap modifier.
function handleUnwrapping obj createUnwrap collapseAfterUnwrap =
(
	--Check whether an unwrap in channel 2 already exists.
	addModifier obj (edit_mesh())
	local channel2UnwrapExists = meshop.getMapSupport obj 2
	deleteModifier obj 1
	
	print "creating unwrap1"

	--Create a new unwrap in channel 2 if requested or if it does not exist yet.
	if createUnwrap OR NOT channel2UnwrapExists then
	(
		print "creating unwrap2"
		--Add the unwrap-modifier.
		addModifier obj (unwrap_UVW())

		--The unwrap is put in channel 2, so as not to disturb the unwrap for the diffuse texture.
		obj.modifiers[1].setMapChannel 2

		--This is a bit of a hack, used to force 3dsmax to update the modifier dialogue. This is
		--necessary for flattenMap to work.
		classOf obj
		
		--Select all textureTriangles, to apply the flattenMap on.
		selectionBitArray = #{}
		for i = 1 to obj.modifiers[1].numberPolygons() do
		(
			append selectionBitArray i
		)
		obj.modifiers[1].selectPolygons selectionBitArray

		--Generate an automatic unwrap.
		obj.modifiers[1].flattenMap 50 #([1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1]) 0.01 true 0 true true

		--Collapse the modifier stack (including the unwrap modifier) if requested.
		if collapseAfterUnwrap then
		(
			print "creating unwrap3"
			collapseStack obj
		)
	)
)




function calculateProportion obj =
(
	--Getting vertex data requires an edit mesh modifier.
	addModifier obj (edit_mesh())

	--Calculate the length of an edge in UV-space.
	local textureVertexIndex1 = (meshop.getMapFace obj 2 1)[1]
	local textureVertexIndex2 = (meshop.getMapFace obj 2 1)[2]
	local edgeUVSpaceLength = length ((meshop.getMapVert obj 2 textureVertexIndex1) - (meshop.getMapVert obj 2 textureVertexIndex2))
	print ("edgeUVSpaceLength: " + edgeUVSpaceLength as string)

	--Calculate the length of the same edge in world space.
	local meshVertexIndex1 = (getFace obj 1)[1]
	local meshVertexIndex2 = (getFace obj 1)[2]
	local edgeWorldSpaceLength = length((getVert obj meshVertexIndex1) - (getVert obj meshVertexIndex2))
	print ("edgeWorldSpaceLength: " + edgeWorldSpaceLength as string)

	--The edit mesh modifier is now not needed anymore, so delete it.
	deleteModifier obj 1

	--Calculate the proportion for the resolution.
	local proportion = edgeWorldSpaceLength / edgeUVSpaceLength
	print ("proportion: " + proportion as string)
	proportion
)




--Calculates the texture resolution for this object. This will be larger for large objects.
--	Param obj: the object to calculate the texture resolution for.
--	Param proportionMultiplier: a multiplier that can be used to alter the proportion between resolution and scale of the scene.
--	Param highestResolutionPower: the power of the maximum resolution to be used for a texture.
function calculateResolution obj proportionMultiplier highestResolutionPower =
(
	local proportion = calculateProportion obj
	local actualPower = log (proportion * proportionMultiplier)
	print ("actualPower: " + actualPower as string)
	actualPower = floor (actualPower + 0.5f)

	--Make sure the calculated value is not out of range.
	if actualPower > highestResolutionPower then
	(
		--This is to prevent very high resolutions.
		actualPower = highestResolutionPower
	)
	if actualPower < 4 then
	(
		--This is to prevent very low resolutions.
		actualPower = 4
	)

	--Return the resulting value in pixels.
	actualResolution = pow 2 actualPower
	print ("actualResolution: " + actualResolution as string)
	actualResolution
)




function calculateOptimalProportionMultiplier createUnwrap collapseAfterUnwrap highestResolutionPower =
(
	max modify mode

	wantedMaximumProportion = pow 2 highestResolutionPower
	maximumProportion = 0.0001

	--These are the objects to be processed.
	local selectedObjects = copy ($selection as array) #noMap
	
	--Process every object.
	for obj in selectedObjects do
	(
		--Only generate a lightmap if the object is geometry.
		if isKindOf obj GeometryClass AND NOT isKindOf obj TargetObject then
		(
			--Select the object.
			select obj

			--Create an unwrap in channel 2 if requested or necessary.
			handleUnwrapping obj createUnwrap collapseAfterUnwrap
			
			--Calculate the resolution in pixels to be used for this object.
			local currentProportion = calculateProportion obj
			if maximumProportion < currentProportion then
			(
				maximumProportion = currentProportion
			)
		)
	)

	--Recover the selection the user made before calling this script.
	select selectedObjects
	
	print ("wantedMaximumProportion " + wantedMaximumProportion as string)
	print ("maximumProportion " + maximumProportion as string)
	
	wantedMaximumProportion / maximumProportion
)




--The function that actually performs the generation of the lightmaps.
--	Param proportionMultiplier: a multiplier that can be used to alter the proportion between resolution and scale of the scene.
--	Param forceAllToMaximumResolution: used to turn of adaptive resolution calculation for the texture.
--	Param createUnwrap: whether to add a new unwrap modifier.
--	Param collapseAfterUnwrap: whether to collapse the modifier-stack after adding the unwrap modifier.
--	Param highestResolutionPower: the highest resolution lightmap a large object can get.
function generateLightMaps proportionMultiplier forceAllToMaximumResolution createUnwrap collapseAfterUnwrap highestResolutionPower appendix_id =
(
	max modify mode
	
	lightmapPath = getSavePath caption:"Select the folder to save to"
	if (lightmapPath == undefined) then exit

	--This will be reused for all lightmaps to be generated.
	local map = VRayLightingMap()

	--While having its lightmap generated, each object temporarily gets this white material.
	--This is necessary, because VRay does not fully support texture baking and cannot ignore
	--the standard material.
	local whiteMaterial = standardMaterial()
	whiteMaterial.diffuse = color 255 255 255

	--These are the objects to be processed.
	local selectedObjects = copy ($selection as array) #noMap
	
	--Process every object.
	for obj in selectedObjects do
	(
		--abort operation if escape is pressed
		if keyboard.escPressed then
		(
			exit
		)

		--Only generate a lightmap if the object is geometry.
		if isKindOf obj GeometryClass AND NOT isKindOf obj TargetObject then
		(
			--Select the object.
			select obj

			--Create an unwrap in channel 2 if requested or necessary.
			handleUnwrapping obj createUnwrap collapseAfterUnwrap
			
			--Calculate the resolution in pixels to be used for this object.
			local resolutionInPixels = 64
			if forceAllToMaximumResolution then
			(
				resolutionInPixels = pow 2 highestResolutionPower
			)
			else
			(
				resolutionInPixels = calculateResolution obj proportionMultiplier highestResolutionPower
			)

			--Change the material to the white material and store the original material.
			local originalMaterial = obj.material
			obj.material = whiteMaterial

			--Settings for the baking of this object.
			map.autoSzOn = false
			--map.directOn = true
			map.elementName = "baked"
			map.enabled = true
			
			if (appendix_id == 1) then appendix = "_lightmap"
			if (appendix_id == 2) then appendix = "_shadowmap"
			
			map.filename = (lightmapPath + "\\" + obj.name + appendix + ".png")
			map.filenameUnique = false
			map.filetype = "PNG"
			map.filterOn = true
			--map.inDirectOn = true
			map.outputSzX = resolutionInPixels
			map.outputSzY = resolutionInPixels
			--map.shadowsOn = true
			map.targetMapSlotName = ""

			--Attach the baking to this object.
			local bakeobject = obj.INodeBakeProperties
			bakeobject.removeAllBakeElements()
			bakeobject.addBakeElement map
			bakeobject.nDilations = 64
			bakeObject.bakeEnabled = true
			bakeObject.bakeChannel = 2

			--let the currently selected object be baked.
			render rendertype:#BakeSelected outputwidth:map.outputSzX outputheight:map.outputSzY vfb:true outputfile:map.filename
			
			--Baking is finished for this object, so reset the baking settings for this object.
			bakeobject.removeAllBakeElements()

			--Restore the original material of this object.
			obj.material = originalMaterial
		)
	)
	
	--Recover the selection the user made before calling this script.
	select selectedObjects
)





--The user interface for the lightmap generator.
rollout lightmapGenerator "Lightmap Generator"
(
	Group "Resolution:"
	(
		RadioButtons resolutionRadioButtons "Highest resolution:" labels:#("32", "64", "128", "256", "512", "1024", "2048", "4096") default:8
		RadioButtons texnameRadioButtons "Texture Appendix:" labels:#("_lightmap", "_shadowmap") default:1
		Spinner proportionMultiplier "Multiplier:" range:[0.001, 10000000, 600] type:#float
		Button calculateGoodMultiplier "Calculate good multiplier"
		CheckBox forceAllToMaximumResolution "Force all to maximum" checked:false
	)
	Group "Channel 2 unwrap"
	(
		CheckBox unwrapCheckBox "Create new unwrap" checked:true
		CheckBox collapseCheckBox "Collapse modifiers" checked:true enabled:true
	)
	Button executeButton "Start lightmap generation"
	
	on calculateGoodMultiplier pressed do
	(
		proportionMultiplier.value = calculateOptimalProportionMultiplier unwrapCheckBox.checked \
						 							 					  collapseCheckBox.checked \
						  												  (resolutionRadioButtons.state + 4)
	)
	on unwrapCheckBox changed newState do
	(
		collapseCheckBox.enabled = newState
	)
	on executeButton pressed do
	(
		generateLightMaps proportionMultiplier.value \
						  forceAllToMaximumResolution.checked \
						  unwrapCheckBox.checked \
						  collapseCheckBox.checked \
						  (resolutionRadioButtons.state + 4) \
						  texnameRadioButtons.state
	)
)

--Put the user interface on the screen.
createDialog lightmapGenerator