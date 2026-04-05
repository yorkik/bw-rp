local notifycol = Color(0, 146 ,231)
local notify_types = {
	[0] = notifycol,
	[1] = notifycol,
}

net.Receive('ba.NotifyString', function(len)
	if (not IsValid(LocalPlayer())) then return end
	chat.AddText(notify_types[net.ReadBit()], '★ ', unpack(ba.ReadMsg()))
end)

net.Receive('ba.NotifyTerm', function(len)
	if (not IsValid(LocalPlayer())) then return end
	chat.AddText(notify_types[net.ReadBit()], '★ ', unpack(ba.ReadTerm()))
end)