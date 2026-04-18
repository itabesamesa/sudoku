#!/bin/bash

# 300|967|001
# 040|302|080
# 020|000|070
# ---+---+---
# 070|000|090
# 000|873|000
# 500|010|003
# ---+---+---
# 004|705|100
# 905|000|207
# 800|621|004
puzzle="300|967|001\n040|302|080\n020|000|070\n---+---+---\n070|000|090\n000|873|000\n500|010|003\n---+---+---\n004|705|100\n905|000|207\n800|621|004"
#echo -e "$puzzle\n"
puzzle="${puzzle//[^0-9]/}"
# 358|967|421
# 741|352|689
# 629|184|375
# ---+---+---
# 173|546|892
# 492|873|516
# 586|219|743
# ---+---+---
# 264|795|138
# 915|438|267
# 837|621|954
solution="358|967|421\n741|352|689\n629|184|375\n---+---+---\n173|546|892\n492|873|516\n586|219|743\n---+---+---\n264|795|138\n915|438|267\n837|621|954"
#echo -e "$solution\n"
solution="${solution//[^0-9]/}"

format_sudoku() {
  local tmp=""
  i=1
  while [[ $i -le ${#1} ]]; do
    tmp+="${1:$(($i - 1)):1}"
    if [[ $(($i % 3)) == 0 ]]; then
      if [[ $(($i % 9)) == 0 ]]; then
        tmp+="\n"
        if [[ $(($i % 27)) == 0 && $(($i % 81)) != 0 ]]; then
          tmp+="---+---+---\n"
        fi
      else
        tmp+="|"
      fi
    fi
    ((i++))
  done
  echo "$tmp"
}

for ((i = 0; i < 10; i++)); do
  pos=$(($RANDOM % 81))
  if [[ "${puzzle:$pos:1}" == "0" ]]; then
    puzzle="${puzzle:0:$pos}${solution:$pos:1}${puzzle:$(($pos + 1))}"
  else
    puzzle="${puzzle:0:$pos}0${puzzle:$(($pos + 1))}"
  fi
done

puzzle="${puzzle//1/a}"
puzzle="${puzzle//2/b}"
puzzle="${puzzle//3/c}"
puzzle="${puzzle//4/d}"
puzzle="${puzzle//5/e}"
puzzle="${puzzle//6/f}"
puzzle="${puzzle//7/g}"
puzzle="${puzzle//8/h}"
puzzle="${puzzle//9/i}"
nums="123456789"
chars="abcdefghi"

while [[ ! -z $nums ]]; do
  pos=$(($RANDOM % ${#nums}))
  puzzle="${puzzle//"${chars:0:1}"/"${nums:$pos:1}"}"
  nums="${nums:0:$pos}${nums:$(($pos + 1))}"
  chars="${chars:1}"
done

echo $1 $(format_sudoku $puzzle)
