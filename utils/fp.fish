# Fish completion for the `fp` command
# Check $fish_complete_path for possible install locations
# Or check the documentation:
# https://fishshell.com/docs/current/completions.html#where-to-put-completions

function __fp_cli_complete
    # Get current buffer and cursor
    set --local COMP_LINE (commandline)
    set --local COMP_POINT (commandline -C)

    # Get valid completions from fp-cli
    set --local opts (fp cli completions --line=$COMP_LINE --point=$COMP_POINT)

    # fp-cli will indicate if it needs a file
    if string match -qe "<file> " -- $opts
        command ls -1
    else
        # Remove unnecessary double spaces that fp-cli splits options with
        string trim -- $opts
        # `string` echoes each result on a newline.
        # Which is then collected for use with the `-a` flag for `complete`.
    end
end
complete -f -a "(__fp_cli_complete)" fp
