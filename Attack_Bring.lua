hookfunction(require(game:GetService("ReplicatedStorage").Effect.Container.Death), function() end)
hookfunction(require(game:GetService("ReplicatedStorage").Effect.Container.Respawn), function() end)
hookfunction(require(game:GetService("ReplicatedStorage"):WaitForChild("GuideModule")).ChangeDisplayedNPC, function() end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
local GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")
local Config = {
    AttackDistance = 60,
    AttackMobs = true,
    AttackPlayers = true,
    AttackCooldown = 0.2,
    ComboResetTime = 0.3,
    MaxCombo = 4,
    HitboxLimbs = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"},
    AutoClickEnabled = true
}
local FastAttack = {}
FastAttack.__index = FastAttack
function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        EnemyRootPart = nil,
        Connections = {},
        Overheat = { Dragonstorm = { MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 350, Shooting = false }},
        ShootsPerTarget= { ["Dual Flintlock"] = 2 },
        SpecialShoots  = { ["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat" }
    }, FastAttack)
    pcall(function()
        self.CombatFlags  = require(Modules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction= getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)
    return self
end
function FastAttack:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end
function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end
function FastAttack:GetBladeHits(Character, Distance)
    local Position  = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or Config.AttackDistance
    local function ProcessTargets(Folder)
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local BasePart = Enemy:FindFirstChild(Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]) or Enemy:FindFirstChild("HumanoidRootPart")
                if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                    if not self.EnemyRootPart then
                        self.EnemyRootPart = BasePart
                    else
                        table.insert(BladeHits, {Enemy, BasePart})
                    end
                end
            end
        end
    end
    if Config.AttackMobs then ProcessTargets(Workspace.Enemies) end
    if Config.AttackPlayers then ProcessTargets(Workspace.Characters) end
    return BladeHits
end
function FastAttack:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDis = nil, math.huge
    for _, Hit in ipairs(BladeHits) do
        local Mag = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Mag < MinDis then
            MinDis = Mag
            Closest = Hit[2]
        end
    end
    return Closest
end
function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end
function FastAttack:ShootInTarget(TargetPosition)
    local Character = Player.Character
    if not self:IsEntityAlive(Character) then return end
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        GunValidator:FireServer(self:GetValidator2())
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end
function FastAttack:GetValidator2()
    local v1 = getupvalue(self.ShootFunction, 15)
    local v2 = getupvalue(self.ShootFunction, 13)
    local v3 = getupvalue(self.ShootFunction, 16)
    local v4 = getupvalue(self.ShootFunction, 17)
    local v5 = getupvalue(self.ShootFunction, 14)
    local v6 = getupvalue(self.ShootFunction, 12)
    local v7 = getupvalue(self.ShootFunction, 18)
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    return math.floor(v9 / v4 * 16777215), v7
end
function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    if self.EnemyRootPart then
        RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end
function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local Targets = self:GetBladeHits(Character)
    if not Targets[1] then return end
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end
function FastAttack:Attack()
    if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
    local Character = Player.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    local Humanoid = Character.Humanoid
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee","Blox Fruit","Sword","Gun"}, ToolTip) then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then self:ShootInTarget(Target.Position) end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end
local AttackInstance = FastAttack.new()
table.insert(AttackInstance.Connections, RunService.Stepped:Connect(function()
    AttackInstance:Attack()
end))
for _, v in pairs(getgc(true)) do
    if typeof(v) == "function" and iscclosure(v) then
        local name = debug.getinfo(v).name
        if name == "Attack" or name == "attack" or name == "RegisterHit" then
            hookfunction(v, function(...)
                AttackInstance:Attack()
                return v(...)
            end)
        end
    end
end
local Register_Hit = Net:WaitForChild("RE/RegisterHit")
local Register_Attack = Net:WaitForChild("RE/RegisterAttack")
local Funcs = {}
function GetAllBladeHits()
    local bladehits = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        if hum and v:FindFirstChild("HumanoidRootPart") and hum.Health > 0
           and (v.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end
function Getplayerhit()
    local bladehits = {}
    for _, v in pairs(workspace.Characters:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        if v.Name ~= Player.Name and hum and v:FindFirstChild("HumanoidRootPart") and hum.Health > 0
           and (v.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end
function Funcs:Attack()
    local bladehits = {}
    for _, v in pairs(GetAllBladeHits()) do table.insert(bladehits, v) end
    for _, v in pairs(Getplayerhit())   do table.insert(bladehits, v) end
    if #bladehits == 0 then return end
    local args = { [1] = nil, [2] = {}, [4] = "078da341" }
    for r, v in pairs(bladehits) do
        Register_Attack:FireServer(0)
        if not args[1] then args[1] = v.Head end
        args[2][r] = { [1] = v, [2] = v.HumanoidRootPart }
    end
    Register_Hit:FireServer(unpack(args))
end
local plr = Players.LocalPlayer
TweenObject = function(Object, Pos, Speed)
    Speed = Speed or 350
    local Distance = (Pos.Position - Object.Position).Magnitude
    local tweenService = game:GetService("TweenService")
    local info = TweenInfo.new(Distance/Speed, Enum.EasingStyle.Linear)
    local tween1 = tweenService:Create(Object, info, {CFrame = Pos})
    tween1:Play()
end
GetMobPosition = function(EnemiesName)
    local pos, count = nil, 0
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == EnemiesName then
            if not pos then pos = v.HumanoidRootPart.Position else pos = pos + v.HumanoidRootPart.Position end
            count = count + 1
        end
    end
    pos = pos / count
    return pos
end
BringMob = function(Value)
    if not Value then return end
    local ememe = game.Workspace.Enemies:GetChildren()
    if #ememe == 0 then return end
    local totalpos = {}
    for _, v in pairs(ememe) do
        if not totalpos[v.Name] then
            totalpos[v.Name] = GetMobPosition(v.Name)
        end
    end
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            if (v.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 350 then
                for k, f in pairs(totalpos) do
                    if k and v.Name == k and f then
                        local Gay = CFrame.new(f.X, f.Y, f.Z)
                        local Cac = (v.HumanoidRootPart.Position - Gay.Position).Magnitude
                        if Cac > 3 and Cac <= 280 then
                            TweenObject(v.HumanoidRootPart, Gay, 300)
                            v.HumanoidRootPart.CanCollide = false
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            v.Humanoid:ChangeState(14)
                            sethiddenproperty(plr, "SimulationRadius", math.huge)
                        end
                    end
                end
            end
        end
    end
end
