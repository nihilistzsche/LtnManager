-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL STAGE UTILITIES

local util = require('__core__.lualib.util')

-- adds the contents of two material tables together
-- t1 contains the items we are adding into the table, t2 will be returned
function util.add_materials(t1, t2)
  for name,count in pairs(t1) do
    local existing = t2[name]
    if existing then
      t2[name] = existing + count
    else
      t2[name] = count
    end
  end
  return t2
end

-- add commas to separate thousands
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
function util.comma_value(input)
  local formatted = input
  while true do
    formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

-- convert a number of ticks into runtime
-- this assumes only minutes and seconds, hours are unneeded for our usecase
function util.ticks_to_time(ticks)
  local seconds = math.floor(ticks / 60)
  return math.floor(seconds / 60)..':'..string.format('%02.f', math.floor(seconds % 60))
end

util.train = require('__OpteraLib__/script/train')

-- for OCD's sake
util.train.get_composition_string = util.train.get_train_composition_string

-- create a string naming the status of the train
-- first return is the string used for sorting, second return is the formatted string data for display
function util.train.get_status_string(train_data, translations)
  local state = train_data.train.state
  local def = defines.train_state
  if state == def.on_the_path or state == def.arrive_signal or state == def.wait_signal or state == def.arrive_station then
    if train_data.returning_to_depot then
      return translations['returning-to-depot'], {{'bold_label', translations['returning-to-depot']}}
    else
      return
        translations[train_data.pickupDone and 'delivering-to' or 'fetching-from']..':^^'..train_data.to,
        {{'label', translations[train_data.pickupDone and 'delivering-to' or 'fetching-from']..':'}, {'bold_label', train_data.to}}
    end
  elseif state == def.wait_station then
    if train_data.surface or train_data.returning_to_depot then
      return translations['parked-at-depot'], {{'bold_green_label', translations['parked-at-depot']}}
    else
      return
        translations[train_data.pickupDone and 'unloading-at' or 'loading-at']..':^^'..(train_data.from or train_data.to),
        {{'label', translations[train_data.pickupDone and 'unloading-at' or 'loading-at']..':'}, {'bold_label', train_data.from or train_data.to}}
    end
  else
    return 'N/A', {{'bold_red_label', 'N/A'}}
  end
end

return util