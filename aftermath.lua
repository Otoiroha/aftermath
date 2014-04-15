--[[
Copyright (c) 2014, kotodamage
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'aftermath'
_addon.version = '0.1'
_addon.author = 'kotodamage'
_addon.command = 'aftermath'

chat = require('chat')

-- global variables
lasttp = 0

windower.register_event('addon command', function(...)
    local args = {...}
    local comm
    local helptext
    local player
    local tp
    local duration
    local w_type
    local am_level
    local icon
    local present = nil

    if args[1] ~= nil then
        comm = args[1]:lower()

        -- switch with subcommands
        if comm == 'help' then
            -- aftermath help
            helptext = [[aftermath - Command List:
1. aftermath register R|M|E -- start timers. specify weapon type.
    Relic = 'R'
    Mythic = 'M'
    Empy = 'E'
2. aftermath delete -- delete timers. please call this when aftermath is removed.
3. aftermath help -- print this message.]]
            for _, line in ipairs(helptext:split('\n')) do
                windower.add_to_chat(207, line..chat.controls.reset)
            end

        elseif comm == 'register' then
            -- aftermath register
            -- get player status
            player = windower.ffxi.get_player()
            tp = player.vitals.tp

            -- get weapon type
            w_type = args[2]
            if w_type == 'R' then
                duration = math.floor(tp * 0.2)
            elseif w_type == 'M' then
                duration = math.floor(tp * 0.6)
            elseif w_type == 'E' then
                duration = math.floor(tp * 0.3)
            else
                windower.add_to_chat(
                207,
                '[aftermath] Please specify weapon type. e.g) aftermath register R' .. chat.controls.reset
                )
                return
            end

            -- determine aftermath level
            if w_type == 'R' then
                am_level = 1
                icon = 'spells/00033.png'
            else
                if tp < 100 then
                    return
                elseif tp < 200 then
                    am_level = 1
                    icon = 'spells/00033.png'
                elseif tp < 300 then
                    am_level = 2
                    icon = 'spells/00034.png'
                else
                    am_level = 3
                    icon = 'spells/00035.png'
                end
            end

            -- check now have AMs
            for key,value in pairs(player.buffs) do
                if value == 270 then
                    present = 1
                elseif value == 271 then
                    present = 2
                elseif value == 272 then
                    present = 3
                elseif value == 273 then
                    present = 1
                end
            end

            -- register timers
            if present then
                -- when have AMs
                if lasttp < tp or w_type == 'R' then
                    windower.send_command('timers create AM' .. am_level .. ' ' .. duration .. ' down ' .. icon)
                    lasttp = tp
                    for i = am_level, 1 , -1 do
                        windower.send_command('timers delete AM' .. i)
                    end
                end
            else
                -- when dont have AMs
                windower.send_command('timers create AM' .. am_level .. ' ' .. duration .. ' down ' .. icon)
                lasttp = tp
            end

        elseif comm == 'delete' then
            -- aftermath delete
            for i = 3, 1 , -1 do
                windower.send_command('timers delete AM' .. i)
            end
            lasttp = 0
        end
    end
end)

