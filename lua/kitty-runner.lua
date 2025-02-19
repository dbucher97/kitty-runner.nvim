--
-- KITTY RUNNER
--


local fn = vim.fn
local cmd = vim.cmd
local loop = vim.loop
local nvim_set_keymap = vim.api.nvim_set_keymap

local M = {}

local whole_command

local function open_new_runner()
  loop.spawn('kitty', {
      args = {'@', 'launch', '--title=' .. Cfg.runner_name}
    })
  Cfg.runner_is_open = true
end

local function send_kitty_command(cmd_args, command)
  local args = {'@'}
  for _, v in pairs(cmd_args) do
    table.insert(args, v)
  end
  table.insert(args, command)
  loop.spawn('kitty', {
    args = args
  })
end

local function prepare_command(region)
  local lines
  if region[1] == 0 then
    lines = vim.api.nvim_buf_get_lines(0, vim.api.nvim_win_get_cursor(0)[1]-1, vim.api.nvim_win_get_cursor(0)[1], true)
  else
    lines = vim.api.nvim_buf_get_lines(0, region[1]-1, region[2], true)
  end
  local command = table.concat(lines, '\r') .. '\r'
  return command
end

function M.run_command(region)
  whole_command = prepare_command(region)
  -- delete visual selection marks
  vim.cmd([[delm <>]])
  if Cfg.runner_is_open == false then
    open_new_runner()
  end
  send_kitty_command(Cfg.run_cmd, whole_command)
end

function M.open_new_runner()
  if Cfg.runner_is_open == false then
    open_new_runner()
  end
end

function M.re_run_command()
  if whole_command then
    if Cfg.runner_is_open == false then
      open_new_runner()
    end
    send_kitty_command(Cfg.run_cmd, whole_command)
  end
end

function M.prompt_run_command(commandarg)
  fn.inputsave()
  local command = commandarg or fn.input("Command: ")
  fn.inputrestore()
  whole_command = command .. '\r'
  if Cfg.runner_is_open == false then
    open_new_runner()
  end
  send_kitty_command(Cfg.run_cmd, whole_command)
end

function M.kill_runner()
  if Cfg.runner_is_open == true then
    send_kitty_command(Cfg.kill_cmd, nil)
  end
end

function M.clear_runner()
  if Cfg.runner_is_open == true then
    send_kitty_command(Cfg.run_cmd, '')
  end
end

local function define_commands()
  cmd[[command! KittyReRunCommand lua require('kitty-runner').re_run_command()]]
  cmd[[command! -range KittySendLines lua require('kitty-runner').run_command(vim.region(0, vim.fn.getpos("'<"), vim.fn.getpos("'>"), "l", false)[0])]]
  cmd[[command! -nargs=+ KittyRunCommand lua require('kitty-runner').prompt_run_command(<q-args>)]]
  cmd[[command! KittyClearRunner lua require('kitty-runner').clear_runner()]]
  cmd[[command! KittyKillRunner lua require('kitty-runner').kill_runner()]]
  cmd[[command! KittyOpenRunner lua require('kitty-runner').open_new_runner()]]
end

local function define_keymaps()
  nvim_set_keymap('n', '<leader>tr', ':KittyRunCommand<cr>', {})
  nvim_set_keymap('x', '<leader>ts', ':KittySendLines<cr>', {})
  nvim_set_keymap('n', '<leader>ts', ':KittySendLines<cr>', {})
  nvim_set_keymap('n', '<leader>tc', ':KittyClearRunner<cr>', {})
  nvim_set_keymap('n', '<leader>tk', ':KittyKillRunner<cr>', {})
  nvim_set_keymap('n', '<leader>tl', ':KittyReRunCommand<cr>', {})
end

function M.setup(cfg_)
  Cfg = cfg_ or {}
  local uuid_handle = io.popen[[uuidgen|sed 's/.*/&/']]
  local uuid = uuid_handle:read("*a")
  uuid_handle:close()
  Cfg.runner_name = 'vim-cmd' .. uuid
  Cfg.run_cmd = Cfg.run_cmd or {'send-text', '--match=title:' .. Cfg.runner_name}
  Cfg.kill_cmd = Cfg.kill_cmd or {'close-window', '--match=title:' .. Cfg.runner_name}
  if Cfg.use_keymaps ~= nil then
    Cfg.use_keymaps = Cfg.use_keymaps
  else
    Cfg.use_keymaps = true
  end
  define_commands()
  if Cfg.use_keymaps == true then
    define_keymaps()
  end
  Cfg.runner_is_open = false
end

return M
