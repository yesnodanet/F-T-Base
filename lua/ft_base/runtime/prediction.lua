FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Prediction = FTBase.Module.Define("Prediction", {})

function Prediction.NextShotId(runtime)
    runtime.prediction = runtime.prediction or {
        shotId = 0
    }

    runtime.prediction.shotId = runtime.prediction.shotId + 1
    return runtime.prediction.shotId
end

function Prediction.ShouldRun()
    if IsFirstTimePredicted then
        return IsFirstTimePredicted()
    end

    return true
end

function Prediction.Seed(owner, shotId)
    if util and util.SharedRandom then
        return util.SharedRandom("ft_shot_" .. tostring(shotId), 0, 1, shotId)
    end

    return math.random()
end

FTBase.Runtime.Prediction = Prediction
