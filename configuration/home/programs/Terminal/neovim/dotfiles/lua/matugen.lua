 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#121316',
    base01 = '#1f2022',
    base02 = '#292a2c',
    base03 = '#8e9198',
    base04 = '#c4c6cf',
    base05 = '#e3e2e5',
    base06 = '#e3e2e5',
    base07 = '#e3e2e5',
    base08 = '#ffb4ab',
    base09 = '#e4b9e1',
    base0A = '#bfc7d8',
    base0B = '#b1c8ef',
    base0C = '#e4b9e1',
    base0D = '#b1c8ef',
    base0E = '#bfc7d8',
    base0F = '#dbe3f5',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#e3e2e5',          bg = '#121316' })
  hi('TelescopeBorder',         { fg = '#8e9198',             bg = '#121316' })
  hi('TelescopePromptNormal',   { fg = '#e3e2e5',          bg = '#121316' })
  hi('TelescopePromptBorder',   { fg = '#8e9198',             bg = '#121316' })
  hi('TelescopePromptPrefix',   { fg = '#b1c8ef',             bg = '#121316' })
  hi('TelescopePromptCounter',  { fg = '#c4c6cf',  bg = '#121316' })
  hi('TelescopePromptTitle',    { fg = '#121316',             bg = '#b1c8ef' })
  hi('TelescopePreviewTitle',   { fg = '#121316',             bg = '#bfc7d8' })
  hi('TelescopeResultsTitle',   { fg = '#121316',             bg = '#e4b9e1' })
  hi('TelescopeSelection',      { fg = '#e3e2e5',          bg = '#292a2c' })
  hi('TelescopeSelectionCaret', { fg = '#b1c8ef',             bg = '#292a2c' })
  hi('TelescopeMatching',       { fg = '#b1c8ef',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#e3e2e5',          bg = '#121316' })
  hi('MiniPickBorder',         { fg = '#8e9198',             bg = '#121316' })
  hi('MiniPickPrompt',   { fg = '#e3e2e5',          bg = '#121316' })
  hi('MiniPickPromptPrefix',   { fg = '#b1c8ef',             bg = '#121316' })
  hi('MiniPickBorderText',    { fg = '#121316',             bg = '#b1c8ef' })
  hi('MiniPickMatchCurrent',      { fg = '#e3e2e5',          bg = '#292a2c' })
  hi('MiniPickPromptCaret', { fg = '#b1c8ef',             bg = '#292a2c' })
  hi('MiniPickMatchRanges',       { fg = '#b1c8ef',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
