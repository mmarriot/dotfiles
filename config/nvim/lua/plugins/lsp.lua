-- ==============================================================================
--  LSP  (native neovim LSP, no Mason)
--
--  clangd / clang-format / clang-tidy come from `cmsenv` (CVMFS, el8-built).
--  pyright + ruff come from install.sh (npm / pip). Every server is guarded by
--  executable() so nothing errors when it's absent - e.g. C++ outside a cmsenv.
-- ==============================================================================

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "hrsh7th/cmp-nvim-lsp" },
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Diagnostics: signs + inline virtual text, kept quiet
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      severity_sort = true,
    })

    -- --- server definitions (neovim 0.11+ vim.lsp.config API) -----------------

    -- clangd (C / C++ / CUDA) - from cmsenv
    vim.lsp.config("clangd", {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
      },
      capabilities = capabilities,
      filetypes = { "c", "cpp", "cuda", "objc", "objcpp" },
      root_markers = { "compile_commands.json", ".git", "CMakeLists.txt" },
    })

    -- pyright (Python) - from `npm i -g pyright`
    vim.lsp.config("pyright", {
      capabilities = capabilities,
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
    })

    -- ruff (Python lint/format) - from `pip install ruff`
    vim.lsp.config("ruff", {
      capabilities = capabilities,
      filetypes = { "python" },
    })

    -- bash
    vim.lsp.config("bashls", { capabilities = capabilities })

    -- Enable only servers whose binary is actually on PATH
    if vim.fn.executable("clangd") == 1 then
      vim.lsp.enable("clangd")
    end
    if vim.fn.executable("pyright-langserver") == 1 then
      vim.lsp.enable("pyright")
    end
    if vim.fn.executable("ruff") == 1 then
      vim.lsp.enable("ruff")
    end
    if vim.fn.executable("bash-language-server") == 1 then
      vim.lsp.enable("bashls")
    end

    -- --- buffer-local keymaps on attach (your old vim-lsp vocabulary) --------
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
      callback = function(ev)
        local opts = function(desc)
          return { buffer = ev.buf, silent = true, desc = desc }
        end
        local map = vim.keymap.set
        map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
        map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
        map("n", "gr", vim.lsp.buf.references, opts("References"))
        map("n", "gt", vim.lsp.buf.type_definition, opts("Type definition"))
        map("n", "K", vim.lsp.buf.hover, opts("Hover docs"))
        map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        map("n", "]e", function() vim.diagnostic.jump({ count = 1 }) end, opts("Next diagnostic"))
        map("n", "[e", function() vim.diagnostic.jump({ count = -1 }) end, opts("Prev diagnostic"))

        -- ruff is lint/format only - let pyright own hover so K isn't doubled
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "ruff" then
          client.server_capabilities.hoverProvider = false
        end
      end,
    })
  end,
}
