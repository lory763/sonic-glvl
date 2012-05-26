clearlistener()
	-- Script originally written by chroxx, Link, and Kentalin. Modified by Brooks (ItsEasyActually) for Generations :D

struct weight_data
(
	boneids,weights
)

struct BoneOffset (
BoneTOffset
)

struct BoneDataStruc (
BoneID, BoneNameOffset, BoneName, BoneParentID
)

fn PrintOffset Var =
(
	local Var = Var
print ("This is the offset 0x" + (bit.intAsHex Var) as string)
	Var
)
y = 180
PrintOffset y
x = 200
print ("This is the number 0x" + (bit.intAsHex x) as string)

fn floatSwap2 f = 
(
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)	

fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

 fn ReadBEHalfFloat Fstream = (
  local BH  = readByte Fstream #unsigned
  local BL  = readByte Fstream #unsigned
  local N = BH*256 + BL
  local S = floor((mod N 65536) / 32768)
  local Ef = floor((mod N 32768) / 1024)
  local M = mod N 1024
  if (Ef==0)AND(M==0) then return ( (-1.0)^S * 0.0 )
  if (Ef==0)AND(M!=0) then return ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
  if (Ef>0)AND(Ef<31) then return ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
  if (Ef==31)AND(M==0) then return ( (-1.0)^S * 1/0.0 )
  if (Ef==31)AND(M!=0) then return 0	--hack-- should be #inf   
 )--end fn ReadBEHalfFloat

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

if (heapSize < 20000000) then
	heapSize = 200000000 -- allow ~ 40 MB instead of just 7.5 MB. Prevents "Runtime Error: Out of scripter memory"

-- TexDir = getSavePath caption:"Select texture path" initialDir:"C:\Users\Experience\Desktop\Emulators\Games\360\Sonic Generations Demo\disk\bb\Packed\ghz100\TexPack"
-- Textures = getFiles (TexDir+"/*.dds")
-- Materials = getFiles (TexDir+"/*.material")

fname = GetOpenFileName caption:"Open Sonic Model File" types:"Sonic Model File(*.model)|*.model"
f = fopen fname "rb"   --open file in read only format

filepath = GetFilenamePath fname

fseek f 0x18#seek_set
MeshHeaderTotal = ReadBELong f
OffsetMHLoc = ReadBELong f + 0x18
CinematicMesh = ReadBElong f
MorphTargetTable = ReadBElong f + 0x18
BoneCount = ReadBElong f
BoneTableOffset = ReadBElong f + 0x18
BoneTableOffset2 = ReadBElong f + 0x18
BoneTableOffset3 = ReadBElong f + 0x18


fseek f BoneTableOffset#seek_set
Bone_Offset_array = #()
for i = 1 to BoneCount Do (
BoneTOffset = ReadBElong f + 0x18
append Bone_Offset_array (BoneOffset BoneTOffset:BoneTOffset)
)
print Bone_Offset_array
Bone_Data_array = #()
BoneID = -1
for k in Bone_Offset_array Do (
fseek f k.BoneTOffset#seek_set
BoneID += 1
BoneParentID = ReadBElong f
BoneNameOffset = ReadBElong f
BoneName = readstring f
append Bone_Data_array ( BoneDataStruc BoneID:BoneID BoneNameOffset:BoneNameOffset BoneName:BoneName BoneParentID:BoneParentID )
)
print Bone_Data_array
fseek f BoneTableOffset2 #seek_set
--if CinematicMesh == 1 Do (
--fseek f 0x1#seek_cur
--)
BNArr = #()
disableSceneRedraw()
Bone_root_array = #()
for i = 1 to BoneCount Do (
m11 = ReadBEfloat f; m12 = ReadBEfloat f; m13 = ReadBEfloat f; m14 = ReadBEfloat f
m21 = ReadBEfloat f; m22 = ReadBEfloat f; m23 = ReadBEfloat f; m24 = ReadBEfloat f
m31 = ReadBEfloat f; m32 = ReadBEfloat f; m33 = ReadBEfloat f; m34 = ReadBEfloat f
m41 = ReadBEfloat f; m42 = ReadBEfloat f; m43 = ReadBEfloat f; m44 = ReadBEfloat f
tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	
newBone = bonesys.createbone	\
				  tfm.row4	\
				  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
				  (normalize tfm.row3)
			newBone.name   = Bone_Data_array[i].BoneName

    	    newBone.width  = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.wirecolor = yellow
			newbone.showlinks = true
					  
			pos = [m14,m24,m34]
			pos = pos * tfm
 
			newBone.pos.x = (-1)*pos.x
			newBone.pos.y = (1)*pos.z
			newBone.pos.z = (-1)*pos.y

			newBone.setBoneEnable false 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()

			
			if (Bone_Data_array[i].BoneParentID != -1) then
					  newBone.parent = BNArr[Bone_Data_array[i].BoneParentID+1]

			BNArr[i] = newBone
			if i == 1 do (
				append Bone_root_array newBone
			)
			
				  )
MorphArr = #()
MorphArr2 = #()
Morph_Face_array = #()
Morph_Name_array = #()

print "Bones done"

if CinematicMesh == 1 Then (
fseek f MorphTargetTable #seek_set
MorphVertCountOffset = ReadBElong f	+ 0x18
MorphVertCount = ReadBElong f	
MorphTableEnd = ReadBElong f + 0x18
MorphUnkCount1 = ReadBElong f
MorphCount = ReadBElong f
MorphTableStart = ReadBElong f + 0x18
MorphTableNameStart = ReadBElong f + 0x18
MorphFaceSetsCount = ReadBElong f
MorphFaceTableStart = ReadBElong f + 0x18
Null = readlong f
MorphFaceTableEnd = ReadBElong f + 0x18

Bone_ids1 = #()

fseek f MorphFaceTableStart#seek_set
PrintOffset (ftell f)
MorphFaceSets = #()
for i = 1 to MorphFaceSetsCount Do
(
	FaceSetStart = ReadBElong f	+ 0x18
	append MorphFaceSets FaceSetStart
)
for i = 1 to MorphFaceSetsCount Do
(
fseek f MorphFaceSets[i] #seek_set
Offset1 = ReadBElong f	+ 0x18
MorphFaceCount = ReadBElong f
MorphFaceOffset = ReadBElong f + 0x18
if ( i == 1) then
(
	fseek f 0x10 #seek_cur
	boneidcount = ReadBElong f
	boneidstart = (ReadBElong f) + 0x18
			
	fseek f boneidstart #seek_set
	for j=1 to boneidcount do
	(
		addboneid = (ReadByte f #unsigned)
		append Bone_ids1 (addboneid + 1)
	)
)	
fseek f MorphFaceOffset#seek_set
StartDirection = 1
f1 = (ReadBEword f) + 1
f2 = (ReadBEword f) + 1  
FaceDirection = StartDirection
Do (
f3 = (ReadBEword f)
if (f3==0xFFFF) then (
f1 = (ReadBEword f) + 1
f2 = (ReadBEword f) + 1
FaceDirection = StartDirection 
) else (
f3 += 1
FaceDirection *= -1
if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
if FaceDirection > 0 then append Morph_Face_array [f1,f2,f3]
else append Morph_Face_array [f1,f3,f2]
)
f1 = f2
f2 = f3
) 
) while ((ftell f) != (MorphFaceOffset + (MorphFaceCount * 2)))
)

fseek f MorphTableEnd #seek_set

Vert_array1 = #() --define arrays for verts, normals, UV and Faces
Normal_array1 = #()
UV_array1 = #()
Weight_array1 = #()



for k = 1 to MorphVertCount Do (
vx = ReadBEfloat f  --read xyz coordinates
vy = ReadBEfloat f
vz = ReadBEfloat f
fseek f 0x24#seek_cur
tu = ReadBEFloat f   --read UV float value
tv = ReadBEFloat f * -1
fseek f 0x28#seek_cur

bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned

w = (weight_data boneids:#() weights:#())

maxweight = 0
	
if(bone1 != 0xFF) then
	maxweight = maxweight + weight1
if(bone2 != 0xFF) then
	maxweight = maxweight + weight2
if(bone3 != 0xFF) then
	maxweight = maxweight + weight3
if(bone4 != 0xFF) then
	maxweight = maxweight + weight4

if(maxweight != 0) then
	(
		mxw = maxweight as float
		if(bone1 != 0xFF) then
		(
			w1 = weight1 as float
			append w.boneids (Bone_ids1[bone1+1])
			append w.weights (w1 / mxw)
		)
		if(bone2 != 0xFF) then
		(
			w2 = weight2 as float
			append w.boneids (Bone_ids1[bone2+1])
			append w.weights (w2 / mxw)
		)
		if(bone3 != 0xFF) then
		(
			w3 = weight3 as float
			append w.boneids (Bone_ids1[bone3+1])
			append w.weights (w3 / mxw)
		)
		if(bone4 != 0xFF) then
		(
			w4 = weight4 as float
			append w.boneids (Bone_ids1[bone4+1])
			append w.weights (w4 / mxw)
		)		
	)

append Vert_array1 [vx,vy,vz]
append UV_array1 [tu,tv,0]  --save UVs to UV_array
append Weight_array1 w
)
msh = mesh vertices:Vert_array1 faces:Morph_Face_array --build mesh
msh.numTVerts = UV_array1.count
buildTVFaces msh
msh.name =  "Mouth"
for j = 1 to UV_array1.count do setTVert msh j UV_array1[j]
for j = 1 to Morph_Face_array.count do setTVFace msh j Morph_Face_array[j]
for j = 1 to Normal_array1.count do setNormal msh j Normal_array1[j]
select $Mouth
MorphMod = morpher ()
addModifier $Mouth MorphMod
$Mouth.morpher.Autoload_of_targets = 1
--$Mouth.parent = $Neck

fseek f MorphTableStart#seek_set
for i = 1 to MorphCount Do (
append MorphArr (ReadBElong f + 0x18)
)
for i = 1 to MorphCount Do (
append MorphArr2 (ReadBElong f + 0x18)
)	
for i = 1 to MorphCount Do (
fseek f MorphArr[i]#seek_set
MorphName = readstring f
fseek f MorphArr2[i]#seek_set
Morph_Vert_array = #()
Morph_UV_array = #()
Morph_Normal_array = #()
for k = 1 to MorphVertCount Do (
vx = ((ReadBEfloat f) ) + Vert_array1[k].x
vy = ((ReadBEfloat f) ) + Vert_array1[k].y
vz = ((ReadBEfloat f) ) + Vert_array1[k].z
append Morph_Vert_array [vx,-vz,vy]
)

msh = mesh vertices:Morph_Vert_array faces:Morph_Face_array   --build mesh
msh.numTVerts = UV_array1.count
buildTVFaces msh
msh.name =  MorphName
for j = 1 to UV_array1.count  do setTVert msh j UV_array1[j]
for j = 1 to Morph_Face_array.count  do setTVFace msh j Morph_Face_array[j]
for j = 1 to Morph_Normal_array.count do setNormal msh j Morph_Normal_array[j]
append Morph_Name_array msh
)

max modify mode
select $mouth
skinMod = skin ()
addModifier $mouth skinMod
for i = 1 to BNArr.count do
(
	maxbone = getnodebyname BNArr[i].name
	if i != BNArr.count then
		skinOps.addBone skinMod maxbone 0
	else
		skinOps.addBone skinMod maxbone 1
	
)

modPanel.setCurrentObject skinMod

for i = 1 to Weight_array1.count do
(
	w = Weight_array1[i]
	bi = #() --bone index array
	wv = #() --weight value array
	
	for j = 1 to w.boneids.count do
	(
		boneid = w.boneids[j]
		weight = w.weights[j]
		append bi boneid
		append wv weight
	)	
	
	skinOps.ReplaceVertexWeights skinMod i bi wv
)

max create mode

)
for b = 1 to Morph_Name_array.count Do (
	WM3_MC_BuildFromNode $Mouth.morpher b Morph_Name_array[b]
	hide Morph_Name_array[b]
)

fseek f OffsetMHLoc#seek_set

for m = 1 to MeshHeaderTotal Do (
MeshHeader = ReadBELong f + 0x18
	NextHeader = ftell f
	

fseek f MeshHeader#seek_set
MeshCount = ReadBElong f
MshLoc = ReadBElong f + 0x18
AddMeshCount = ReadBElong f
AddMeshBegin = ReadBElong f + 0x18
AlphaMeshCount = ReadBELong f
AlphaMeshBegin = ReadBELong f + 0x18

fseek f 0x4#seek_cur
TestByte = ReadByte f#unsigned
if TestByte != 0xFF Do (
	fseek f -0x5#seek_cur
	OpaqueCount = ReadBELong f
	OpaqueOffset = ReadBELong f + 0x1C
	fseek f OpaqueOffset#seek_set
	OpOff = ReadBELong f + 0x18
	OpaqueMeshBegin = ReadBELong f + 0x18	
	fseek f OpOff#seek_set
	OpaqueMeshCount = ReadBELong f
)

if TestByte == 0xFF Do (
	OpaqueMeshCount = 0
)

fseek f MshLoc#seek_set
for c = 1 to MeshCount+AddMeshCount+AlphaMeshCount+OpaqueMeshCount Do (

if(c == MeshCount + 1) then (
	fseek f AddMeshBegin #seek_set
)	

if(c == (MeshCount+AddMeshCount) + 1) then (
	fseek f AlphaMeshBegin #seek_set
)	

if(c == (MeshCount+AddMeshCount+AlphaMeshCount) + 1) then (
	fseek f OpaqueMeshBegin #seek_set
)	

	Vert_array = #()
	Normal_array = #()
	UV_array = #()
	Face_array = #()
	Weight_array = #()
	BoneID_array = #()
	
offsetstart = (ReadBElong f) + 0x18
tablestart = ftell f
	fseek f offsetstart#seek_set
TexNameOff = ReadBElong f + 0x18
FaceCount = ReadBElong f	
FaceStart = ReadBElong f 	+ 0x18
VertCount = ReadBElong f	
VertSize = ReadBElong f	
VertStart = ReadBElong f + 0x18
VertEnd = ReadBElong f + 0x18
SecBoneCount = ReadBElong f	
SecBoneIDs = (ReadBElong f) + 0x18
MaterialCount = ReadBElong f	
MaterialCountOffset = ReadBElong f

BackJump = ftell f
	
fseek f SecBoneIDs #seek_set
for i = 1 to SecBoneCount do
(
	addboneid = (ReadByte f #unsigned)
	append BoneID_array (addboneid + 1)
)
	
fseek f BackJump #seek_set
	
FaceStart = ftell f	
VerStart = (FaceCount * 2) + FaceStart


StartDirection = 1
f1 = (ReadBEword f) + 1
f2 = (ReadBEword f) + 1  
FaceDirection = StartDirection
Do (
f3 = (ReadBEword f)
if (f3==0xFFFF) then (
f1 = (ReadBEword f) + 1
f2 = (ReadBEword f) + 1
FaceDirection = StartDirection 
) else (
f3 += 1
FaceDirection *= -1
if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
if FaceDirection > 0 then append Face_array [f1,f2,f3]
else append Face_array [f1,f3,f2]
)
f1 = f2
f2 = f3
) 
) while ((ftell f) != (VerStart))
fseek f VerStart#seek_set
 test = readshort f
 if test != 0x0000 Do (
         fseek f -2 #seek_cur
)
fseek f VertStart#seek_set
for v = 1 to VertCount Do (
if VertSize == 0x24 Do (
vx = ReadBEfloat f  --read xyz coordinates
vy = ReadBEfloat f
vz = ReadBEfloat f
bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
fseek f 0x8#seek_cur
tu = ReadBEHalfFloat f   --read UV float value
tv = ReadBEHalfFloat f * -1
fseek f 0x4#seek_cur
)
if VertSize == 0x28 Do (
vx = ReadBEfloat f  --read xyz coordinates
vy = ReadBEfloat f
vz = ReadBEfloat f
fseek f 0xC#seek_cur
tu = ReadBEHalfFloat f   --read UV float value
tv = ReadBEHalfFloat f * -1
fseek f 0x4#seek_cur

bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
)
if VertSize == 0x2C Do (
vx = ReadBEfloat f  --read xyz coordinates
vy = ReadBEfloat f
vz = ReadBEfloat f
fseek f 0x10#seek_cur
tu = ReadBEHalfFloat f   --read UV float value
tv = ReadBEHalfFloat f * -1
fseek f 0x4#seek_cur
	
bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
)

if VertSize == 0x30 Do(
vx = ReadBEFloat f
vy = ReadBEFloat f
vz = ReadBEFloat f
fseek f 0xC#seek_cur
tu = ReadBEHalfFloat f
tv = ReadBEHalfFloat f * -1
fseek f 0xC#seek_cur
bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
)

if VertSize == 0x34 Do (
vx = ReadBEFloat f
vy = ReadBEFloat f
vz = ReadBEFloat f
fseek f 0x10#seek_cur
tu = ReadBEHalfFloat f
tv = ReadBEHalfFloat f * -1
fseek f 0xC#seek_cur
bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
)

if VertSize == 0x68 Do (
vx = ReadBEfloat f  --read xyz coordinates
vy = ReadBEfloat f
vz = ReadBEfloat f
fseek f 0x24#seek_cur
tu = ReadBEFloat f   --read UV float value
tv = ReadBEFloat f * -1
fseek f 0x28#seek_cur
	
bone1 = readbyte f#unsigned
bone2 = readbyte f#unsigned
bone3 = readbyte f#unsigned
bone4 = readbyte f#unsigned
weight1 = readbyte f#unsigned
weight2 = readbyte f#unsigned
weight3 = readbyte f#unsigned
weight4 = readbyte f#unsigned
)

w = (weight_data boneids:#() weights:#())

maxweight = 0
	
if(bone1 != 0xFF) then
	maxweight = maxweight + weight1
if(bone2 != 0xFF) then
	maxweight = maxweight + weight2
if(bone3 != 0xFF) then
	maxweight = maxweight + weight3
if(bone4 != 0xFF) then
	maxweight = maxweight + weight4

if(maxweight != 0) then
	(
		mxw = maxweight as float
		if(bone1 != 0xFF) then
		(
			w1 = weight1 as float
			append w.boneids (BoneID_array[bone1+1])
			append w.weights (w1 / mxw)
		)
		if(bone2 != 0xFF) then
		(
			w2 = weight2 as float
			append w.boneids (BoneID_array[bone2+1])
			append w.weights (w2 / mxw)
		)
		if(bone3 != 0xFF) then
		(
			w3 = weight3 as float
			append w.boneids (BoneID_array[bone3+1])
			append w.weights (w3 / mxw)
		)
		if(bone4 != 0xFF) then
		(
			w4 = weight4 as float
			append w.boneids (BoneID_array[bone4+1])
			append w.weights (w4 / mxw)
		)		
	)

append Vert_array [vx,-vz,vy] --save verts to Vert_array
--append Normal_array [nx,ny,nz] --save normals to Normal_array
append UV_array [tu,tv,0]  --save UVs to UV_array
append Weight_array w

)
fseek f TexNameOff#seek_set
TexName = ReadString f
print TexName

fseek f tablestart#seek_set

MaterialFile = (filepath+"/")+(TexName+".material")

msh = mesh vertices:Vert_array faces:Face_array --build mesh
msh.numTVerts = UV_array.count
buildTVFaces msh    
msh.name = TexName
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	
max modify mode
select msh
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BNArr.count do
(
	maxbone = getnodebyname BNArr[i].name
	if i != BNArr.count then (
		skinOps.addBone skinMod maxbone 0
	)else(
		skinOps.addBone skinMod maxbone 1
	)
)

modPanel.setCurrentObject skinMod

for i = 1 to Weight_array.count do
(
	w = Weight_array[i]
	bi = #() --bone index array
	wv = #() --weight value array
	
	for j = 1 to w.boneids.count do
	(
		boneid = w.boneids[j]
		weight = w.weights[j]
		append bi boneid
		append wv weight
	)	
	
	skinOps.ReplaceVertexWeights skinMod i bi wv
)

mf = fopen MaterialFile "rb"

fseek mf 0x24#seek_set
TextureTable = ReadBELong mf +0x18
fseek mf 0x6#seek_cur
TextureTotal = ReadBEWord mf

-- DiffArr = #()
-- BumpArr = #()
-- SpecArr = #()

fseek mf TextureTable#seek_set
	m = standardMaterial()
for tex = 1 to 1 Do (

	TextureNameOff = ReadBELong mf +0x18
	NextTex = ftell mf
	
	fseek mf TextureNameOff#seek_set
	fseek mf 0xC#seek_cur
	TextureName = ReadString mf +".dds"
	TexType = ReadString mf as name
	
	TextureFile = filepath+"/"+TextureName
	
-- 	print "TextureType ="
-- 	print TexType
-- 	
-- 	if TexType == "diffuse" Do (
-- 		bt = BitmapTexture()
-- 		bt.FileName = TextureFile
-- 		m.DiffuseMap = bt
-- 	)
-- 	
-- 	if TexType == "normal" Do (
-- 		nt = BitmapTexture()
-- 		nt.FileName = TextureFile
-- 		append BumpArr[nt]
-- 	)
-- 	
-- 	if TexType == "specular" Do (
-- 		st = BitmapTexture()
-- 		st.FileName = TextureFile
-- 		append SpecArr[st]
-- 	)
-- 	
-- 	if TexType == "opacity" Do (
-- 		ot = BitmapTexture()
-- 		ot.FileName = TextureFile
-- 	)
-- 	
-- 	if TexType == "reflection" Do (
-- 		rt = BitmapTexture()
-- 		rt.FileName = TextureFile
-- 	)
-- 	
-- 	if TexType == "displacement" Do (
-- 		dt = BitmapTexture()
-- 		dt.FileName = TextureFile
-- 	)
-- 	
-- 	if TexType == "gloss" Do (
-- 		gt = BitmapTexture()
-- 		gt.FileName = TextureFile
-- 	)
	
	bt = BitmapTexture()
	bt.FileName = TextureFile
	m.DiffuseMap = bt
	print bt
	)
	
-- 	fseek mf NextTex#seek_set

-- m.DiffuseMap = bt
-- m.BumpMap = nt
-- m.SpecularMap = st
-- m.OpacityMap = ot
-- m.ReflectionMap = rt
-- m.DisplacementMap = dt
-- m.GlossinessMap = gt

m.showInViewport = true
$.material = m


max create mode
)
fseek f NextHeader#seek_set
)

enableSceneRedraw()


fclose mf
fclose f
clearSelection()
actionMan.executeAction 0 "311"  -- Tools: Zoom Extents All Selected
