-- GUI component obj will call `create()` or return its static template when invoked
return function()
  local obj = {}
  setmetatable(obj, {__call = function(self, ...)
    if self.create then
      return self.create(...)
    else
      return self.template
    end
  end})
  return obj
end