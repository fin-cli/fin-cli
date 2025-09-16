# Fish completion for the `fin` command
# Check $fish_complete_path for possible install locations
# Or check the documentation:
# https://fishshell.com/docs/current/completions.html#where-to-put-completions

function __fin_cli_complete
    # Get current buffer and cursor
    set --local COMP_LINE (commandline)
    set --local COMP_POINT (commandline -C)

    # Get valid completions from fin-cli
    set --local opts (fin cli completions --line=$COMP_LINE --point=$COMP_POINT)

    # fin-cli will indicate if it needs a file
    if string match -qe "<file> " -- $opts
        command ls -1
    else
        # Remove unnecessary double spaces that fin-cli splits options with
        string trim -- $opts
        # `string` echoes each result on a newline.
        # Which is then collected for use with the `-a` flag for `complete`.
    end
end
complete -f -a "(__fin_cli_complete)" fin
