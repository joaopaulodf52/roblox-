local MapUtils = {}

function MapUtils.getDefaultMapId(MapConfig)
    if type(MapConfig) ~= "table" then
        error("MapUtils.getDefaultMapId requer uma tabela MapConfig válida")
    end

    local candidate = MapConfig.defaultMap
    if typeof(candidate) == "string" and MapConfig[candidate] then
        return candidate
    end

    for key, value in pairs(MapConfig) do
        if type(value) == "table" and value.assetName then
            return key
        end
    end

    return nil
end

return MapUtils
