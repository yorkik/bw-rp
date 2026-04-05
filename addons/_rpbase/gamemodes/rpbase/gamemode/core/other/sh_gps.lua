gpspos = {}
function AddGPSPos(pos,time,text,icon)
    local key = text
    gpspos[key] = {p = pos, i = icon}
    
     timer.Simple(time,function()
        if gpspos[key] ~= nil then
            gpspos[key] = nil
        end
    end)
end