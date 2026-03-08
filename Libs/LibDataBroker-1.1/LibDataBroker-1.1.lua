-- LibDataBroker-1.1 - Data broker library for addon communication
-- Standard library for minimap button and data display addons

local MAJOR, MINOR = "LibDataBroker-1.1", 4
local LDB, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not LDB then return end

LDB.callbacks = LDB.callbacks or LibStub("CallbackHandler-1.0"):New(LDB)
LDB.attributestorage = LDB.attributestorage or {}
LDB.namestorage = LDB.namestorage or {}
LDB.proxystorage = LDB.proxystorage or {}

local attributestorage = LDB.attributestorage
local namestorage = LDB.namestorage
local proxystorage = LDB.proxystorage
local callbacks = LDB.callbacks

function LDB:NewDataObject(name, dataobj)
    if proxystorage[name] then return nil end

    if dataobj then
        assert(type(dataobj) == "table", "Invalid dataobj")
    end

    local storage = {}
    if dataobj then
        for k, v in pairs(dataobj) do
            storage[k] = v
        end
    end

    attributestorage[name] = storage
    namestorage[name] = name

    local proxy = setmetatable({}, {
        __index = function(self, key)
            return storage[key]
        end,
        __newindex = function(self, key, value)
            storage[key] = value
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, storage)
            callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, storage)
        end,
    })

    proxystorage[name] = proxy
    callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxy)
    return proxy
end

function LDB:GetDataObjectByName(name)
    return proxystorage[name]
end

function LDB:GetNameByDataObject(dataobj)
    for name, proxy in pairs(proxystorage) do
        if proxy == dataobj then return name end
    end
end

function LDB:DataObjectIterator()
    return pairs(proxystorage)
end
