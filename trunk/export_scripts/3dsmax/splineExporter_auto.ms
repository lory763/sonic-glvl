utility GenerationsSplineExporter "Generations Spline Exporter 1.0" width:162 height:175
(
	--label lbl1 "Export Options:" pos:[16,44] width:108 height:15
	--editText pathText "" pos:[10,67] width:140 height:20
	checkBox enableFlip "Enable Y-Z flip" pos:[18,12] checked:true
	button warningButton "INSTRUCTIONS" pos:[20,100] width:116 height:23 enabled:true
	button exportButton "Export" pos:[20,131] width:116 height:23 enabled:true
	--button browseButton "Browse" pos:[20,99] width:116 height:23 enabled:true
	
	global filePath = ""
	global pathValid = false
	global splineCount = 0
	global splineLocation = #()
	
	global nodeCount = 0
	global nodeLocation = #()
	
	global currentName = ""
	
	global geometryCount = 0
	
	global smoothName = "#smooth" as string
	global cornerName = "#corner" as string
	global bezierName = "#bezier" as string
	global bezierCornerName = "#bezierCorner" as string
	
	on warningButton pressed do
	(
		messageBox "This exporter exports the CURRENT SELECTION. Non-spline objects will cause it to malfunction and you won't get your file."
		messageBox "Make sure to check Stage.stg.xml for necessary scene splines if your exports aren't working. Missing splines cause problems."
		messageBox "Name your splines in this format: 'name@type' \nTypes:\n GR - Grind Rail\n SV - Side View\n QS - QuickStep\n DP - Dash Path\n\nThe exporter automatically appends the -geometry tag where necessary. Do not put it in your spline names"
		messageBox "The exporter does not support rotation or instances (yet). If rotations exist, they will be reset. Consider yourself warned. \nThat's all - signed, Dude"
	)
	
	on exportButton pressed do
	(
		filePath = getSaveFileName caption:"Save a path file" types:"Path File|*.xml"
		if(filePath == undefined) then 
		(
			--messageBox "Operation Canceled"
		) else
		(
			outputStream = createFile filePath
			geometryStream = " " as stringStream -- this will hold all of the spline data
			nodeStream = " " as stringStream -- this will hold all of the node tags for the splines
			
			format "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>\n<SonicPath>\n\n" to:outputStream
			
			format "\t<library type=\"GEOMETRY\">\n" to:geometryStream
			format "\t<scene id=\"DefaultScene\">\n" to: nodeStream
			-- both of these streams will be merged into the outputStream at the end
			
			if(outputStream != undefined) then
			(
				-- recursive loop will go here
				nodeCount = selection.Count
				for currentNode = 1 to nodeCount do
				(
					splineCount = numSplines(selection[currentNode])
					format "\t\t<geometry id=\"" to: geometryStream
					format selection[currentNode].name to: geometryStream
					format "-geometry\" name=\"" to: geometryStream
					format selection[currentNode].name to: geometryStream
					format "-geometry\">\n" to: geometryStream
					
					format "\t\t\t<spline count=\"" to:geometryStream
					format "%" splineCount to: geometryStream
					format "\" width=\"0\">\n" to: geometryStream
					
					ResetXform selection[currentNode]
					maxops.CollapseNode selection[currentNode] true
					
					for s = 1 to splineCount do
					(
						knotsCount = numknots selection[currentNode] s
						format "\t\t\t\t<spline3d count=\"" to:geometryStream
						format "%" knotsCount to:geometryStream
						format "\">\n" to:geometryStream
						
						oldPos = selection[currentNode].pos
						old_x = selection[currentNode].pos.x
						old_y = selection[currentNode].pos.y
						old_z = selection[currentNode].pos.z
						
						selection[currentNode].pos.x = 0
						selection[currentNode].pos.y = 0
						selection[currentNode].pos.z = 0
						
						for n = 1 to knotsCount do
						(
							-- remember to swap invec/outvec for generations support
							type = getKnotType selection[currentNode] s n as String
							invec = getInVec selection[currentNode] s n
							outvec = getOutVec selection[currentNode] s n
							
							position = getKnotPoint selection[currentNode] s n
							
							type = toLower(type)
							
							/*---------EXPORT KNOT TYPE-----------*/
							if(type == "smooth") then
							(
								format "\t\t\t\t\t<knot type=\"auto\">\n" to:geometryStream
							)
							if(type == "corner") then
							(
								format "\t\t\t\t\t<knot type=\"corner\">\n" to:geometryStream
							) 
							if(type == "bezier") then
							(
								format "\t\t\t\t\t<knot type=\"bezier\">\n" to:geometryStream
							)
							if(type == "beziercorner") then
							(
								format "\t\t\t\t\t<knot type=\"bezier_corner\">\n" to:geometryStream
							)
							
							print type
							
							/*---------EXPORT INVEC-----------*/
							if(enableFlip.checked == true) then
							(
								transformZ = invec.y *-1
								format "\t\t\t\t\t\t<invec>" to:geometryStream
								format (invec.x as String) to:geometryStream
								format " " to:geometryStream
								format (invec.z as String) to:geometryStream
								format " " to:geometryStream
								format (transformZ as String) to:geometryStream
								format "</invec>\n" to:geometryStream
							) else
							(
								format "\t\t\t\t\t\t<invec>" to:geometryStream
								format (invec.x as String) to:geometryStream
								format " " to:geometryStream
								format (invec.y as String) to:geometryStream
								format " " to:geometryStream
								format (invec.z as String) to:geometryStream
								format "</invec>\n" to:geometryStream
							)
							
							/*---------EXPORT OUTVEC-----------*/
							if(enableFlip.checked == true) then
							(
								transformZ = outvec.y *-1
								format "\t\t\t\t\t\t<outvec>" to:geometryStream
								format (outvec.x as String) to:geometryStream
								format " " to:geometryStream
								format (outvec.z as String) to:geometryStream
								format " " to:geometryStream
								format (transformZ as String) to:geometryStream
								format "</outvec>\n" to:geometryStream
							) else
							(
								format "\t\t\t\t\t\t<outvec>" to:geometryStream
								format (outvec.x as String) to:geometryStream
								format " " to:geometryStream
								format (outvec.y as String) to:geometryStream
								format " " to:geometryStream
								format (outvec.z as String) to:geometryStream
								format "</outvec>\n" to:geometryStream
							)
							
							/*---------EXPORT POSITION-----------*/
							if(enableFlip.checked == true) then
							(
								transformZ = position.y *-1
								format "\t\t\t\t\t\t<point>" to:geometryStream
								format (position.x as String) to:geometryStream
								format " " to:geometryStream
								format (position.z as String) to:geometryStream
								format " " to:geometryStream
								format (transformZ as String) to:geometryStream
								format "</point>\n" to:geometryStream
							) else
							(
								format "\t\t\t\t\t\t<point>" to:geometryStream
								format (position.x as String) to:geometryStream
								format " " to:geometryStream
								format (position.y as String) to:geometryStream
								format " " to:geometryStream
								format (position.z as String) to:geometryStream
								format "</point>\n" to:geometryStream
							)						
							format "\t\t\t\t\t</knot>\n" to:geometryStream -- close the knot tag
						)
						
						selection[currentNode].pos.x = old_x -- re-instate old values
						selection[currentNode].pos.x = old_y
						selection[currentNode].pos.x = old_z
						selection[currentNode].pos = oldPos
						
						format "\t\t\t\t</spline3d>\n" to:geometryStream
					)
					format "\t\t\t</spline>\n" to:geometryStream
					
					
					format "\t\t</geometry>\n" to:geometryStream
					
					-- time to add node tag
					format "\t\t<node id=\"" to:nodeStream
					format selection[currentNode].name to: nodeStream
					format "\" name=\"" to: nodeStream
					format selection[currentNode].name to: nodeStream
					format "\">\n" to: nodeStream
					
					-- translate
					format "\t\t\t<translate>" to:nodeStream
					format (selection[currentNode].pos.x as string) to:nodeStream
					format " " to:nodeStream
					format (selection[currentNode].pos.z as string) to:nodeStream
					trans_y = selection[currentNode].pos.y * -1
					format " " to:nodeStream
					format (trans_y as string) to:nodeStream
					format "</translate>\n" to:nodeStream
					-- scale
					format "\t\t\t<scale>1 1 1</scale>\n" to:nodeStream
					-- rotation
					format "\t\t\t<rotate>0 0 0 1</rotate>\n"to:nodeStream
					-- instance
					format "\t\t\t<instance url=\"#" to:nodeStream
					format selection[currentNode].name to: nodeStream
					format "-geometry\"/>\n" to: nodeStream
					-- closing
					format "\t\t</node>\n" to:nodeStream
				) -- recursive loop ends here
				format "\t</library>\n" to:geometryStream
				format "\t</scene>\n" to:nodeStream
				
				format (geometryStream as string) to:outputStream
				format (nodeStream as string) to:outputStream
				
				format"\n</SonicPath>" to:outputStream
				
				flush outputStream
				close outputStream
				print "done exporting"
			) else messageBox ("Error Opening File") -- end file validity check
		) -- end file save prompt
	) -- end importButton press
)