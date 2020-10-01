-- GUI component obj will call `build()` or return its static template when invoked
return function()
  local obj = {}
  setmetatable(obj, {__call = function(self, ...)
    if self.build then
      return self.build(...)
    else
      return self.template
    end
  end})
  return obj
end