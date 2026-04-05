if CLIENT then

	local function OpenCreateOrgMenu()
		Derma_StringRequest(
			"Создать организацию",
			"Введите название вашей организации:",
			"",
			function(text)
				local org_name = text
				if not org_name or string.Trim(org_name) == "" then
					LocalPlayer():ChatPrint("Название организации не может быть пустым!")
					return
				end

				net.Start("RequestCreateOrg")
					net.WriteString(org_name)
				net.SendToServer()
			end,
			function()
			end,
			"Подтвердить",
			"Отмена"
		)
	end

	net.Receive("RequestCreateOrg", function(len)
		local org_name = net.ReadString()
		local can_afford = net.ReadBool()
		local current_money = net.ReadInt(32)

		if not can_afford then
			Derma_Message("У вас недостаточно денег для создания организации. Требуется $2500.\nВаш баланс: $" .. current_money, "Ошибка", "OK")
			return
		end

		Derma_Query(
			"Вы хотите создать организацию '" .. org_name .. "'?\nСтоимость: " .. FormatMoney(cfg.orgcost),
			"Подтверждение создания",
			"Да",
			function()
				net.Start("ConfirmCreateOrg")
					net.WriteString(org_name)
				net.SendToServer()
				timer.Simple(.5, function()
					RunConsoleCommand('org_menu')
				end)
			end,
			"Нет",
			function()
			end
		)
	end)

	local function OpenOrgManagementMenu()
		local frame = vgui.Create("DFrame")
		frame:SetSize(ScrW() * 0.3, ScrH() * 0.5)
		frame:Center()
		frame:SetTitle("Управление организацией")
		frame:SetVisible(true)
		frame:MakePopup()

		local org_name = LocalPlayer():GetOrg()
		if not org_name then
			frame:SetTitle("Управление организацией - Не состоите в организации")
			local label = vgui.Create("DLabel", frame)
			label:SetText("Вы не состоите ни в одной организации.")
			label:SizeToContents()
			label:Center()
			return
		end

		frame:SetTitle("Организация: " .. org_name)

		local org_data = LocalPlayer():GetOrgData()
		local is_owner = org_data.Perms.Owner
		local can_invite = org_data.Perms.Invite
		local can_kick = org_data.Perms.Kick
		local can_rank = org_data.Perms.Rank
		local can_motd = org_data.Perms.MoTD
		local can_change_color = org_data.Perms.ChangeColor

		local sheet = vgui.Create("DPropertySheet", frame)
		sheet:Dock(FILL)

		local info_panel = vgui.Create("DPanel")
		info_panel:SetPaintBackground(false)
		sheet:AddSheet("Информация", info_panel, "icon16/information.png")

		local info_text = vgui.Create("DLabel", info_panel)
		info_text:Dock(TOP)
		info_text:SetText("Название: " .. org_name)
		info_text:SetContentAlignment(7)
		info_text:SetAutoStretchVertical(true)

		local motd_label = vgui.Create("DLabel", info_panel)
		motd_label:Dock(TOP)
		motd_label:SetText("Описание: " .. (org_data.MoTD or "Добро пожаловать в " .. org_name .. "!"))
		motd_label:SetContentAlignment(7)
		motd_label:SetAutoStretchVertical(true)

		local motd_label_ref = motd_label

		if can_motd then
			local edit_motd_btn = vgui.Create("DButton", info_panel)
			edit_motd_btn:Dock(TOP)
			edit_motd_btn:SetText("Изменить описание")
			edit_motd_btn:SetTall(30)
			edit_motd_btn:DockMargin(0, 10, 0, 0)
			edit_motd_btn.DoClick = function()
				Derma_StringRequest(
					"Изменить описание организации",
					"Введите новое описание:",
					org_data.MoTD or "",
					function(new_motd)
						net.Start("UpdateOrgMotD")
							net.WriteString(new_motd)
						net.SendToServer()

						motd_label_ref:SetText("Описание: " .. new_motd)
						motd_label_ref:SizeToContents()
					end
				)
			end
		end

		if can_change_color then
			local change_color_btn = vgui.Create("DButton", info_panel)
			change_color_btn:Dock(TOP)
			change_color_btn:SetText("Изменить цвет организации")
			change_color_btn:SetTall(30)
			change_color_btn:DockMargin(0, 10, 0, 0)
			change_color_btn.DoClick = function()
				local color_picker = vgui.Create("DFrame")
				color_picker:SetSize(300, 300)
				color_picker:Center()
				color_picker:SetTitle("Выберите цвет организации")
				color_picker:SetVisible(true)
				color_picker:MakePopup()

				local color_mixer = vgui.Create("DColorMixer", color_picker)
				color_mixer:Dock(FILL)
				color_mixer:SetColor(LocalPlayer():GetOrgColor())

				local confirm_color_btn = vgui.Create("DButton", color_picker)
				confirm_color_btn:SetText("Применить цвет")
				confirm_color_btn:Dock(BOTTOM)
				confirm_color_btn.DoClick = function()
					local selected_color = color_mixer:GetColor()
					net.Start("UpdateOrgColor")
						net.WriteUInt(selected_color.r, 8)
						net.WriteUInt(selected_color.g, 8)
						net.WriteUInt(selected_color.b, 8)
					net.SendToServer()
					color_picker:Close()
				end
			end
		end

		local members_panel = vgui.Create("DPanel")
		members_panel:SetPaintBackground(false)
		sheet:AddSheet("Участники", members_panel, "icon16/group.png")

		local list_view = vgui.Create("DListView", members_panel)
		list_view:Dock(FILL)
		list_view:SetMultiSelect(false)
		list_view:AddColumn("Имя")
		list_view:AddColumn("Роль")

		local function PopulateList()
			if not IsValid(list_view) then return end
			net.Start("RequestOrgMembers")
			net.SendToServer()
		end

		net.Receive("SendOrgMembers", function()
			if not IsValid(list_view) then return end

			list_view:Clear()

			local num = net.ReadUInt(8)
			for i = 1, num do
				local name = net.ReadString()
				local rank = net.ReadString()
				local line = list_view:AddLine(name, rank)
				if line then
					line.player_name = name
				end
			end
		end)

		local controls_panel = vgui.Create("DPanel", members_panel)
		controls_panel:Dock(BOTTOM)
		controls_panel:SetTall(40)
		controls_panel:SetPaintBackground(false)

		if is_owner then
			local disband_btn = vgui.Create("DButton", controls_panel)
			disband_btn:SetText("Распустить")
			disband_btn:SetSize(100, 30)
			disband_btn:SetPos(210, 5)
			disband_btn.DoClick = function()
				Derma_Query(
					"Вы уверены, что хотите распустить организацию?\nЭто действие нельзя отменить.",
					"Подтверждение",
					"Да",
					function()
						net.Start("DisbandOrg")
						net.SendToServer()
						frame:Close()
					end,
					"Нет",
					function() end
				)
			end
		end

		local invite_btn = vgui.Create("DButton", controls_panel)
		invite_btn:SetText("Пригласить")
		invite_btn:SetSize(100, 30)
		invite_btn:SetPos(10, 5)
		invite_btn:SetEnabled(can_invite)
		invite_btn.DoClick = function()
			local players = player.GetAll()
			local menu = DermaMenu()
			for _, pl in ipairs(players) do
				if pl ~= LocalPlayer() and not pl:GetOrg() then
					menu:AddOption(pl:Name(), function()
						net.Start("InviteToOrg")
							net.WriteString(pl:SteamID())
						net.SendToServer()
						PopulateList()
					end)
				end
			end
			menu:Open()
		end

		local kick_btn = vgui.Create("DButton", controls_panel)
		kick_btn:SetText("Выгнать")
		kick_btn:SetSize(80, 30)
		kick_btn:SetPos(120, 5)
		kick_btn:SetEnabled(can_kick)
		kick_btn.DoClick = function()
			local selected_line = list_view:GetSelectedLine()
			if not selected_line then
				LocalPlayer():ChatPrint("Выберите участника для исключения.")
				return
			end
			local selected_name = list_view:GetLine(selected_line).player_name
			local target_pl = DarkRP.FindPlayer(selected_name)
			if not target_pl or not target_pl:GetOrg() or target_pl:GetOrg() ~= org_name then
				LocalPlayer():ChatPrint("Игрок не найден или не состоит в вашей организации.")
				return
			end
			if target_pl:SteamID() == LocalPlayer():SteamID() then
				LocalPlayer():ChatPrint("Нельзя исключить самого себя.")
				return
			end
			net.Start("KickFromOrg")
				net.WriteString(target_pl:SteamID())
			net.SendToServer()
			PopulateList()
		end

		timer.Simple(0.1, function()
			if IsValid(frame) and IsValid(list_view) then
				PopulateList()
			end
		end)

		net.Receive("SendUpdatedMotD", function()
			local received_org_name = net.ReadString()
			local new_motd = net.ReadString()

			if received_org_name == org_name then
				motd_label_ref:SetText("Описание: " .. new_motd)
				motd_label_ref:SizeToContents()
			end
		end)

		net.Receive("SendUpdatedColor", function()
			local received_org_name = net.ReadString()
			local new_color = net.ReadColor()

			if received_org_name == org_name then
				--LocalPlayer():SetNetVar('OrgColor', new_color)
			end
		end)

	end

	concommand.Add("create_org", OpenCreateOrgMenu)
	concommand.Add("org_menu", OpenOrgManagementMenu)
end