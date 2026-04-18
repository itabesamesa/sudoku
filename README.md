# sudoku
sudoku in bash using kittys text sizing protocol

<img width="1280" height="606" alt="2026-04-18-02:26:26-screenshot" src="https://github.com/user-attachments/assets/dcc22add-285d-4198-bd81-88994d646bbd" />

I wanted to do something with [kittys text sizing protocol](https://sw.kovidgoyal.net/kitty/text-sizing-protocol/)

It is very slow... (it takes ~1 sec to change the screen after an input)

## Running

The first argument of the `./sudoku.sh` is the sudoku puzzle you want to play. This can be a string of 81 numbers where the 0s can be spaces. If you use spaces instead of 0s, make sure there aren't any spaces that aren't part of the sudoku puzzle
```
./sudoku.sh "300|967|001\n040|302|080\n020|000|070\n---+---+---\n070|000|090\n000|873|000\n500|010|003\n---+---+---\n004|705|100\n905|000|207\n800|621|004"
./sudoku.sh "3  |967|  1\n 4 |3 2| 8 \n 2 |   | 7 \n---+---+---\n 7 |   | 9 \n   |873|   \n5  | 1 |  3\n---+---+---\n  4|7 5|1  \n9 5|   |2 7\n8  |621|  4"
./sudoku.sh "300967001040302080020000070070000090000873000500010003004705100905000207800621004"
./sudoku.sh "3  967  1 4 3 2 8  2     7  7     9    873   5   1   3  47 51  9 5   2 78  621  4"
```
All of these should work

## Schizoku

A while back i downloaded a Sudoku app and i played it so often, that i swear i started getting sudokus i had already played... `./schizoku.sh` has the same starting point and (obviously) the same solution. It does however randomly add/remove numbers and switches their values around

Run it with `-e` if you want a pretty output
```
./schizoku.sh -e
```
To pass it to `./sudoku.sh` run this:
```
./sudoku.sh $(./schizoku.sh)
```
Give this to a friend you hate and see how long they take to realize they're getting scammed i guess...

## Notes

Might endup rewriting this in C, but i don't know yet
