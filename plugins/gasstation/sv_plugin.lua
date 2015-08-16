local PLUGIN = PLUGIN

function PLUGIN:UseGasPump( ply, entity )
	ply.gasUse = ply.gasUse or CurTime() - 1
	if ply.gasUse < CurTime() then
		ply.gasUse = CurTime() + 3
		if entity:GetModel() == "models/props_equipment/gas_pump.mdl" then
			local distance = 200
			local found
			for _, ent in pairs(ents.FindInSphere(ply:GetPos(), 200)) do
				if ent:GetClass() == "prop_vehicle_jeep" then
					local dist = ply:GetPos():Distance(ent:GetPos())
					if dist < distance then
						distance = dist
						found = ent
					end
				end
			end
			if IsValid(found) then
				found.fuel = found.fuel or 0
				local fuel = math.floor(found.fuel)
				if fuel >= 100 then
					ply:notify("Fueltank already full.")
					return false
				elseif timer.Exists("GAS_PUMP_"..found:EntIndex()) then
					ply:notify("This vehicle is already being refueled.")
					return false
				end
				found.gasPos = found:GetPos()
				ply:notify("Vehicle refueling in progress, please do not move your vehicle.")
				local gasSound = CreateSound(  entity, "ambient/machines/pump_loop_1.wav")
				gasSound:Play()
				gasSound:ChangeVolume(0.5, 0)
				local ticks = 0
				timer.Create("GAS_PUMP_"..found:EntIndex(), 0.5, 100, function()
					if not IsValid(found) then return end
					if found:GetPos():Distance(found.gasPos) > 30 then
						ply:notify("You moved your vehicle, refueling stopped.")
						gasSound:Stop()
						timer.Destroy("GAS_PUMP_"..found:EntIndex())
						return
					elseif not ply:HasMoney(self.price) then
						ply:notify("You do not have anymore money to spend.")
						gasSound:Stop()
						timer.Destroy("GAS_PUMP_"..found:EntIndex())
						return
					else
						ply:takeMoney(self.price)
						found.fuel = math.Clamp(found.fuel + 1, 0, 100)
						ticks = ticks + 1
						if found.fuel >= 100 then
							ply:notify("Your vehicle has been refueled for "..self.price * ticks.."€.")
							gasSound:Stop()
							timer.Destroy("GAS_PUMP_"..found:EntIndex())
						end
					end
				end)
			else
				ply:notify("No vehicle in range.")
			end
		end
	end
end

function PLUGIN:KeyPress( ply, key )
	if key == IN_USE then
		local data = {}
		data.start = ply:GetShootPos()
		data.endpos = data.start + ply:GetAimVector() * 84
		data.filter = ply
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if IsValid(entity) then
			self:UseGasPump(ply, entity)
		end
	end
end