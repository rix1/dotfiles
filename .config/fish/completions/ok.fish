# Disable file completions
complete -c ok -f

# Top-level commands
complete -c ok -n '__fish_use_subcommand' -a 'secret' -d 'Manage secrets' 
complete -c ok -n '__fish_use_subcommand' -a 'exec' -d 'Open a shell'
complete -c ok -n '__fish_use_subcommand' -a 'status' -d 'Check deployment status'
complete -c ok -n '__fish_use_subcommand' -a 'context' -d 'Manage contexts'
complete -c ok -n '__fish_use_subcommand' -a 'configure' -d 'Store personal access token'
complete -c ok -n '__fish_use_subcommand' -a 'upgrade' -d 'Upgrade version'
complete -c ok -n '__fish_use_subcommand' -a 'help' -d 'Print help'

# Sub-commands for 'secret'
complete -c ok -n '__fish_seen_subcommand_from secret' -a 'get' -d 'Get secret value'
complete -c ok -n '__fish_seen_subcommand_from secret' -a 'set' -d 'Set secret value'
complete -c ok -n '__fish_seen_subcommand_from secret' -a 'rm' -d 'Remove secret value'
complete -c ok -n '__fish_seen_subcommand_from secret' -a 'list' -d 'List secret keys'
complete -c ok -n '__fish_seen_subcommand_from secret' -a 'help' -d 'Print help'

# Sub-commands for 'exec'
complete -c ok -n '__fish_seen_subcommand_from exec' -a 'shell' -d 'Open a bash shell in a new app container'
complete -c ok -n '__fish_seen_subcommand_from exec' -a 'psql' -d 'Open a psql shell in a psql container'
complete -c ok -n '__fish_seen_subcommand_from exec' -a 'pod' -d 'Open a bash shell in an existing pod'
complete -c ok -n '__fish_seen_subcommand_from exec' -a 'help' -d 'Print help'

# Sub-commands for 'context'
complete -c ok -n '__fish_seen_subcommand_from context' -a 'set list current' -d 'Manage contexts'
complete -c ok -n '__fish_seen_subcommand_from context' -a 'help' -d 'Print help'

complete -c ok -n '__fish_seen_subcommand_from context' -a 'set' -d 'Change context'
complete -c ok -n '__fish_seen_subcommand_from context' -a 'list' -d 'List available contexts'
complete -c ok -n '__fish_seen_subcommand_from context' -a 'current' -d 'Show current context'
complete -c ok -n '__fish_seen_subcommand_from context' -a 'help' -d 'Print help'

# Global options
complete -c ok -s h -l help -d 'Print help'
complete -c ok -s V -l version -d 'Print version'
complete -c ok -s d -l debug -d 'Debug mode'

# Options for commands with applications
complete -c ok -n '__fish_seen_subcommand_from secret exec status' -s a -l application -r -d 'Specifies the application'

# Documentation for 'configure' and 'upgrade'
complete -c ok -n '__fish_seen_subcommand_from configure' -a 'INSERT_PAT' -d 'Store personal access token'
complete -c ok -n '__fish_seen_subcommand_from upgrade' -d 'Upgrade version'


# Abbverations
abbr -a okc "ok context"
abbr -a okcc "ok context current"
abbr -a okcs "ok context set"
abbr -a okcl "ok context list"

abbr -a oks "ok status -a"

abbr -a oke "ok exec"
abbr -a okes "ok exec shell"
abbr -a okeps "ok exec psql"
abbr -a okep "ok exec pod"

