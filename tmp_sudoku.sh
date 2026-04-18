#!/bin/bash

field="$1"

ZERO=$((0xff10))

to_unicode() {
  echo -e \\u$(printf '%x\n' $1)
}

repeat() {
  (
    for ((i = 0; i < $1; i++)); do echo -n $2; done
  )
}

scale() {
  echo "\e]66;s=$1;${2//"%s"/"$1"}\a" | sed 's/%{\([^}]*\)}/\\a\1\\e]66;s='$1';/g'
}

chr_to_double_wide_num() {
  to_unicode $(($ZERO + ${1:0:1}))
}

chr_to_display() {
  if [[ "${1:0:1}" == " " ]]; then
    echo -e "\u3000"
  else
    chr_to_double_wide_num $1
  fi
}

scale_sub() {
  echo "\a$2\e]66;s=$1;"
}

# a for none
# c for cursor highlight bg
# b for sub field/row/column highlight bg
# n for mun highlight fg
# d for b and n
# w for wrong
# e for w and n
# f for wrong cursor highlight bg

highlight() {
  case "${1:0:1}" in
  c)
    echo "%{\e[1;33;45m}$2%{\e[22;39;49m}"
    ;;
  b)
    echo "%{\e[44m}$2%{\e[49m}"
    ;;
  n)
    echo "%{\e[1;33m}$2%{\e[22;39m}"
    ;;
  d)
    echo "%{\e[1;33;44m}$2%{\e[22;39;49m}"
    ;;
  w)
    echo "%{\e[31m}$2%{\e[39m}"
    ;;
  e)
    echo "%{\e[1;31;44m}$2%{\e[22;39;49m}"
    ;;
  f)
    echo "%{\e[1;31;45m}$2%{\e[22;39;49m}"
    ;;
  *)
    echo "$2"
    ;;
  esac
}

cell_to_display() {
  local offset
  if [[ ${1:1:1} == "0" ]]; then
    local tmp=${1:2}
    tmp=${tmp//"0"/" "}
    local tmp2=""
    local cell1=""
    local cell2=""
    local cell3=""
    for ((i = 0; i < ${#tmp}; i += 2)); do
      if [[ ${tmp:$i:1} == "a" ]]; then
        tmp2="$(highlight ${1:0:1} "$(chr_to_display "${tmp:$(($i + 1)):1}")")"
      else
        tmp2="$(highlight ${1:0:1} "$(highlight ${tmp:$i:1} "$(chr_to_display "${tmp:$(($i + 1)):1}")")")"
      fi
      case $(($i / 6)) in
      0)
        cell1="$cell1$tmp2"
        ;;
      1)
        cell2="$cell2$tmp2"
        ;;
      2)
        cell3="$cell3$tmp2"
        ;;
      esac
    done
    echo "\e[3B\e[3A$(scale 1 "$cell1%{\e[%sB\e[6D}$cell2%{\e[%sB\e[6D}$cell3%{\e[%sB}")\e[3A"
  else
    if [[ ${1:0:1} == "a" ]]; then
      echo "\e[3B\e[3A$(scale 3 $(chr_to_display "${1:1:1}"))"
    else
      echo "\e[3B\e[3A$(scale 3 "$(highlight $1 "$(chr_to_display "${1:1:1}")")")"
    fi
  fi
}

parse_sudoku() {
  local field=""
  local cell1=""
  local cell2=""
  local cell3=""

  local j=0
  local regex="[0-9 ]+"
  for ((i = 0; i < ${#1}; i++)); do
    local c=${1:$i:1}
    if [[ "$c" =~ $regex ]]; then
      if [[ "$c" == " " ]]; then
        c="0"
      fi
      case $(($j % 9 / 3)) in
      0)
        cell1="${cell1}a${c}a0a0a0a0a0a0a0a0a0 "
        ;;
      1)
        cell2="${cell2}a${c}a0a0a0a0a0a0a0a0a0 "
        ;;
      2)
        cell3="${cell3}a${c}a0a0a0a0a0a0a0a0a0 "
        ;;
      esac
      if [[ $(($j % 27)) == 26 ]]; then
        field="$field$cell1$cell2$cell3"
        cell1=""
        cell2=""
        cell3=""
      fi
      ((j++))
    fi
  done
  echo "$field"
}

sudoku=($(parse_sudoku "$field"))
offset=0
sudoku[$offset]=${sudoku[$offset]/a/c}

populate_sub_grid() {
  grid=$(scale 3 '  │  │  %{\e[%sB\e[24D}──┼──┼──%{\e[%sB\e[24D}  │  │  %{\e[%sB\e[24D}──┼──┼──%{\e[%sB\e[24D}  │  │  %{\e[%sB}')
  i=0
  while [[ $grid == *"  "* ]]; do
    grid=${grid/"  "/"$(scale_sub 3 "$(cell_to_display "${sudoku[$(($i + $1))]}")")"}
    ((i++))
  done
  echo "$grid"
}

grid_row() {
  echo "$(repeat 15 "\n")\e[15A$(populate_sub_grid $((0 + $1)))\e[15A$(repeat 5 "$(scale 3 "┃")\e[3B\e[3D")\e[15A\e[3C$(populate_sub_grid $((9 + $1)))\e[15A$(repeat 5 "$(scale 3 "┃")\e[3B\e[3D")\e[15A\e[3C$(populate_sub_grid $((18 + $1)))"
}

grid() {
  (
    grid_row 0
    echo "\e[1F$(scale 3 "━━━━━━━━╋━━━━━━━━╋━━━━━━━━")\e[2B"
    grid_row 27
    echo "\e[1F$(scale 3 "━━━━━━━━╋━━━━━━━━╋━━━━━━━━")\e[2B"
    grid_row 54
  )
}

move_right() {
  if [[ $(($offset % 9 % 3)) == 2 ]]; then
    if [[ $(($offset / 9 % 3)) != 2 ]]; then
      ((offset += 7)) # cause of the offset of 3
      sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
    fi
  else
    ((offset++))
    sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
  fi
}

move_left() {
  if [[ $(($offset % 9 % 3)) == 0 ]]; then
    if [[ $(($offset / 9 % 3)) != 0 ]]; then
      ((offset -= 7)) # cause of the offset of 3
      sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
    fi
  else
    ((offset--))
    sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
  fi
}

move_down() {
  if [[ $(($offset % 9 / 3)) == 2 ]]; then
    if [[ $(($offset / 9 / 3)) != 2 ]]; then
      ((offset += 21)) # cause of the offset of 3
      sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
    fi
  else
    ((offset += 3))
    sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
  fi
}

move_up() {
  if [[ $(($offset % 9 / 3)) == 0 ]]; then
    if [[ $(($offset / 9 / 3)) != 0 ]]; then
      ((offset -= 21)) # cause of the offset of 3
      sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
    fi
  else
    ((offset -= 3))
    sudoku[$offset]=${sudoku[$offset]/[a-z]/c}
  fi
}

change_highlight() {
  local column=$((($offset % 9 % 3) + ($offset / 9 % 3 * 9)))
  local row=$((($offset % 9 / 3 * 3) + ($offset / 9 / 3 * 27)))
  if [[ $1 != 0 ]]; then
    sudoku=(${sudoku[@]//a$1/n$1})
  else
    tmp="${sudoku[$offset]}"
    for ((i = 0; i < ${#tmp}; i += 2)); do
      if [[ ${tmp:$((i + 1)):1} != "0" ]]; then
        sudoku=(${sudoku[@]//"${tmp:$i:2}"/"n${tmp:$((i + 1)):1}"})
      fi
    done
  fi
  for ((i = 0; i < 9; i++)); do
    if [[ ${sudoku[$column]:0:1} != "c" ]]; then
      sudoku[$column]=${sudoku[$column]/a/b}
      sudoku[$column]=${sudoku[$column]/n/d}
      sudoku[$column]=${sudoku[$column]/w/e}
    fi
    if [[ ${sudoku[$row]:0:1} != "c" ]]; then
      sudoku[$row]=${sudoku[$row]/a/b}
      sudoku[$row]=${sudoku[$row]/n/d}
      sudoku[$row]=${sudoku[$row]/w/e}
    fi
    if [[ $(($column % 9 / 3)) == 2 ]]; then
      ((column += 21))
    else
      ((column += 3))
    fi
    if [[ $(($row % 9 % 3)) == 2 ]]; then
      ((row += 7))
    else
      ((row++))
    fi
  done
}

clear_highlight() {
  sudoku=(${sudoku[@]//[bdg-vx-z]/a})
  sudoku=(${sudoku[@]//e/w})
}

clear_cursor() {
  sudoku=(${sudoku[@]//c/a})
  sudoku=(${sudoku[@]//f/w})
}

check_doublicates() {
  local grid=$(($offset / 9))
  local column=$((($offset % 9 % 3) + ($grid % 3 * 9)))
  local row=$((($offset % 9 / 3 * 3) + ($grid / 3 * 27)))
  for ((i = 0; i < 9; i++)); do
    if [[ ${sudoku[$column]:0:1} != "c" || ${sudoku[$row]:0:1} != "c" || ${sudoku[$grid]:0:1} != "c" ]]; then
      if [[ "${sudoku[$column]}" == *"$1"* || "${sudoku[$row]}" == *"$1"* || "${sudoku[$grid]}" == *"$1"* ]]; then
        return 0
      fi
    fi
    if [[ $(($column % 9 / 3)) == 2 ]]; then
      ((column += 21))
    else
      ((column += 3))
    fi
    if [[ $(($row % 9 % 3)) == 2 ]]; then
      ((row += 7))
    else
      ((row++))
    fi
    ((grid++))
  done
  return 1
}

place_number() {
  if check_doublicates $1; then
    sudoku[$offset]=${sudoku[$offset]/[a-z]/f}
  fi
  sudoku[$offset]=${sudoku[$offset]/[0-9]/$1}
}

place_number_note() {
  local slice=$(($1 * 2))
  if check_doublicates $1; then
    local tmp=${sudoku[$offset]:2}
    sudoku[$offset]="${sudoku[$offset]:0:2}${tmp//[a-z]$1/f$1}"
  fi
  sudoku[$offset]="${sudoku[$offset]:0:$(($slice + 1))}$1${sudoku[$offset]:$(($slice + 2))}"
}

prev=$((${sudoku[$offset]:1:1}))
change_highlight $prev
echo -e "\e[0;0H\e[2J$(grid)"

while true; do
  read -srn1
  clear_highlight
  case "$REPLY" in
  d)
    clear_cursor
    move_right
    prev=$((${sudoku[$offset]:1:1}))
    ;;
  a)
    clear_cursor
    move_left
    prev=$((${sudoku[$offset]:1:1}))
    ;;
  s)
    clear_cursor
    move_down
    prev=$((${sudoku[$offset]:1:1}))
    ;;
  w)
    clear_cursor
    move_up
    prev=$((${sudoku[$offset]:1:1}))
    ;;
  q)
    exit
    ;;
  0)
    prev=$(($REPLY))
    sudoku[$offset]=${sudoku[$offset]/[0-9]/$REPLY}
    ;;
  [1-9])
    prev=$(($REPLY))
    place_number $REPLY
    ;;
  "!")
    prev=1
    place_number_note 1
    ;;
  "\"")
    prev=2
    place_number_note 2
    ;;
  "§")
    prev=3
    place_number_note 3
    ;;
  "\$")
    prev=4
    place_number_note 4
    ;;
  "%")
    prev=5
    place_number_note 5
    ;;
  "&")
    prev=6
    place_number_note 6
    ;;
  "/")
    prev=7
    place_number_note 7
    ;;
  "(")
    prev=8
    place_number_note 8
    ;;
  ")")
    prev=9
    place_number_note 9
    ;;
  "=")
    prev=0
    tmp=${sudoku[$offset]:2}
    sudoku[$offset]="${sudoku[$offset]:0:2}${tmp//[1-9]/0}"
    ;;
  esac
  change_highlight $prev
  echo -e "\e[0;0H\e[2J$(grid)"
done
