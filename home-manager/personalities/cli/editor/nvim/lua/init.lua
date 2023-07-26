return {
vim.cmd([[
autocmd BufRead,BufNewFile */templates/*.yml,*/templates/*.tpl,*.gotmpl,helmfile*.yml set ft=helm
]])
 
}
