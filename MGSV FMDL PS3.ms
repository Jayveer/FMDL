--made by Jayveer for savemgo.com

--f = fopen "E:\\3d3b40_39.fmdl" "rb" --big boss
--f = fopen "E:\\1915a8_89.fmdl" "rb"  --horn
--f = fopen "E:\\39be78_112.fmdl" "rb" --rubble
fsource = GetOpenFileName \
caption:"Select FMDL File" \
types: "fmdl(*.fmdl)|*.fmdl|All files (*.*)|*.*|"
if fsource != undefined then (
f = fopen fsource "rb"
clearlistener()

fn readBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn readBEshort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 1 2
return short
)
	
fn readBEHalfFloat fstream = (
    hf=readBEshort fstream
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
    return bit.intasfloat outputasfloat*2
)

fn ReadBEfloat fstream = (
    fpt=readfloat fstream
    itger = bit.floatAsInt fpt
    hih = bit.intashex itger
    while hih.count < 8 do hih = "0" + hih
    shn = (substring hih 7 2) + \
    (substring hih 5 2) + \
    (substring hih 3 2) + \
    (substring hih 1 2)
    bit.intAsFloat (bit.hexasint shn)
)

fn whereTheFuckAmI = (
	print (bit.intAsHex(ftell f))
	)

fn readBEFixedString bstream fixedLen = (
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar (readbyte bstream #unsigned)
    )
    str
)
	
struct sections
(
	sectionOffset=#(),
	sectionLength=#()
)

struct indexTable
(
	entryId=#(),
	entryBlocks=#(),
	entryOffset=#()
)

struct secondIndexTable
(
	entryId=#(),
	entryOffset=#(),
	entrySize=#()
)

struct bufferTable
(
	bufferOffset=#(),
	bufferSize=#()
)

struct stringTable
(
	dataType=#(),
	stringLength=#(),
	stringOffset=#()
)

struct meshList
(
	stringArrayEntry=#(),
	unknown=#(),
	meshParent=#(),
	unknown2=#()
)

fmdlSections= sections()
fmdlEntries = indexTable()
fmdlEntries2 = secondIndexTable()
fmdlBuffers = bufferTable()
fmdlStrings = stringTable()

Face_array=#()
Vert_array=#()
UV_array=#()
Normal_array=#()
String_array=#()
Weight_array=#()
vertSize = #()
faceSize= #()
BNArr = #()
vBufSize =#()
--
faceOffset=#()
aFaceSize=#()

fseek f 0x20 #seek_set

noEntries = readBElong f
noEntries2 = readBElong f

for i = 1 to 2 do
(
	fmdlSections.sectionOffset[i] = readBElong f
	fmdlSections.sectionLength[i] = readBElong f
)

fseek f 0x08 #seek_cur 

for i = 1 to noEntries do
(
	id = readshort f
	if id == 0 then
	(
		id = 99 --annoying that maxscript cant accept 0 as an array index, so I have to do this shit hack
	)
	fmdlEntries.entryId[id] = id
	fmdlEntries.entryBlocks[id] = readBEshort f
	fmdlEntries.entryOffset[id] = readBElong f
)
 
for i = 1 to noEntries2 do
(
	id = readbyte f
	fseek f 0x03 #seek_cur
	if id == 0 then
	(
		id = 99 --annoying that maxscript cant accept 0 as an array index, so I have to do this shit hack
	)
	fmdlEntries2.entryId[id] = id
	fmdlEntries2.entryOffset[id] = readBElong f
	fmdlEntries2.entrySize[id] = readBElong f
)

--id 00 = Bone Table
--id 01 = Mesh list
--id 02 = Mesh Group Table
--id 03 = Vertex + Face index table
--id 04 = 
--id 05 = Bone Lookup Table
--id 06 = Tex list
--id 07 = Mat list
--id 08 =
--id 09 =
--id 0A = something to do with vdef
--id 0B = ?? big mystery
--id 0C = String Def Table
--id 0D = floats, the same as bones
--id 0E = Buffer Offset Table
--id 11 = face index table

/** 

They may have taken the string table out for FMDLs in TPP so removing this for now

--id 0C = string table
fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[0x0C]) #seek_set 
for x = 1 to (fmdlEntries.entryBlocks[0x0C]) do
(
		fmdlStrings.dataType[x] = readBEshort f
		fmdlStrings.stringLength[x] = readBEshort f
		fmdlStrings.stringOffset[x] = readBElong f
)

--populate String Array
for x = 1 to (fmdlEntries.entryBlocks[0x0C]) do
(	
		fseek  f (fmdlSections.sectionOffset[2] + fmdlEntries2.entryOffset[3] + fmdlStrings.stringOffset[x]) #seek_set
		String_array[x] = readBEFixedString f fmdlStrings.stringLength[x]
)

*/


--id 0A = Vert Def Table, or something
fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[0x0A]) #seek_set 
for x = 1 to (fmdlEntries.entryBlocks[0x03] ) do
(
		fseek f 0x0A #seek_cur
		vBufSize[x] = readbyte f

		if vBufSize[x] == 0x1C or vBufSize[x] == 0x14 then
		(
			fseek f 0xD #seek_cur
		)
		else
		(
			fseek f 0x15 #seek_cur
		)
)
/*
--id 00 = bones, oh sorry, 99 because maxscript is a piece of shit (if it doesnt have this id it doesn't have bones)
if (fmdlEntries.entryBlocks[99] != undefined) then
(
	fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[99]) #seek_set 

	for x = 1 to (fmdlEntries.entryBlocks[99]) do
	(	
		boneid = (readBEshort f) as string
		boneparent = (readBEshort f) +1	
		boneidx = readBEshort f 
	
		unknown = readBEshort f--mostly always 0x01?
		unknown = readBElong  f--always 0
		unknown = readBElong f --always 0

		b1x = readBEfloat f
		b1y = readBEfloat f
		b1z = readBEfloat f	
		b1w = readBEfloat f	
		b2x = readBEfloat f
		b2y = readBEfloat f
		b2z = readBEfloat f
		b2w = readBEfloat f

		tfm = (quat 0 0 0 1) as matrix3
		tfm.row4 = [b1x,b1y,b1z]
		if isvalidnode (getNodeByName boneid) == true Do 
		(
			append BNArr (getNodeByName boneid)
		)
		if isvalidnode (getNodeByName boneid) != true Do 
		(
			if (boneparent != 0) do 
			(
			tfm = tfm * BNArr[boneparent].objecttransform
			)	

			newBone = bonesys.createbone	tfm.row4 (tfm.row4 + 0.01 * (normalize tfm.row1)) (normalize tfm.row3)

			newBone.name   =  String_array[((boneid as integer)+1)]
			newBone.width  = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			--newBone.wirecolor = white
			newBone.showlinks = true
			newBone.setBoneEnable true 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
			if (boneparent != 0) then
				newBone.parent = BNArr[boneparent]
			append BNArr newBone
 
		)

	)
)
*/
--id 03 = vertex index table
fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[3])  #seek_set 
for x=1 to fmdlEntries.entryBlocks[3] do
(
	fseek f 0xA #seek_cur
	
	print("vertsizeoffset")
	whereTheFuckAmI()
	--vertSize[x] = readBElong f
	vertSize[x] = readBEshort f
	fseek f 0x02 #seek_cur
	uk = readBEshort f
	uk = readBEshort f
	--faceOffset[x] = readBElong f
	faceOffset[x] = readBEshort f
	print(bit.intAsHex(faceOffset[x]))
	--aFaceSize[x] = readBElong f
	fseek f 0x02 #seek_cur
	aFaceSize[x] = readBEshort f
	fseek f 0x18 #seek_cur	
)
/*	
--id 03 = face index table	
fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[0x11])  #seek_set
for x=1 to fmdlEntries.entryBlocks[3] do
(
	if (fmdlEntries.entryBlocks[0x11] == fmdlEntries.entryBlocks[0x03]) then
	(
		print("It was this type")
		fseek f 0x4 #seek_cur
		faceSize[x] = readBElong f
	)
	else
	(
		fseek f 0x18 #seek_cur
		val1 = readBElong f
		val2 = readBElong f
		faceSize[x] = val1 + val2
	)
)
*/
--id 0E = Buffer offset table	
fseek f (fmdlSections.sectionOffset[1] + fmdlEntries.entryOffset[0x0E])  #seek_set
for x=1 to fmdlEntries.entryBlocks[0x0E] do
(
	fseek f 0x4 #seek_cur
	fmdlBuffers.bufferSize[x] = readBElong f
	fmdlBuffers.bufferOffset[x] = readBElong f
	fseek f 0x4 #seek_cur
)
	
--id 02 of second index = vertex buffer
vertexOffset = (fmdlSections.sectionOffset[2] +fmdlEntries2.entryOffset[2])--0x5C00
fseek f vertexOffset #seek_set

--id 02 of second index = vertex buffer + 3rd entry of buffer table = face buffer
lastFacePos = ((fmdlSections.sectionOffset[2] +fmdlEntries2.entryOffset[2]) + fmdlBuffers.bufferOffset[3])--0x78450 

--id 02 of second index = vertex buffer + 2nd entry of buffer table = vdef buffer
lastUVPos = ((fmdlSections.sectionOffset[2] +fmdlEntries2.entryOffset[2]) + fmdlBuffers.bufferOffset[2])--0x25860

for n = 1 to fmdlEntries.entryBlocks[3] do
(
	print("vbuf offset")
	print(whereTheFuckAmI())
	print(vertSize[n])
	--vertex buffer
	for x=1 to vertSize[n] do
	(
		vx=readBEfloat f
		vy=readBEfloat f
		vz=readBEfloat f
		
		append Vert_array[vx,vy,vz]
		--comment below if you want to give UVs a try
		append UV_array[0,0,0]
	)
	
	while mod (ftell f) 16 !=0 do
	(
		fseek f 0x4 #seek_cur
	)
	
	lastVertPos = ftell f
	
	--uncomment below if you want to give uv's a try, wont always work isn't completely ported
/*
	--temp testing
	fseek f lastUVPos #seek_set
	
	whereTheFuckAmI()
	
	for x =1 to vertSize[n] do
	(	
		nx = readBEhalffloat f
		ny = readBEhalffloat f
		nz = readBEhalffloat f
		nw = readBEhalffloat f
		uk = readBEhalffloat f
		uk = readBEhalffloat f
		uk = readBEhalffloat f
		uk = readBEhalffloat f

		if vBufSize[n] == 0x20 or vBufSize[n] == 0x1C  then
		(
		
		bw1 = readbyte f#unsigned / 255
		bw2 = readbyte f#unsigned / 255
		bw3= readbyte f#unsigned / 255
		bw4 = readbyte f#unsigned / 255
		bidx1 = readbyte f
		bidx2 = readbyte f
		bidx3 = readbyte f
		bidx4 = readbyte f
		
		if vBufSize[n] == 0x20 then
		(
			uk = readBEfloat f
		)
		
		)
		tu = readBEhalffloat f
		tv = readBEhalffloat f*-1
		
		append UV_array[tu,tv,0]
		append Normal_array[nx,ny,nz]
	)
	
	while mod (ftell f) 16 !=0 do
	(
		fseek f 0x4 #seek_cur
	)
	
	lastUVPos = ftell f
*/
	--face buffer
	
	--fseek f lastFacePos #seek_set
	fseek f (lastFacePos + (faceOffset[n]*2)) #seek_set
	

	for n=1 to aFaceSize[n]/3 do
	(
		fa=readBEShort f +1
		fb=readBEShort f +1
		fc=readBEShort f +1
			
		append Face_array[fc, fb, fa]
	)
	
	--lastFacePos = ftell f

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_array.count
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	--for j = 1 to Normal_array.count do setnormal msh j Normal_array[j]
	
	
	--print Normal_Array
	Face_array=#()  
	Vert_array=#()	
	UV_array=#()	
	Normal_array=#()		

	fseek f lastvertPos #seek_set
)	
gc()
fclose f
)
else 
(
	clearlistener()
)
