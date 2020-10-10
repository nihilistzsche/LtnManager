return function(comp_name, sort_name, caption, tooltip, state, constants)
  return {
    type = "checkbox",
    style = state.selected_sort == sort_name and "ltnm_selected_sort_checkbox" or "ltnm_sort_checkbox",
    width = constants[sort_name],
    caption = {"ltnm-gui."..caption},
    tooltip = tooltip and {"ltnm-gui."..tooltip.."-tooltip"} or nil,
    state = state["sort_"..sort_name],
    on_click = {comp = comp_name, action = "update_sort", sort = sort_name},
  }
end