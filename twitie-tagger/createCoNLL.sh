#!/bin/bash

# print help message for invalid uses
print_help() {
	printf "\nInvalid arguments!\n"
	echo "Usage:  ./createCoNLL.sh [OPTION] <INPUT FILE>"
	printf "OPTION:\n\t--remove\tremoves all intermediate files at the end.\n"
	printf "INPUT FILE:\t\tfile consists of sentences per line.\n\n"
}

# $# will is equal to the number of passed arguments.
if [ $# -ne 1 ] && [ $# -ne 2 ]; then
	print_help
	exit 1
elif [ $# -eq 2 ]; then
	if [ "$1" != "--remove" ]; then
		print_help
		exit 1
	fi	
	input=$2
else
	input=$1
fi



# tokenize tweets
../ark-tweet-nlp-tokenizer/twokenize.sh $input > 'tokenized_temp.txt'
if [ -f tokenized_tweets.txt ]; then
	rm tokenized_tweets.txt
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
	echo "$line" | cut -d$'\t' -f1 >> tokenized_tweets.txt
done < tokenized_temp.txt
rm tokenized_temp.txt



# find POS tags of tokenized tweets
echo 'Finding POS tags ...'
java -jar ./twitie_tag.jar ./models/gate-EN-twitter.model 'tokenized_tweets.txt' > 'tagged_tweets.txt'
printf "\n" >> tagged_tweets.txt



# print all POST tags in a file 
echo 'Extracting POS tags ...'
if [ -f POS_tags.txt ]; then
	rm POS_tags.txt
fi

tags_arr=()
global_rematch() { 
    local s=$1 regex=$2
	if [ $# -ne 2 ]; then
		while [[ $s =~ $regex ]]; do 
			#echo ${BASH_REMATCH[1]}
			echo ${BASH_REMATCH[1]#_} >> POS_tags.txt
			tags_arr+=("${BASH_REMATCH[1]#_}")
		    s=${s#*"${BASH_REMATCH[1]}"}
		done
		echo >> POS_tags.txt
		tags_arr+=('
')
	else
		while [[ $s =~ $regex ]]; do 
			#echo ${BASH_REMATCH[1]}
			tags_arr+=("${BASH_REMATCH[1]#_}")
		    s=${s#*"${BASH_REMATCH[1]}"}
		done
		tags_arr+=('
')
	fi
}

regex="(_[A-Z$]{1,4}|_[.,:()]|_''|_\"|_\`\`)(:? |
)"
while IFS='' read -r line || [[ -n "$line" ]]; do
	# line doesn't include \n ; it needs to be appended for regex!
	global_rematch "$line
" "$regex" 
done < tagged_tweets.txt



# call lemmatizer and store lemmas into an array
echo 'Lemmatizing the tokenized input ...'
java -cp ../stanford-corenlp-full-2016-10-31/stanford-corenlp-3.7.0.jar:../stanford-corenlp-full-2016-10-31/stanford-corenlp-3.7.0-models.jar:../stanford-corenlp-full-2016-10-31/xom.jar:../stanford-corenlp-full-2016-10-31/joda-time.jar -Xmx600m edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators tokenize,ssplit,pos,lemma -file ./tokenized_tweets.txt -ssplit.eolonly true -tokenize.whitespace true -outputFormat conll

echo 'Loading lemmas from the file ...'
lemma_arr=()
while IFS=$'\t' read -ra arr || [[ -n "${arr[@]: -1:1}" ]]; do
	lemma_arr+=("${arr[2]}")
done < tokenized_tweets.txt.conll



# convert tokenized_tweets.txt into CoNLL Format and append POS tags
echo 'Creating CoNLL_tweets.tsv ...'
if [ -f CoNLL_tweets.tsv ]; then
	rm CoNLL_tweets.tsv
fi

tag_index=0
lemma_index=0
while IFS=' ' read -ra arr || [[ -n "${arr[@]: -1:1}" ]]; do
	for index in "${!arr[@]}"
	do
		echo "${arr[index]}	O	${lemma_arr[lemma_index]}	${tags_arr[tag_index]}" >> CoNLL_tweets.tsv
		lemma_index=$((lemma_index+1))
		tag_index=$((tag_index+1))
	done
	echo >> CoNLL_tweets.tsv
	lemma_index=$((lemma_index+1))
	tag_index=$((tag_index+1))
done < tokenized_tweets.txt



# remove intermediate files 
if [ $# -eq 2 ]; then
	rm tokenized_tweets.txt
	rm tagged_tweets.txt
	rm tokenized_tweets.txt.conll
fi

printf 'Done!\n\n'



