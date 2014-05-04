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
_addon.version = '0.2'
_addon.author = 'kotodamage'
_addon.command = 'aftermath'

chat = require('chat')

-- global variables
g_last_tp = 0
g_last_limit = 0

windower.register_event('addon command', function(...)
    local args = {...}
    local comm
    local helptext
    local player
    local present_tp
    local duration
    local w_type
    local next_am
    local icon
    local available_am = nil
    local left_time = 0

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
            present_tp = player.vitals.tp

            -- get weapon type
            w_type = args[2]
            if w_type == 'R' then
                duration = math.floor(present_tp * 0.2)
            elseif w_type == 'M' then
                duration = math.floor(present_tp * 0.6)
            elseif w_type == 'E' then
                duration = math.floor(present_tp * 0.3)
            else
                windower.add_to_chat(
                    207,
                    '[aftermath] Please specify weapon type. e.g) aftermath register R' .. chat.controls.reset
                )
                return
            end

            -- determine aftermath level
            if present_tp < 100 then
                return
            else
                if w_type == 'R' then
                    next_am = 1
                    icon = 'spells/00033.png'
                elseif present_tp < 200 then
                    next_am = 1
                    icon = 'spells/00033.png'
                elseif present_tp < 300 then
                    next_am = 2
                    icon = 'spells/00034.png'
                else
                    next_am = 3
                    icon = 'spells/00035.png'
                end
            end

            -- check now have AMs
            for key,value in pairs(player.buffs) do
                if value == 270 then
                    available_am = 1
                elseif value == 271 then
                    available_am = 2
                elseif value == 272 then
                    available_am = 3
                elseif value == 273 then
                    available_am = 1
                end
            end

            -- タイマー登録
            if available_am then
                -- 前回AMが有効な場合
                -- 前回AMの残時間を計算
                left_time = g_last_limit - os.clock()
                if w_type == 'R' then
                    -- レリックの場合、常に残時間と比較する
                    if left_time < duration then
                        registerTimer(next_am, present_tp, duration, icon)
                    end

                elseif w_type == 'M' then
                    -- ミシックの場合
                    if available_am == 1 and next_am == 1 then
                        -- 前後ともにAM1の場合、残時間と比較する
                        if left_time < duration then
                            registerTimer(next_am, present_tp, duration, icon)
                        end
                    elseif available_am == 2 and next_am == 2 then
                        -- 前後ともにAM2の場合、発動時TPと比較する
                        if g_last_tp < present_tp then
                            registerTimer(next_am, present_tp, duration, icon)
                        end
                    elseif available_am < next_am then
                        -- 前回AMよりもLvが高い場合登録
                        registerTimer(next_am, present_tp, duration, icon)
                        deleteTimers(next_am - 1)
                    end

                elseif w_type == 'E' then
                    -- エンピの場合
                    if available_am == next_am then
                        -- 前後のAMが同じ場合、残時間と比較する
                        if left_time < duration then
                            registerTimer(next_am, present_tp, duration, icon)
                        end
                    elseif available_am < next_am then
                        -- 前回AMよりもLvが高い場合登録
                        registerTimer(next_am, present_tp, duration, icon)
                        deleteTimers(next_am - 1)
                    end
                end

            else
                -- AM効果がない場合登録
                registerTimer(next_am, present_tp, duration, icon)
            end

        elseif comm == 'delete' then
            -- aftermath delete
            deleteTimers(3)
            g_last_tp = 0
        end
    end
end)

function registerTimer(next_am, present_tp, duration, icon)
    windower.send_command('timers create AM' .. next_am .. ' ' .. duration .. ' down ' .. icon)
    g_last_limit = os.clock() + duration
    g_last_tp = present_tp
end

function deleteTimers(start_with)
    for i = start_with, 1 , -1 do
        windower.send_command('timers delete AM' .. i)
    end
end
