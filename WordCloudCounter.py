# Build a word cloud counter 

# This project comes from my UC San Diego MicroMasters course 1, Python for Data Science. 

# Start with importing collections package for use towards the end 

import collections

# Import the file from my hard drive into python, for this word bubble, we will be using 

file=open('98-0.txt', encoding="utf8")

# Create the data structure to use, in this case a dictionary

wordcount = {} 

# Now I want to seperate the values within the original import file 
# and clean the data

for word in file.read().lower().split():
    word = word.replace(".", "") 
    word = word.replace(",","")
    word = word.replace("\"", "") 
    word = word.replace("“","")

#For the previous line, why do we include the backslash? 
# and how do you note the quotes in the last line without it
# closing the brackets (i only got it to work by copy pasting 
# from the solutions) 

# Now I count out the words

if word not in wordcount: 
    wordcount[word] = 1 
else:
    wordcount[word] += 1

# Now I will use the collections package, the collections.counter 
# function will be useful to count all of the word counts. 

Count = collections.Counter(wordcount)

for word, count in Count.most_common(10):
    print(word, ":", count)

