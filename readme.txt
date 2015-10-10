data.json contains all 2391 plays analyzed in the paper.
For each entry: 
"userid" is a unique ID for each player. 
"score" is -1 if the play failed.
"key" contains the distance instance where "acc" or "brk" buttons are pressed. E.g., "acc"=[174,2048,2771,3535,4847] says the vehicle started to accelerate at distance 174 (which is roughly the starting distance in the game) until distance 2048, and then restarted at 2771 until 3535, then restarted at 4847 until the game is over.
"ranking_percentage" records the rank of the play when it was recorded
"ranking_scoreboard" records whether the play was among the top five when it was recorded