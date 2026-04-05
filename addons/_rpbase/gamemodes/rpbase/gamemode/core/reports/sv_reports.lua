util.AddNetworkString("reports.send")
util.AddNetworkString("reports.accept")
util.AddNetworkString("reports.close")
util.AddNetworkString("reports.message")

reports = reports or {}
reports.active = reports.active or {}
reports.roomUsed = reports.roomUsed or {}

function table.Filter(t, fn)
    local out = {}
    for k, v in ipairs(t) do
        if fn(v, k) then
            table.insert(out, v)
        end
    end
    return out
end

function reports.CloseReport(ply)
	if not reports.active[ply] then return end

	local data = reports.active[ply]
	local admin = data.admin

	if admin and IsValid(admin) then
		admin:SetNWBool("report_claimed", false)
		admin.lastReport = CurTime()
		admin.reportTarget = nil
	end


	net.Start("reports.close")
	if admin and IsValid(admin) then
		net.Send({ply, admin})
	else
		net.Send(ply)
	end

	reports.active[ply] = nil
end

hook.Add("PlayerSay", "reports.send", function(ply, text)
	local lowerText = string.lower(text)
	local command = 'rep'
	if string.sub(text, 1, 2) == "@ " or string.StartWith(lowerText, "!" .. command .. " ") or string.StartWith(lowerText, "/" .. command .. " ") then
		local admins = table.Filter(player.GetAll(), function(p) return p:IsAdmin() end)

		text = string.sub(text, 3)
		if reports.active[ply] then
			ply:ChatPrint("У вас уже есть активная жалоба!")
			return ""
		end

		reports.active[ply] = {
			reporter = ply,
			report_chat = {{ply, text}},
			start = CurTime()
		}

		net.Start("reports.send")
		net.WriteTable(reports.active[ply])
		net.Send(table.Add({ply}, admins))

		return ""
	end
end)

net.Receive("reports.accept", function(_, ply)
	if not ply:IsAdmin() then return end
	local target = net.ReadEntity()
	if not IsValid(target) or not reports.active[target] or reports.active[target].admin then return end
	if ply.reportTarget then return end

	reports.active[target].admin = ply
	ply.reportTarget = target
	ply:SetNWBool("report_claimed", true)
	ply.lastReport = CurTime()

	local recips = {target, ply}
	for _, p in ipairs(player.GetAll()) do
		if p:IsAdmin() and p ~= ply then table.insert(recips, p) end
	end

	net.Start("reports.accept")
	net.WriteEntity(target)
	net.WriteEntity(ply)
	net.WriteTable(reports.active[target])
	net.Send(recips)
end)

net.Receive("reports.close", function(_, ply)
	if ply.reportTarget and reports.active[ply.reportTarget] and reports.active[ply.reportTarget].admin == ply then
		reports.CloseReport(ply.reportTarget)
		return
	end

	if reports.active[ply] then
		reports.CloseReport(ply)
		net.Start("reports.accept")
		net.WriteEntity(ply)
		net.Send(table.Filter(player.GetAll(), function(ply) return ply:IsAdmin() end))
	end
end)

hook.Add("PlayerDisconnected", "reports.cleanup", function(ply)
	if reports.active[ply] then
		reports.CloseReport(ply)
	end
	if ply.reportTarget and reports.active[ply.reportTarget] then
		reports.CloseReport(ply.reportTarget)
	end
end)

net.Receive("reports.message", function(_, ply)
	if reports.active[ply] then
		local msg = net.ReadString()
		table.insert(reports.active[ply].report_chat, {ply, msg})

		local recips = {ply}
		local admin = reports.active[ply].admin
		if admin then table.insert(recips, admin) end

		net.Start("reports.message")
		net.WriteTable({ply, msg})
		net.Send(recips)
		return
	end

	if ply.reportTarget and reports.active[ply.reportTarget] then
		local msg = net.ReadString()
		table.insert(reports.active[ply.reportTarget].report_chat, {ply, msg})

		net.Start("reports.message")
		net.WriteTable({ply, msg})
		net.Send({ply, ply.reportTarget})
		return
	end
end)