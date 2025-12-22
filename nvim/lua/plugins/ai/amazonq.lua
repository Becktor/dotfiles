return {
  {
    name = 'amazonq',
    url = 'https://github.com/awslabs/amazonq.nvim.git',
    enabled = false,
    opts = {
      ssoStartUrl = 'https://view.awsapps.com/start', -- Authenticate with Amazon Q Free Tier
      inline_suggest = true,
    },
  },
}
