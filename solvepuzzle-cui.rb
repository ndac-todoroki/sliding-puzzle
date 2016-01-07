require_relative 'sliding-puzzle'
include SlidingPuzzle

# Error for raising.
class NotAbleToSolveError < StandardError
  def initialize
    puts super "Seems not able to solve the puzzle."
  end
end


print "Enter the array's x (default:3): "
x = (num = gets.to_i) == 0 ? 3 : num

print "Enter the array's y (default:3): "
y = (num = gets.to_i) == 0 ? 3 : num

puts "Enter the array's body. Separate elements by spaces. Place a 'nil' where there's no tiles."
print "           : "
puz_arr = gets.chomp.split(/[[:blank:]]/).map do |i|
  begin
    eval(i)
  rescue NameError
    i
  end
end
puz_body = puz_arr.length != 0 ? puz_arr : ((1..x*y-1).to_a << nil).shuffle

puts "Enter the goal's body. Separate elements by spaces. Place a 'nil' where there's no tiles."
print "           : "
goal_arr = gets.chomp.split(/[[:blank:]]/).map do |i|
  begin
    eval(i)
  rescue NameError
    i
  end
end
goal_body = goal_arr.length != 0 ? goal_arr : (1..x*y-1).to_a << nil

puzzle = SlidingPuzzle.new(x, y, puz_body)
goal = SlidingPuzzle.new(x, y, goal_body)

puts "繰り返し回数、スタックの深さ、プリントオプション数を改行で指定してください: "
trials = (num = gets.to_i) != 0 ? num : x*y*4*10**(x+y)
stack = (num = gets.to_i) != 0 ? num : 1
print_opt = (num = gets.to_i)!= 0 ? num : 0         # 0で描画なし

### Matzによるおまじない ###
# 参考：http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/42076
# > 以下のコードを実行するとそれ以降print, putsなどの出力がファイルと標準出力の両方に行われます。
###########################
defout = Object.new
defout.instance_eval{@ofile=open("./sliding-puzzle_#{x}-#{y}-#{trials}_#{Random.rand(x*y*10**(x+y))}.log", "w")}
class << defout
  def write(str)
    STDOUT.write(str)
    @ofile.write(str)
  end
end
$stdout = defout
###########################

#File.open("./sliding-puzzle_#{Random.rand(trials)}.log", "w") do |file|

  puts "START!!"
  begin
    # ループ本体。set_targetしてくれるので自動的に範囲が狭まってゆくはず。
    loop do
      target = puzzle.target     # {x:Range, y:Range}
      puts "\n* target = #{target}"
      print puzzle
      side =  (target[:x].size <=> target[:y].size) >= 0 ? SlidingPuzzle::LEFT : SlidingPuzzle::TOP
      puts "** #{side} を揃えます\n\n"
      result = puzzle.arrange_side_and_set_target(goal, side, trials, stack, print_opt)     # これ自体がループ
      if result
        puts "Cleared with #{result} tries"
        trials = (trials * 0.5).floor
      else
        raise NotAbleToSolveError
      end
      break if puzzle.check_with(goal, :ALL)
    end
  rescue NotAbleToSolveError => e
    puts ""
    print puzzle
    puts e
  rescue => e
    puts "CRITICAL: #{e}"
  else
    puts ""
    print puzzle
    puts "COMPLETED!"
  end

#end
