
-------------------------------------------
-- Prop to holo converter
-- by shadowscion

AddCSLuaFile( "p2h/convert.lua" )

-------------------------------------------
-- Shared
TOOL.Name     = "E2 Hologram Converter"
TOOL.Category = "Render"

if WireLib then
    TOOL.Tab                  = "Wire"
    TOOL.Wire_MultiCategories = { "Tools" }
end

TOOL.ClientConVar = {
    ["radius"] = 64,
    ["clipboard"] = 1,
    ["openeditor"] = 1,
    ["vclips"] = 1,
}


-------------------------------------------
-- Client
if CLIENT then
    include( "weapons/gmod_tool/stools/p2h/convert.lua" )

    language.Add( "Tool.p2h_converter.name", "E2 Hologram Converter" )
    language.Add( "Tool.p2h_converter.desc", "Converts props into holograms for use with expression2." )
    language.Add( "Tool.p2h_converter.0", "Click to select or deselect an entity. Hold USE to select entities within a radius. Right click to finalize." )

    TOOL.LeftClick  = function() return true end
    TOOL.RightClick = function() return true end

    local PANEL_TEXT_COLOR = Color( 0, 0, 0 )

    function TOOL.BuildCPanel( self )
        -- Base panel
        self.Paint = function( pnl, w, h )
            draw.RoundedBox( 0, 0, 0, w, 20, Color( 50, 50, 50, 255 ) )
            draw.RoundedBox( 0, 1, 1, w - 2, 18, Color( 125, 125, 125, 255 ) )
        end

        -- Root category element
        local root = vgui.Create( "DCollapsibleCategory" )

        root:SetLabel( "Options" )
        root:SetExpanded( 1 )
        self:AddItem( root )

        root.Paint = function( pnl, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 255 ) )
            draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 175, 175, 175, 255 ) )
            draw.RoundedBox( 0, 1, 1, w - 2, 18, Color( 125, 125, 125, 255 ) )
        end

        -- List container
        local container = vgui.Create( "DPanelList" )

        container:SetAutoSize( true )
        container:SetDrawBackground( false )
        container:SetSpacing( 5 )
        container:SetPadding( 5 )
        root:SetContents( container )

        ------------------------------------
        -- Clipboard toggle
        local xbox = vgui.Create( "DCheckBoxLabel" )

        xbox:SetText( "Copy to clipboard." )
        xbox:SetTextColor( PANEL_TEXT_COLOR )
        xbox:SetValue( 1 )
        xbox:SetConVar( "p2h_converter_clipboard" )
        container:AddItem( xbox )

        ------------------------------------
        -- Editor toggle
        local xbox = vgui.Create( "DCheckBoxLabel" )

        xbox:SetText( "Open in expression2 editor." )
        xbox:SetTextColor( PANEL_TEXT_COLOR )
        xbox:SetValue( 1 )
        xbox:SetConVar( "p2h_converter_openeditor" )
        container:AddItem( xbox )

        ------------------------------------
        -- VClip toggle
        local xbox = vgui.Create( "DCheckBoxLabel" )

        xbox:SetText( "Enable visclip support." )
        xbox:SetTextColor( PANEL_TEXT_COLOR )
        xbox:SetValue( 1 )
        xbox:SetConVar( "p2h_converter_vclips" )
        container:AddItem( xbox )

        ------------------------------------
        -- Set selection radius
        local ctrl = vgui.Create( "DNumSlider" )

        ctrl:SetText( "Selection radius." )
        ctrl.Label:SetTextColor( PANEL_TEXT_COLOR )
        ctrl:SetMin( 0 )
        ctrl:SetMax( 4096 )
        ctrl:SetDecimals( 0 )
        ctrl:SetConVar( "p2h_converter_radius" )
        container:AddItem( ctrl )
    end

    return
end


-------------------------------------------
-- Server
util.AddNetworkString( "p2h_converter" )

TOOL.Selection      = {}
TOOL.SelectionColor = Color( 0, 255, 0, 125 )

-------------------------------------------
-- Checks if an entity belongs to a player
local function IsPropOwner( ply, ent )
    if CPPI then return ent:CPPIGetOwner() == ply end

    for k, v in pairs( g_SBoxObjects ) do
        for b, j in pairs( v ) do
            for _, e in pairs( j ) do
                if e == ent and k == ply:UniqueID() then return true end
            end
        end
    end

    return false
end

-------------------------------------------
-- Checks if an entity is already selected
function TOOL:IsSelected( ent )
    return self.Selection[ent] ~= nil
end

-------------------------------------------
--  Adds an entity to selection
function TOOL:Select( ent )
    if not self:IsSelected( ent ) then
        local oldColor = ent:GetColor()

        ent:SetColor( self.SelectionColor )
        ent:SetRenderMode( RENDERMODE_TRANSALPHA )
        ent:CallOnRemove( "e2holo_convertor_onrmv", function( e )
            self:Deselect( e )
            self.Selection[e] = nil
        end )

        self.Selection[ent] = oldColor
    end
end

-------------------------------------------
-- Removes an entity from selection
function TOOL:Deselect( ent )
    if self:IsSelected( ent ) then
        local oldColor = self.Selection[ent]

        ent:SetColor( oldColor )
        ent:SetRenderMode( oldColor.a ~= 255 and RENDERMODE_TRANSALPHA or RENDERMODE_NORMAL )

        self.Selection[ent] = nil
    end
end

-------------------------------------------
-- Left click ( selection )
function TOOL:LeftClick( eye )

    -- Filter out bad entities
    local user   = self:GetOwner()
    local hitEnt = eye.Entity

    if not IsValid( user ) or ( hitEnt:IsWorld() and not user:KeyDown( IN_USE ) ) then
        return false
    end

    if IsValid( hitEnt ) then
        if hitEnt:IsPlayer() then return false end
        if not IsPropOwner( user, hitEnt ) then return false end
        if not util.IsValidPhysicsObject( hitEnt, eye.PhysicsBone ) then return false end
    end

    -- Area select
    if user:KeyDown( IN_USE ) then
        local radius = math.Clamp( self:GetClientNumber( "radius" ), 64, 4096 )

        for _, ent in pairs( ents.FindInSphere( eye.HitPos, radius ) ) do
            if not IsValid( ent ) or not IsPropOwner( user, ent ) then continue end
            self:Select( ent )
        end

        return false
    end

    -- Deselect entity if already selected
    if self:IsSelected( hitEnt ) then self:Deselect( hitEnt ) return false end

    -- Otherwise add to selection
    self:Select( hitEnt )

    -- No serverside tool sounds
    return false

end

-------------------------------------------
-- Right click ( finalize )
function TOOL:RightClick( eye )

    -- Filter out bad entities
    local user   = self:GetOwner()
    local hitEnt = eye.Entity

    if not IsValid( user ) or not IsValid( hitEnt ) or hitEnt:IsWorld() then
        return false
    end

    if hitEnt:IsPlayer() then return false end
    if not IsPropOwner( user, hitEnt ) then return false end
    if not util.IsValidPhysicsObject( hitEnt, eye.PhysicsBone ) then return false end

    -- Remove base entity from selection
    self:Deselect( hitEnt )

    -- Send entity list to client
    local selectionCount = table.Count( self.Selection )

    net.Start( "p2h_converter" )
        -- Base entity
        net.WriteUInt( hitEnt:EntIndex(), 16 )

        -- Entity list
        if selectionCount >= 1 then
            net.WriteUInt( selectionCount, 16 )
            for ent, _ in pairs( self.Selection ) do
                net.WriteUInt( ent:EntIndex(), 16 )
                self:Deselect( ent )
            end
        end
    net.Send( user )

    -- Clear selection
    self.Selection = {}

    -- No serverside tool sounds
    return false

end
