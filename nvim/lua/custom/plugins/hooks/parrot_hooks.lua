local parrot_hooks = {}

parrot_hooks.Complete = function(prt, params)
  local template = [[
I have the following code from {{filename}}:



{{filetype}}
{{selection}}


Please finish the code above carefully and logically.
Respond just with the snippet of code that should be inserted.
]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
end

parrot_hooks.CompleteFullContext = function(prt, params)
  local template = [[
I have the following code from {{filename}}:



{{filetype}}
{{filecontent}}


Please look at the following section specifically:


{{filetype}}
{{selection}}


Please finish the code above carefully and logically.
Respond just with the snippet of code that should be inserted.
]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
end

parrot_hooks.CompleteMultiContext = function(prt, params)
  local template = [[
I have the following code from {{filename}} and other related files:



{{filetype}}
{{multifilecontent}}


Please look at the following section specifically:


{{filetype}}
{{selection}}


Please finish the code above carefully and logically.
Respond just with the snippet of code that should be inserted.
]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
end

parrot_hooks.Explain = function(prt, params)
  local template = [[
Your task is to take the code snippet from {{filename}} and explain it with gradually increasing complexity.
Break down the code's functionality, purpose, and key components.



{{filetype}}
{{selection}}


Use markdown format with code blocks and inline code.
Explanation:
]]
  local model = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.new, model, nil, template)
end

parrot_hooks.FixBugs = function(prt, params)
  local template = [[
You are an expert in {{filetype}}.
Fix bugs in the following code from {{filename}}:



{{filetype}}
{{selection}}


Provide the corrected code and a short explanation of the fixes.
]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.new, model_obj, nil, template)
end

parrot_hooks.Optimize = function(prt, params)
  local template = [[
Analyze and optimize the following {{filetype}} code:



{{filetype}}
{{selection}}


Suggest improvements for performance, readability, and efficiency.
]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.new, model_obj, nil, template)
end

parrot_hooks.UnitTests = function(prt, params)
  local template = [[
Write table-driven unit tests for the following code:



{{filetype}}
{{selection}}


]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.enew, model_obj, nil, template)
end

parrot_hooks.Debug = function(prt, params)
  local template = [[
Review the following code, identify bugs or edge cases, and suggest fixes:



{{filetype}}
{{selection}}


]]
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.enew, model_obj, nil, template)
end

parrot_hooks.CommitMsg = function(prt, params)
  local futils = require 'parrot.file_utils'
  if futils.find_git_root() == '' then
    prt.logger.warning 'Not in a git repository'
    return
  end
  local template = [[
Generate a git commit message from the staged diff below using the conventional commit format:

]] .. vim.fn.system 'git diff --no-color --no-ext-diff --staged'
  local model_obj = prt.get_model 'command'
  prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
end

parrot_hooks.SpellCheck = function(prt, params)
  local chat_prompt = [[
Rewrite the text to fix grammar, spelling, and punctuation while preserving meaning.
]]
  prt.ChatNew(params, chat_prompt)
end

parrot_hooks.CodeConsultant = function(prt, params)
  local chat_prompt = [[
Analyze the following {{filetype}} code and suggest improvements for performance and clarity.



{{filetype}}
{{filecontent}}


]]
  prt.ChatNew(params, chat_prompt)
end

parrot_hooks.ProofReader = function(prt, params)
  local chat_prompt = [[
Review the following text for grammar, clarity, and style. Return:
1. Corrected version with backticks for changes
2. Slightly improved version
3. Ideal version

Respond in this format:

## Corrected text:
...
## Slightly better text:
...
## Ideal text:
...

Text:
{{selection}}
]]
  prt.ChatNew(params, chat_prompt)
end

return parrot_hooks
