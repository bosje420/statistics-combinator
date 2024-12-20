
local MK1 = "production-combinator"
local MK2 = "consumption-combinator"
local MK = {[MK1]=true,[MK2]=true}

 
--------------------------------------------------------------------------------





local precision_ticks = 60


--------------------------------------------------------------------------------
local flow_precisions = defines.flow_precision_index
local precisions = {{flow_precisions.five_seconds, 0.0833}, {flow_precisions.one_minute, 1},{flow_precisions.ten_minutes, 10}, {flow_precisions.one_hour, 60}, {flow_precisions.ten_hours, 60*10}, {flow_precisions.fifty_hours, 60*50}}


local function write_output_statistics(control, force, time_step, iostat)
    local params = control.parameters
    for i,signalID in pairs(params) do
        if signalID.signal.name ~= nil then
            local count = 0
            if signalID.signal.type == "item" then
                count = force.item_production_statistics.get_flow_count{name=signalID.signal.name, input=iostat, precision_index=time_step[1], count=false}
            elseif signalID.signal.type == "fluid" then
                count = force.fluid_production_statistics.get_flow_count{name=signalID.signal.name, input=iostat, precision_index=time_step[1], count=false}
            end
            signalID.count = math.floor(0.5+(time_step[2]*count))
            params[i] = signalID
        end
    end
    control.parameters = params

end

--------------------------------------------------------------------------------

local function State(entity)
    local state = {entity=entity, tick=game.tick}
    
    
    state.control = entity.get_or_create_control_behavior()
    state.time_step = precisions[1]
   
    return state
end

local function write(state, tick)
    local control = state.control
    local iostat = state.entity.name == "production-combinator"
    write_output_statistics(control, state.entity.force, state.time_step, iostat)

 
  --  local b = a.signals[4].signal.name
   -- local c = state.entity.force.item_production_statistics.get_flow_count{name=b, input=true, precision_index=defines.flow_precision_index.one_minute, count=false}

end

--------------------------------------------------------------------------------

local function alloc(entity)
    if entity and entity.unit_number and MK[entity.prototype.name] then
        global.state[entity.unit_number] = State(entity)
    end
end

local function cleanup(entity)
    if entity and entity.unit_number then
        local state = global.state[entity.unit_number]
        if state then
            global.state[entity.unit_number] = nil
        end
    end
end

local function update(tick)
    if tick %  precision_ticks > 0 then return end
    local invalid = {}
    local size = 1
    for id, state in pairs(global.state) do
        if not (state.entity and state.entity.valid) then
            invalid[size] = id
        elseif state.tick < tick and state.control.enabled then
            write(state, tick)
        end
    end
    for _, id in ipairs(invalid) do cleanup{unit_number=id} end
end
local function make_gui(player)
    local anchor = {gui=defines.relative_gui_type.constant_combinator_gui, position=defines.relative_gui_position.right, names={"production-combinator", "consumption-combinator"}}
    if player.gui.relative["stat-comb-gui"] == nil then
        local frame = player.gui.relative.add{name="stat-comb-gui",type="frame", anchor=anchor}
        frame.add{type="label", caption="Precision"}
        frame.add{name="stat-comb-dropdown",type="drop-down", items={"5s", "1m", "10m", "1h", "10h", "50h"}}
    end

end
local function init()
    global.state = {}
    global.last_clicked = 0
    for _, surface in pairs(game.surfaces) do
        for _, combinator in pairs(surface.find_entities_filtered{name={MK1,MK2}}) do
            alloc(combinator)
        end
    end

    for _, player in pairs(game.players) do
        make_gui(player)

    end

    
end


--------------------------------------------------------------------------------

local filters = {
    {filter = "name", name = MK1},
    {filter = "name", name = MK2},
}

local events = {
    entity = {
        added = {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            defines.events.script_raised_built,
        },
        removed = {
            defines.events.on_entity_died,
            defines.events.on_robot_mined_entity,
            defines.events.on_player_mined_entity,
            defines.events.script_raised_destroy,
        },
    },
}

--------------------------------------------------------------------------------

script.on_init(init)
script.on_configuration_changed(init)
script.on_event(defines.events.on_player_created, function (event)
    local player = game.get_player(event.player_index)
    make_gui(player)

end)

script.on_event(defines.events.on_gui_opened, function (event)
    local player = game.get_player(event.player_index)
    local gui = player.gui.relative["stat-comb-gui"]
    if event.gui_type ~= nil and event.gui_type == defines.gui_type.entity then
        if player.opened ~= nil then
            if gui ~= nil and gui["stat-comb-dropdown"] ~= nil  and player.opened["name"] ~= nil  then
                if (player.opened.name == "production-combinator" or player.opened.name == "consumption-combinator") then
                    gui["stat-comb-dropdown"].selected_index = (global.state[player.opened.unit_number].time_step[1] + 1)
                end
            end
        end
    end
end)
script.on_event(defines.events.on_gui_selection_state_changed, function (event)
    if event.element.name == "stat-comb-dropdown" then
        local player = game.get_player(event.player_index)
        global.state[player.opened.unit_number].time_step = precisions[event.element.selected_index]
    end
end)

script.on_event(events.entity.added, function (event)
    alloc(event.created_entity or event.entity)
end)
script.on_event(events.entity.removed, function (event)
    cleanup(event.entity)
end)
script.on_event(defines.events.on_tick, function (event)
    update(event.tick)
end)

for _,events in pairs(events.entity) do
    for _,event in ipairs(events) do
        script.set_event_filter(event, filters)
    end
end
