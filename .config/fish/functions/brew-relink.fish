function brew-relink -d "Will relink all installed brew packages"
	brew list -1 | while read -l line
		brew unlink $line
  	brew link $line	
	end
end
