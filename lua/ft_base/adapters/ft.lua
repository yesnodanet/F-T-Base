FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local function identity(value)
    return value
end

local rules = {
    ["Priority"] = { ir = "developer.priority" },
    ["Merge"] = { ir = "developer.merge" },

    ["Meta.PrintName"] = { ir = "meta.printName" },
    ["Meta.Category"] = { ir = "meta.category" },
    ["Meta.Author"] = { ir = "meta.author" },
    ["Meta.Spawnable"] = { ir = "meta.spawnable" },

    ["Damage"] = { ir = "damage.base" },
    ["Damage.Base"] = { ir = "damage.base" },
    ["Damage.Minimum"] = { ir = "damage.minimum" },
    ["Damage.Curve"] = { ir = "damage.curve", transform = identity },
    ["Damage.Hitgroups"] = { ir = "damage.hitgroups", transform = identity },
    ["Damage.Armor"] = { ir = "damage.armor", transform = identity },

    ["Fire.RPM"] = { ir = "fire.rpm" },
    ["Fire.Delay"] = { ir = "fire.delay" },
    ["Fire.Automatic"] = { ir = "fire.automatic" },
    ["Fire.Burst"] = { ir = "fire.burst" },
    ["Fire.Modes"] = { ir = "fire.modes", transform = identity },

    ["Ammo.ClipSize"] = { ir = "ammo.clipSize" },
    ["Ammo.DefaultClip"] = { ir = "ammo.defaultClip" },
    ["Ammo.Type"] = { ir = "ammo.type" },

    ["Spread.Hip"] = { ir = "spread.hip" },
    ["Spread.ADS"] = { ir = "spread.ads" },
    ["Spread.Movement"] = { ir = "spread.movement" },
    ["Spread.PerShot"] = { ir = "spread.perShot" },

    ["Ballistics.Mode"] = { ir = "ballistics.mode" },
    ["Ballistics.Pellets"] = { ir = "ballistics.pellets" },
    ["Ballistics.MuzzleVelocity"] = { ir = "ballistics.muzzleVelocity" },
    ["Ballistics.TravelTime"] = { ir = "ballistics.travelTime" },
    ["Ballistics.Drag"] = { ir = "ballistics.drag" },
    ["Ballistics.Gravity"] = { ir = "ballistics.gravity" },
    ["Ballistics.Wind"] = { ir = "ballistics.wind", transform = identity },
    ["Ballistics.Penetration"] = { ir = "ballistics.penetration", transform = identity },
    ["Ballistics.Armor"] = { ir = "ballistics.armor", transform = identity },
    ["Ballistics.Ricochet"] = { ir = "ballistics.ricochet", transform = identity },
    ["Ballistics.Fragments"] = { ir = "ballistics.fragments", transform = identity },
    ["Ballistics.MaterialResponses"] = { ir = "ballistics.materialResponses", transform = identity },
    ["Ballistics.DamageCurve"] = { ir = "ballistics.damageCurve", transform = identity },

    ["Recoil.Mode"] = { ir = "recoil.mode" },
    ["Recoil.Scalar"] = { ir = "recoil.scalar" },
    ["Recoil.Pattern"] = { ir = "recoil.pattern", transform = identity },
    ["Recoil.Interpolation"] = { ir = "recoil.interpolation" },
    ["Recoil.Procedural"] = { ir = "recoil.procedural", transform = identity },
    ["Recoil.Procedural.Vertical"] = { ir = "recoil.procedural.vertical" },
    ["Recoil.Procedural.Horizontal"] = { ir = "recoil.procedural.horizontal" },
    ["Recoil.Procedural.Roll"] = { ir = "recoil.procedural.roll" },
    ["Recoil.Procedural.Randomness"] = { ir = "recoil.procedural.randomness" },
    ["Recoil.Procedural.Recovery"] = { ir = "recoil.procedural.recovery" },

    ["Camera.Shake"] = { ir = "camera.shake" },
    ["Camera.Sway"] = { ir = "camera.sway" },
    ["Camera.FreeAim"] = { ir = "camera.freeAim", transform = identity },
    ["Camera.FreeAim.Radius"] = { ir = "camera.freeAim.radius" },
    ["Camera.Spring"] = { ir = "camera.spring", transform = identity },
    ["Camera.Breathing"] = { ir = "camera.breathing" },
    ["Camera.Landing"] = { ir = "camera.landing" },
    ["Camera.Sprint"] = { ir = "camera.sprint", transform = identity },
    ["Camera.MicroJitter"] = { ir = "camera.microJitter" },
    ["Camera.Deadzone"] = { ir = "camera.deadzone" },
    ["Camera.AimTransition"] = { ir = "camera.aimTransition" },

    ["ADS.FOV"] = { ir = "ads.fov" },
    ["ADS.Pos"] = { ir = "ads.pos", transform = identity },
    ["ADS.Ang"] = { ir = "ads.ang", transform = identity },
    ["ADS.Speed"] = { ir = "ads.speed" },

    ["Animations"] = { ir = "animations", transform = identity },
    ["Animations.Base"] = { ir = "animations.base", transform = identity },
    ["Animations.Layers"] = { ir = "animations.layers", transform = identity },
    ["Animations.IK"] = { ir = "animations.ik", transform = identity },
    ["Animations.Events"] = { ir = "animations.events", transform = identity },
    ["Animations.ReloadStages"] = { ir = "animations.reloadStages", transform = identity },
    ["Animations.Inspect"] = { ir = "animations.inspect", transform = identity },

    ["Attachments"] = { ir = "attachments", transform = identity },
    ["Attachments.Slots"] = { ir = "attachments.slots", transform = identity },
    ["Attachments.Definitions"] = { ir = "attachments.definitions", transform = identity },
    ["Attachments.DynamicModifiers"] = { ir = "attachments.dynamicModifiers", transform = identity },

    ["Sounds"] = { ir = "sounds", transform = identity },
    ["Sounds.Fire"] = { ir = "sounds.fire", transform = identity },
    ["Sounds.Fire.Layers"] = { ir = "sounds.fire.layers", transform = identity },
    ["Sounds.Fire.IndoorTail"] = { ir = "sounds.fire.indoorTail" },
    ["Sounds.Fire.OutdoorTail"] = { ir = "sounds.fire.outdoorTail" },
    ["Sounds.Fire.Distant"] = { ir = "sounds.fire.distant" },
    ["Sounds.Fire.Suppressed"] = { ir = "sounds.fire.suppressed" },
    ["Sounds.Mechanical"] = { ir = "sounds.mechanical", transform = identity },
    ["Sounds.Reload"] = { ir = "sounds.reload", transform = identity },

    ["Effects.Muzzle"] = { ir = "effects.muzzle" },
    ["Effects.Shell"] = { ir = "effects.shell" },
    ["Effects.Impact"] = { ir = "effects.impact", transform = identity },
    ["Effects.Tracer"] = { ir = "effects.tracer" },

    ["Networking"] = { ir = "networking", transform = identity },
    ["Prediction"] = { ir = "prediction", transform = identity },
    ["Movement"] = { ir = "movement", transform = identity },
    ["Movement.Speed"] = { ir = "movement.speed" },
    ["Movement.SightedSpeed"] = { ir = "movement.sightedSpeed" },
    ["Movement.BlindFire"] = { ir = "movement.blindFire" },
    ["NPC"] = { ir = "npc", transform = identity },
    ["Vehicles"] = { ir = "vehicles", transform = identity },
    ["Physics"] = { ir = "physics", transform = identity },

    ["Rendering.ViewModel"] = { ir = "rendering.viewModel" },
    ["Rendering.WorldModel"] = { ir = "rendering.worldModel" },
    ["Rendering.HoldType"] = { ir = "rendering.holdType" },
    ["Rendering.UseHands"] = { ir = "rendering.useHands" },
    ["UI.DrawAmmo"] = { ir = "ui.drawAmmo" },
    ["UI.Crosshair"] = { ir = "ui.crosshair" }
}

FTBase.Adapters.FT = FTBase.Adapters.Make({
    Name = "FT",
    Aliases = {"F&T", "FTBase", "FamiliaTarka"},
    Rules = rules
})
