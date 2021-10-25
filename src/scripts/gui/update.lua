local trains_tab = require("trains")

--- Updates the GUI based on the current set of LTN data.
return function(self)
  local state = self.state

  -- TODO: Update surfaces dropdown

  if state.active_tab == "trains" then
    trains_tab.update(self)
  end
end

