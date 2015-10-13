
-------------------------------------------
-- Prop to holo converter
-- by shadowscion
if not CLIENT then return end

local string = string

local str_Holo = "    HN++,HT[HN,array] = array(%d,vec(%f,%f,%f),ang(%f,%f,%f),\"%s\",\"%s\",vec4(%d,%d,%d,%d))\n"

local str_Header = [[
#[
    Important!!!!!!!!!

    Holograms are not magic, they are still entities and they still take server resources.
    You should consider them the same as you would any other prop.

    Ideally this tool is to be used for minor details, not entire contraptions.
]#

@name <NAME>
@inputs BaseProp:entity
@persist [ID SpawnStatus CoreStatus]:string [HT CT BG]:table [HN CN SpawnCounter ScaleFactor ToggleColMat ToggleShading] BaseParent:entity Rescale:vector

if ( dupefinished() | first() ) {

    #Settings
    ScaleFactor   = 1 #scales the contraption
    ToggleColMat  = 1 #disables materials and color
    ToggleShading = 0 #disables shading


    #Holo data
]]

local str_Footer = [[


    #[
        HOLOGRAM LOADER - DO NOT EDIT BELOW THIS LINE

        IF YOU WISH TO EDIT HOLOGRAMS AFTER SPAWNING, PLACE CODE AFTER THE

        elseif ( CoreStatus == "InitPostSpawn" ) {

        CODEBLOCK AT THE BOTTOM
    ]#

    BaseParent = BaseProp ?: entity()
    Rescale = vec( ScaleFactor )

    function array:holo() {
        local Index = This[1, number]
        local Parent = Index != 1 ? holoEntity( 1 ) : BaseParent

        holoCreate( Index, Parent:toWorld( This[2, vector]*ScaleFactor ), Rescale, Parent:toWorld( This[3, angle] ), vec( 255 ), This[4, string] ?: "cube" )
        holoParent( Index, Parent )

        if ( ToggleColMat ) {
            holoMaterial( Index, This[5, string] )
            holoColor( Index, This[6, vector4] )
        }

        if ( ToggleShading ) { holoDisableShading( Index, 1 ) }
        if ( This[7, number] ) { holoSkin( Index, This[7, number] ) }
        if ( BG[Index, array] ) { foreach ( K, Group:vector2 = BG[Index, array] ) { holoBodygroup( Index, Group[1], Group[2] ) } }

        if ( CT[Index, table] ) {
            for ( I = 1, CT[Index, table]:count() ) {
                local Clip = CT[Index, table][I, array]
                holoClipEnabled( Index, Clip[1, number], 1 )
                holoClip( Index, Clip[1, number], Clip[2, vector]*ScaleFactor, Clip[3, vector], 0 )
                CN++
            }
        }
    }

    function loadContraption() {
        switch ( SpawnStatus ) {
            case "InitSpawn",
                if ( clk( "Start" ) ) {
                    SpawnStatus = "LoadHolograms"
                }
                soundPlay( "Blip", 0, "@^garrysmod/content_downloaded.wav", 0.212 )
            break

            case "LoadHolograms",
                while ( perf() & holoCanCreate() &  SpawnCounter < HN ) {
                    SpawnCounter++
                    HT[SpawnCounter, array]:holo()

                    if ( SpawnCounter >= HN ) {
                        SpawnStatus = "PrintStatus"
                        SpawnCounter = 0
                        break
                    }
                }
            break

            case "PrintStatus",
                printColor( vec( 125, 255, 125 ), "HoloCore: ", vec( 255, 255, 255 ), "Loaded " + HN + " holograms and " + CN + " clips." )

                CoreStatus = "InitPostSpawn"
                SpawnStatus = ""
            break
        }
    }

    runOnTick( 1 )
    timer( "Start", 500 )

    CoreStatus = "InitSpawn"
    SpawnStatus = "InitSpawn"

}

#----------------------
#-- Load the hologram and clip data arrays.
elseif ( CoreStatus == "InitSpawn" ) {
    loadContraption()
}


#----------------------
#-- This is like if ( first() ) { }, code here is run only once.
elseif ( CoreStatus == "InitPostSpawn" ) {
    CoreStatus = "RunThisCode"

    interval( 0 ) #start or stop clk

    runOnTick( 0 ) #start or stop tick
}


#----------------------
#-- This is where executing code goes
elseif ( CoreStatus == "RunThisCode" ) {
    if ( clk() ) {
        #interval( 15 )

    }

    if ( tickClk() ) {

    }
}
]]


-------------------------------------------
-- FUNC: Returns table of entity info
-- ARGS: base entity, selection table
local function SetupEntityInfo( base, ents )
    local ret = {}

    local doClips = tobool( GetConVarNumber( "p2h_converter_vclips" ) )

    for _, ent in ipairs( ents ) do
        local entry = {
            lpos = base:WorldToLocal( ent:GetPos() ),
            lang = base:WorldToLocalAngles( ent:GetAngles() ),
            model = string.lower(ent:GetModel()),
            material = string.lower(ent:GetMaterial()),
            color = ent:GetColor(),
        }

        if _ == 1 then entry.lang = ent:GetAngles() end

        -- bodygroup support
        if ent:GetSkin() > 0 then entry.skin = ent:GetSkin() end

        local bgroups = ent:GetBodyGroups()
        if #bgroups > 1 then
            local groups = {}
            for _, bgroup in pairs( bgroups ) do
                if bgroup.num <= 1 then continue end
                if bgroup.num == 2 then
                    if ent:GetBodygroup( bgroup.id ) == 1 then groups[#groups + 1] = { id = bgroup.id, state = 1 } end
                else
                    for i = 2, bgroup.num do
                        if ent:GetBodygroup( bgroup.id ) == i - 1 then groups[#groups + 1] = { id = bgroup.id, state = i - 1 } end
                    end
                end
            end
            if #groups > 0 then entry.bodygroups = groups end
        end

        if not doClips or not ent.ClipData then ret[#ret + 1] = entry continue end

        -- visclip support ( requires wrex's workshop version )
        entry.clips = {}

        for _, clip in ipairs( ent.ClipData ) do
            entry.clips[#entry.clips + 1] = {
                ldir = clip[1]:Forward(),
                lpos = clip[1]:Forward()*clip[2],
            }
        end

        ret[#ret + 1] = entry
    end

    return ret
end

-------------------------------------------
-- FUNC: Returns formatted e2 code
-- ARGS: script name, entity info table
local function FormatEntityInfo( name, info )
    local ret = string.Replace( str_Header, "<NAME>", name or "defaultname" )

    for i, entry in pairs( info ) do
        local line = string.format(
            str_Holo, i,
            entry.lpos.x, entry.lpos.y, entry.lpos.z,
            entry.lang.p, entry.lang.y, entry.lang.r,
            entry.model, entry.material,
            entry.color.r, entry.color.g, entry.color.b, entry.color.a
        )

        -- bodygroup support
        if entry.skin then line = string.Left( line, #line - 2 ) .. "," .. entry.skin .. ")" end

        if entry.bodygroups then
            line = line .. "\n    #Bodygroup data <" .. i .. ">\n    BG[" .. i .. ",array] = array("
            for bi, bgroup in ipairs( entry.bodygroups ) do
                line = line .. "\n        vec2(" .. bgroup.id .. "," .. bgroup.state .. ")" .. ( bi ~= #entry.bodygroups  and "," or "\n    )\n" )
            end
            if i ~= #info then line = line .. "\n    #Holo data\n" end
        end

        if not entry.clips then ret = ret .. line continue end

        -- visclip support ( requires wrex's workshop version )
        line = line .. "\n    #Clip data <" .. i .. ">\n    CT[" .. i .. ",table] = table("

        for ci, clip in ipairs( entry.clips ) do
            line = line .. string.format("\n        array(%d,vec(%f,%f,%f),vec(%f,%f,%f))" .. (ci ~= #entry.clips and "," or "\n    )\n"),
                ci,
                clip.lpos.x, clip.lpos.y, clip.lpos.z,
                clip.ldir.x, clip.ldir.y, clip.ldir.z
            )
        end

        if i ~= #info then line = line .. "\n    #Holo data\n" end
        ret = ret .. line
    end

    ret = ret .. str_Footer

    return ret
end

-------------------------------------------
-- FUNC: Handles data recieved from server
-- ARGS: script name, entity info table
local function PostListGet( name, base, ents )
    local data = SetupEntityInfo( base, ents )
    local code = FormatEntityInfo( name, data )

    file.Write( "p2h_auto.txt", code )

    if tobool( GetConVarNumber( "p2h_converter_clipboard" ) ) then
        SetClipboardText( code )
    end

    if not WireLib then return end
    if not tobool( GetConVarNumber( "p2h_converter_openeditor" ) ) then return end

    spawnmenu.ActivateTool( "wire_expression2" )

    openE2Editor()
    if wire_expression2_editor then
        wire_expression2_editor:NewTab()
        wire_expression2_editor:SetCode( code )
    end

end

-------------------------------------------
-- FUNC: Recieves data from server
local function GetListFromServer()
    local eid = net.ReadUInt( 16 )
    local base = Entity( eid )

    if not IsValid( base ) then return end

    local ents = { base }
    local count = net.ReadUInt( 16 )

    for i = 1, count do
        local eid = net.ReadUInt( 16 )
        local ent = Entity( eid )

        if not IsValid( ent ) then continue end

        ents[#ents + 1] = ent
    end

    Derma_StringRequest(
        "Expression2 Script Name", "Please enter a name for your script!", "default_script_name",

        function ( text )
            PostListGet( text, base, ents )
        end,

        function () end
    )
end
net.Receive( "p2h_converter", GetListFromServer )
