# sliding-puzzle.rb
SlidingPuzzle::SlidingPuzzle

## 利用方法

```
require_relative './sliding-puzzle'
include SlidingPuzzle
```
includeすると ```print``` でSlidingPuzzleオブジェクトの場合は以下のように特殊な書き出しをしてくれたり、
Arrayクラスに ```calc_with``` メソッドが追加されたりします。

動作例

```
puzzle = SlidingPuzzle.new(3, 3, [1,4,5,2,8,6,7,3,nil])
print puzzle
#=>
+---+---+---+
| 1 | 4 | 5 |
+---+---+---+
| 2 | 8 | 6 |
+---+---+---+
| 7 | 3 |   |
+---+---+---+
```

```
print puzzle.move(position: ABOVE)      # ABOVEにあるタイルを空白位置に動かす
#=>
+---+---+---+
| 1 | 4 | 5 |
+---+---+---+
| 2 | 8 |   |
+---+---+---+
| 7 | 3 | 6 |
+---+---+---+
```



## 自動解決スクリプトの説明
以下Readme.txtの流用なので記法があれ

【実行方法】

```
$ ruby ./solvepuzzle-cui.rb
```


【起動後のオプション指定】

・Enter the array's x (default:3): 
横(ｘ軸)方向のマス目を指定します。デフォルトは３です

・Enter the array's y (default:3): 
縦(ｙ軸)方向。デフォルトは３

・Enter the array's body. Separate elements by spaces. 
　Place a 'nil' where there's no tiles.
左上から右方向に数を打っていきます。空白で区切り、空きマスはnilを指定してください
デフォルトではランダムで入れます。

例）

```
 ２ ８ ６
 １ ４ ５   なら   2 8 6 1 4 5 7 3 nil
 ７ ３ □
```

・Enter the goal's body. Separate elements by spaces. 
　Place a 'nil' where there's no tiles.
同じく。デフォルトは1,2,..,8,nilが順に入ります

・繰り返し回数、スタックの深さ、プリントオプション数を改行で指定してください: 
３つの数字を改行区切りで指定します。インプット方法の統一感のなさは許してください。めんどかったんです
- 繰り返し回数：各列を揃えるときに、ランダムでひたすらタイルを動かす方法をとっていますが、それを最大何回繰り返すか、の指定です。パズルの大きさによって変えてください。３×３なら10000もあれば足りると思います。デフォルトは30000。
- スタックの深さ：ランダムで動かすとはいえ、直前に動いた方向に戻られたら意味ないので、スタックに履歴を叩き込んで効率をあげようとしています。多少。スタックに履歴をいくつまで貯めこむか、の値です。今回スタックに入れるのは「上・下・左・右」の４方向のみなので、スタックは１でいいと思います。デフォルトは１です。
　※４以上を指定するとフリーズします。無限ループですね。
- プリントオプション：経過を書き出したいときに使います。ここで指定した整数回数の操作ごとにパズルの状態を書き出します。0を指定するとプリントは無効になります。無効であっても、操作の節目ごとの書き出しはされます。1を指定すると全部書き出されますが、フリーズしたりはしないと思うので気楽に使いましょ。但しログファイルはでかくなります。


【出力】
```
sliding-puzzle_ｘ数_ｙ数_試行数_ランダム数.log 
```
ってファイルに書きだされます。見てみましょう。


