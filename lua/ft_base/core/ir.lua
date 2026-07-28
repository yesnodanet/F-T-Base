FTBase = FTBase or {}

local IR = {}

function IR.New()
    return {
        version = 1,
        meta = {
            id = "",
            printName = "",
            category = "F&T Base",
            author = "",
            description = "",
            purpose = "",
            manufacturer = "",
            caliber = "",
            country = "",
            year = nil,
            credits = {},
            spawnable = false,
            sourceStyles = {}
        },
        developer = {
            priority = {},
            merge = {},
            plugins = {},
            notes = {}
        },
        damage = {
            base = 0,
            minimum = 0,
            curve = {},
            hitgroups = {},
            armor = {
                mode = "scale",
                scale = 1
            }
        },
        fire = {
            rpm = 600,
            delay = nil,
            automatic = false,
            burst = 0,
            ammoPerShot = 1,
            underwater = false,
            drySound = nil,
            modes = {
                { mode = "semi" }
            }
        },
        ammo = {
            clipSize = 30,
            defaultClip = 90,
            chamberSize = 1,
            type = "SMG1"
        },
        spread = {
            hip = 0,
            ads = 0,
            movement = 0,
            crouch = 0,
            jump = 0,
            perShot = 0,
            maximum = 0,
            recovery = 1,
            recoveryDelay = 0
        },
        ballistics = {
            mode = "hitscan",
            pellets = 1,
            muzzleVelocity = 0,
            travelTime = false,
            drag = 0,
            gravity = 0,
            wind = {0, 0, 0},
            penetration = {
                power = 0,
                materials = {}
            },
            armor = {
                enabled = false,
                scale = 1
            },
            ricochet = {
                enabled = false,
                chance = 0,
                angle = 0
            },
            fragments = {},
            materialResponses = {},
            damageCurve = {}
        },
        recoil = {
            mode = "pattern",
            scalar = 1,
            pattern = {},
            interpolation = "step",
            procedural = {
                vertical = 0,
                horizontal = 0,
                roll = 0,
                randomness = 0,
                recovery = 1
            },
            styles = {
                cs = {},
                valorant = {},
                rust = {},
                random = {},
                hybrid = {}
            }
        },
        camera = {
            shake = 0,
            sway = 0,
            freeAim = {
                enabled = false,
                radius = 0
            },
            spring = {
                stiffness = 180,
                damping = 22
            },
            breathing = 0,
            landing = 0,
            sprint = {
                bob = 0,
                pos = nil,
                ang = nil
            },
            microJitter = 0,
            deadzone = 0,
            aimTransition = 0.16,
            viewModelFOV = nil,
            viewModelFlip = false,
            poses = {
                active = {},
                crouch = {},
                sprint = {},
                holster = {},
                customize = {},
                inspect = {},
                nearWall = {},
                blindFire = {}
            }
        },
        ads = {
            fov = 70,
            pos = nil,
            ang = nil,
            speed = 1,
            sensitivity = 1,
            magnification = 1,
            scopes = {},
            reticle = nil,
            overlay = nil,
            hideWeapon = false
        },
        animations = {
            base = {},
            layers = {},
            ik = {},
            procedural = {},
            events = {},
            curves = {},
            reloadStages = {},
            reloadDuration = nil,
            inspect = nil,
            partialBody = {}
        },
        attachments = {
            slots = {},
            definitions = {},
            nested = true,
            inheritance = {},
            dynamicModifiers = {},
            customTypes = {},
            dependencies = {},
            exclusions = {},
            elements = {},
            icons = {},
            visuals = {}
        },
        sounds = {
            fire = {
                layers = {},
                indoorTail = nil,
                outdoorTail = nil,
                distant = nil,
                suppressed = nil
            },
            mechanical = {},
            reload = {},
            occlusion = {
                enabled = true,
                scale = 1
            },
            suppression = {
                enabled = true,
                sound = nil
            }
        },
        effects = {
            muzzle = nil,
            shell = nil,
            impact = {},
            tracer = nil,
            smoke = nil
        },
        melee = {
            enabled = false,
            damage = 0,
            damageType = nil,
            range = 0,
            delay = 0,
            secondary = {}
        },
        networking = {
            variables = {},
            events = {},
            compression = "delta"
        },
        prediction = {
            seedMode = "command",
            rollback = true,
            shotId = 0
        },
        movement = {
            speed = 1,
            sightedSpeed = 1,
            reloadSpeed = 1,
            sprintToFire = 0,
            aimWalk = 1,
            blindFire = false
        },
        npc = {
            enabled = true,
            burst = { minimum = 1, maximum = 3 },
            rest = { minimum = 0.2, maximum = 0.5 },
            proficiency = 1
        },
        vehicles = {
            enabled = true,
            constraints = {}
        },
        physics = {
            projectile = {},
            springs = {}
        },
        rendering = {
            viewModel = nil,
            worldModel = nil,
            holdType = "ar2",
            useHands = true,
            viewModelFOV = nil,
            viewModelFlip = false,
            bodygroups = {},
            skins = {},
            materials = {},
            elements = {},
            modelOffsets = {},
            muzzleAttachment = nil,
            shellAttachment = nil
        },
        ui = {
            drawAmmo = true,
            crosshair = true,
            inspect = {
                enabled = true,
                command = "ft_customize",
                pos = nil,
                ang = nil,
                animation = nil,
                stats = {}
            },
            customization = {
                provider = "ft",
                source = nil,
                openCommand = "ft_customize"
            },
            visual = {
                providers = {
                    inspect = "ft",
                    attachments = "ft",
                    hud = "ft",
                    presentation = "ft"
                },
                sources = {},
                hud = {},
                customization = {},
                presentation = {}
            }
        },
        runtime = {
            compiledAt = 0,
            optimized = false,
            fingerprints = {}
        }
    }
end

function IR.Clone(ir)
    return FTBase.Util.Table.DeepCopy(ir or IR.New())
end

FTBase.IR = IR
