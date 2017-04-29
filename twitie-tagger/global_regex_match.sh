#!/bin/bash

regex="(_[A-Z$]{1,4}|_[.,:()]|_''|_\"|_\`\`)(:? |
)"

global_rematch() { 
    local s=$1 regex=$2
    while [[ $s =~ $regex ]]; do 
		echo ${BASH_REMATCH[1]}
		echo ${BASH_REMATCH[1]#_} >> tgs.txt
        s=${s#*"${BASH_REMATCH[1]}"}
		echo $s
    done
	echo >> tgs.txt
}

quote="\`"
echo $quote
replaceWith="\\\`"
while IFS='' read -r line || [[ -n "$line" ]]; do
	echo $line
	#line="${line//$quote/$replaceWith}"
	echo $line
	global_rematch "$line
" "$regex" 
#	break
done < in.txt
