function scrape-otovo-shareholders
    set -l project_dir ~/Development/otovo/shareholders
    cd $project_dir
    
    if test "$argv[1]" = "--setup-launchd"
        echo "Setting up launchd job..."
        launchctl load ~/Library/LaunchAgents/com.otovo.shareholder-scraper.plist
        echo "Job loaded. Check with: launchctl list | grep otovo"
    else if test "$argv[1]" = "--test"
        echo "Running test scrape..."
        deno run --allow-net --allow-read --allow-write --allow-ffi main.ts
    else if test "$argv[1]" = "--history"
        deno run --allow-read --allow-write --allow-ffi history.ts
    else if test "$argv[1]" = "--logs"
        tail -f scraper.log
    else
        echo "Usage:"
        echo "  scrape-otovo --setup-launchd  # Set up automatic daily scraping"
        echo "  scrape-otovo --test          # Run scraper once"
        echo "  scrape-otovo --history       # View history"
        echo "  scrape-otovo --logs          # Watch logs"
    end
end
