local trains_tab = require("trains")
local stations_tab = require("stations")

--- Updates the GUI based on the current set of LTN data.
return function(self)
  local state = self.state

  -- TODO: Update surfaces dropdown

  if state.active_tab == "trains" then
    trains_tab.update(self)
  elseif state.active_tab == "stations" then
    stations_tab.update(self)
  end
end

