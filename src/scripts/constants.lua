-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONSTANTS

return {
  -- colors
  default_font_color = {1, 1, 1},
  default_dark_font_color = {},
  bold_dark_font_color = {28, 28, 28},
  heading_font_color = {255, 230, 192},
  -- signals
  ltn_signals = {
    ['ltn-depot'] = true,
    ['ltn-network-id'] = true,
    ['ltn-min-train-length'] = true,
    ['ltn-max-train-length'] = true,
    ['ltn-max-trains'] = true,
    ['ltn-provider-threshold'] = true,
    ['ltn-provier-stack-threshold'] = true,
    ['ltn-provider-priority'] = true,
    ['ltn-locked-slots'] = true,
    ['ltn-requester-threshold'] = true,
    ['ltn-requester-stack-threshold'] = true,
    ['ltn-requester-priority'] = true
  }
}