return {
  -- colorscheme = "catppuccin",
  --
  -- plugins = {
  --   {
  --     "catppuccin/nvim",
  --     name = "catppuccin",
  --     config = function()
  --       require("catppuccin").setup {}
  --     end,
  --   },
  -- },
    vim.filetype.add({
      extension = {
    yaml = utils.yaml_filetype,
    yml = utils.yaml_filetype,
          tmpl = utils.tmpl_filetype,
          tpl = utils.tpl_filetype
      },
      filename = {
          ["Chart.yaml"] = "yaml",
          ["Chart.lock"] = "yaml",
      }
  })

  function is_helm_file(path)
    local check = vim.fs.find("Chart.yaml", { path = vim.fs.dirname(path), upward = true })
    return not vim.tbl_isempty(check)
  end

  --@private
  --@return string
  function yaml_filetype(path, bufname)
    return is_helm_file(path) and "helm.yaml" or "yaml"
  end

  --@private
  --@return string
  function tmpl_filetype(path, bufname)
    return is_helm_file(path) and "helm.tmpl" or "template"
  end

  --@private
  --@return string
  function tpl_filetype(path, bufname)
    return is_helm_file(path) and "helm.tmpl" or "smarty"
  end
}
