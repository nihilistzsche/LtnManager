local util = {}

-- adds the contents of two material tables together
-- t1 contains the items we are adding into the table, t2 will be returned
function util.add_materials(t1, t2)
  for name, count in pairs(t1) do
    local existing = t2[name]
    if existing then
      t2[name] = existing + count
    else
      t2[name] = count
    end
  end
  return t2
end

-- TODO add to flib?

-- add commas to separate thousands
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
function util.comma_value(input)
  input = math.floor(input)
  local formatted = input
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then
      break
    end
  end
  return formatted
end

-- TODO use flib version

-- convert a number of ticks into runtime
-- always shows minutes and seconds, hours is optional
function util.ticks_to_time(ticks)
  local seconds = math.floor(ticks / 60)
  local hours = string.format("%02.f", math.floor(seconds/3600));
  if tonumber(hours) > 0 then
    local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  else
    local mins = math.floor(seconds/60);
    local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return mins..":"..secs
  end
end

-- TODO move to depots file

util.train = require("__flib__.train")

-- create a string naming the status of the train
-- first return is the string used for sorting, second return is the formatted string data for display
function util.train.get_status_string(train_data, translations)
  local state = train_data.state
  local def = defines.train_state
  if
    state == def.on_the_path
    or state == def.arrive_signal
    or state == def.wait_signal
    or state == def.arrive_station
  then
    if train_data.returning_to_depot then
      return {
        string = translations["returning-to-depot"],
        data = {{"bold_label", translations["returning-to-depot"]}}
      }
    else
      if train_data.pickupDone then
        return {
          string = translations["delivering-to"]..": "..train_data.to,
          data = {{"label", translations["delivering-to"]..":"}, {"bold_label", train_data.to}}
        }
      else
        if not train_data.from then
          return {
            string = "N/A",
            data = {{"bold_red_label", "N/A"}}
          }
        else
          return {
            string = translations["fetching-from"]..": "..train_data.from,
            data = {{"label", translations["fetching-from"]..":"}, {"bold_label", train_data.from}}
          }
        end
      end
    end
  elseif state == def.wait_station then
    if train_data.surface or train_data.returning_to_depot then
      return {
        string = translations["parked-at-depot"],
        data = {{"bold_green_label", translations["parked-at-depot"]}}
      }
    else
      if train_data.pickupDone then
        return {
          string = translations["unloading-at"]..": "..train_data.to,
          data = {{"label", translations["unloading-at"]..":"}, {"bold_label", train_data.to}}
        }
      else
        return {
          string = translations["loading-at"]..": "..train_data.from,
          data = {{"label", translations["loading-at"]..":"}, {"bold_label", train_data.from}}
        }
      end
    end
  else
    return {
      string = "N/A",
      data = {{"bold_red_label", "N/A"}}
    }
  end
end

return util