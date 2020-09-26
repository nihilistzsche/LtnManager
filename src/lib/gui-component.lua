-- GUI component obj will return its base_template when directly invoked
return function()
  local obj = {}
  setmetatable(obj, {__call = function() return obj.base_template end})
  return obj
end