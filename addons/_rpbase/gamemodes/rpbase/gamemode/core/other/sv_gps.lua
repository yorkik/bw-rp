util.AddNetworkString('rp.GovernmentRequare_vec')
util.AddNetworkString('rp.GovernmentRequare')

net.Receive('rp.GovernmentRequare',function(len,ply)
	local rsn = net.ReadString()
	if rsn == '' then return end

	notif(ply, 'Вы вызвали полицию', 'ok')

	for k,v in pairs(player.GetAll()) do
		if not IsCop(v:GetPlayerClass()) or IsSWAT(v:GetPlayerClass()) then continue end
		net.Start('rp.GovernmentRequare')
		net.WriteEntity(ply)
		net.WriteString(rsn)
		net.Send(v)
	end
end)

function CP_Call(vec,str)
	for k,v in pairs(player.GetAll()) do
		if not IsCop(v:GetPlayerClass()) or IsSWAT(v:GetPlayerClass()) then continue end
		net.Start('rp.GovernmentRequare_vec')
		net.WriteVector(vec)
		net.WriteString(str)
		net.Send(v)
	end
end