-- Копия линтера mypy, но всегда включает режим strict
-- Также убирает подчеркивание всего тела функции, подчеркивается только первая строка сигнатуры
local function pretty_mypy_linter()
  local pattern = '([^:]+):(%d+):(%d+):(%d+):(%d+): (%a+): (.*)'
  local groups = { 'file', 'lnum', 'col', 'end_lnum', 'end_col', 'severity', 'message' }
  local severities = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    note = vim.diagnostic.severity.HINT,
  }

  return {
    cmd = 'mypy',
    stdin = false,
    ignore_exitcode = true,
    args = {
      '--strict',
      '--show-column-numbers',
      '--show-error-end',
      '--hide-error-codes',
      '--hide-error-context',
      '--no-color-output',
      '--no-error-summary',
      '--no-pretty',
    },
    parser = function(output, bufnr, linter_cwd)
      local current_groups = { table.unpack(groups) }
      -- Если будут другие проблемы с подсветкой, то добавлять их сюда
      if output:find('Function') ~= nil then
        -- Если убрать правильное имя из groups, то подчеркиваться будет одна строка
        current_groups[4] = ''
      end
      return require('lint.parser').from_pattern(
        pattern,
        current_groups,
        severities,
        { ['source'] = 'mypy' },
        { end_col_offset = 0 }
      )(output, bufnr, linter_cwd)
    end
  }
end


return {
  {
    "mfussenegger/nvim-lint",
    lazy=false,
    opts = {
      -- Event to trigger linters
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        -- Все линтеры должны быть установлены через mason в lsp.lua, либо вручную, если в
        -- Mason их установка не поддерживается!!!
        python = { "pretty_mypy", "ruff" },
        cpp = { "clangtidy" },
        yaml = { "yamllint" },
        cmake = { "cmakelint" },
        sh = { "shellcheck" },
        -- Use the "*" filetype to run linters on all filetypes.
        ['*'] = {
        },
      },
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
        pretty_mypy = pretty_mypy_linter()
      },
    },
    config = function(_, opts)
      local M = {}

      local lint = require("lint")

      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
        else
          lint.linters[name] = linter
        end
      end

      lint.linters_by_ft = opts.linters_by_ft

      function M.debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      function M.lint()
        -- Use nvim-lint's logic first:
        -- * checks if linters exist for the full filetype first
        -- * otherwise will split filetype by "." and add all those linters
        -- * this differs from conform.nvim which only uses the first filetype that has a formatter
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Create a copy of the names table to avoid modifying the original.
        names = vim.list_extend({}, names)

        -- Add global linters.
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        -- Filter out linters that don't exist or don't match the condition.
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            vim.notify("(nvim-lint) Linter not found: " .. name, vim.log.levels.WARN)
          end
          return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        -- Run linters.
        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = M.debounce(100, M.lint),
      })
    end,
  },

}

