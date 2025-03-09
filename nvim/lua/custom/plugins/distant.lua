#https://github.com/chipsenkbeil/distant.nvim
return {
    'chipsenkbeil/distant.nvim',
    branch = 'v0.3',
    config = function()
        require('distant'):setup()
    end
}
