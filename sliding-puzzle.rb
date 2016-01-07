module SlidingPuzzle

  # 定数一覧
  TOP = :TOP
  BOTTOM = :BOTTOM
  RIGHT = :RIGHT
  LEFT = :LEFT
  UP = :UP
  DOWN = :DOWN
  ABOVE = :ABOVE
  BELOW = :BELOW
  CLOCKWISE = :CLOCKWISE
  COUNTER_CLOCKWISE = :COUNTER_CLOCKWISE

  # Object of the puzzle
  # めちゃくちゃ悩んだのですが、以下のようにしました。
  #
  # まず、横方向をx 縦方向をyとしたかった(左上原点にして[2,3]のマス、みたいな)
  #
  # 一方実装は(見た目に合わせるため、またユーザーによる代入がしやすいようにと)こうなった
  # [ [1,  2,  3],
  #   [4,  5,  6],
  #   [7,  8,  9],
  #   [10, 11, nil] ]
  #
  # つまりユーザー視点ではnilは [2,3] だけど、システム的には obj.body[3][2]だ、みたいなことになる
  #
  # そこでシステムが(計算などで)指定するものは [3, 2]、ユーザー指定のものは{x:2, y:3}とすることにする。
  # 変換は多少冗長だけれど、メンテナンス性を考えて [:x, :y].reverse! としましょう。明示的に変化したほうが後々楽だろうしね
  # つまるところ [row, column] == [y, x] ってことか
  class SlidingPuzzle

    def initialize(x_size, y_size, body)
      @area_size = x_size * y_size
      @x_size = x_size
      @y_size = y_size
      @body = Array.new(y_size, Array.new(x_size))
      @target = [0..y_size-1, 0..x_size-1]
      @nil_xy = []

      set_body(body)
      @nil_xy = find_element_in_2d(@body, nil)
    end
    attr_reader :body, :x_size, :y_size

    # reader代わりのメソッド。人間が読むように整形してくれてます。主に順番を
    def target
      {x: @target[1], y: @target[0]}
    end

    # 初期状態の設定・再設定
    # initでも呼び出してます
    def set_body(array)
      array.flatten!
      raise "Wrong array size" if array.size != @area_size
      new_body = Array.new
      @y_size.times do |c|
        new_body << array.slice((c)*@x_size, @x_size)
      end
      @body = new_body
    end
    alias_method :body=, :set_body


    # Targetの更新。指定しなかった方は前回の設定が引き継がれる
    # どこかにnilが含まれるかどうかは判定します。
    def set_target(x:@target[1], y:@target[0])
      %w(x y).each do |key|
        elem = eval(key)                                                                                          # †黒魔術†
        raise TypeError, "Keyword #{key} must be Range:Object "  if elem.class != Range
        raise NoElementInPositionError, "Range (#{elem})"  if (elem.first < 0 || elem.last > eval("@#{key}_size"))
      end
      # target内にnilがあることを確認
      raise NoSuchElementError, "nil"  if  y.to_a.all? do |_y|
        x.to_a.all? do |_x|
          #print "#{@body[_y][_x]} "  # FIXME: Debug用
          @body[_y][_x] != nil
        end
      end
      @target = [y, x]
      target
    end

    # set_targetのエイリアスなんだけど alias_method でやるとエラー変わっちゃうから書きました。引数１つまでだしねこの形だと
    def target=(hash)
      # なんともお行儀の悪いエラーの出し方ですこと。…いやいやRubyの「=」の扱いが悪いのですよお嬢様
      if hash.class == Array && hash.length == 2
        hash = {x:hash[1], y:hash[0]}                     # Arrayで渡す場合は内部仕様[y, x]として扱う
      elsif hash.class != Hash || hash.keys != [:x, :y]
        raise ArgumentError, "#{hash.class} #{hash} given, must be Hash {x:, y:}"
      end
      set_target(x:hash[:x], y:hash[:y])
    end


    # 他の(目標などの)SlidingPuzzleオブジェクトと答え合わせ
    def check_with(other_puzzle, target = :ALL)
      if other_puzzle.class != SlidingPuzzle
        raise TypeError, "#{other_puzzle} is not an object of SlidingPuzzle::SlidingPuzzle"
      elsif other_puzzle.x_size != self.x_size || other_puzzle.y_size != self.y_size
        raise "Both puzzle's sizes must be the same."
      end

      target_array = Array.new
      case target.class.to_s
      when "Symbol"
        case target
        when :ALL
          @y_size.times do |y|
            @x_size.times do |x|
              target_array << [y, x]
            end
          end
        when LEFT
          @target[0].to_a.each do |y|
            target_array << [y, @target[1].first]
          end
        when RIGHT
          @target[0].to_a.each do |y|
            target_array << [y, @target[1].last]
          end
        when TOP
          @target[1].to_a.each do |x|
            target_array << [@target[0].first, x]
          end
        when BOTTOM
          @target[1].to_a.each do |x|
            target_array << [@target[0].last, x]
          end
        else
          raise UnknownOptionError, target
        end
      when "Array"
        unless target.all? {|tar| tar.class == Range}
          raise ArgumentError, "Must be a Array of Ranges."
        end
        target[0].each do |y|
          target[1].each do |x|
            target_array << [y, x]
          end
        end
      else
        raise ArgumentError, "#{target.class} #{target} given, must be Array or Symbol objects."
      end

      target_array.all? do |tar|
        self.body[tar[0]][tar[1]] == other_puzzle.body[tar[0]][tar[1]]
      end
    end


    # タイルを動かす。キーワードでモードを指定
    # 戻り値： self
    def move(arg)
      if arg.class != Hash
        raise("Keyword and Value needed.")
      end

      hash = arg
      key = hash.keys.first
      value = hash.values.first

      case key
      when :element
        move_element(value)
      when :position, :from
        move_from_position(value)
      when :direction, :to
        move_to_direction(value)
      when :coordinates, :xy
        move_by_coordinates(value)
      else
       raise(UnknownOptionError, key)
      end

      return self
    end

    # Targetを対象に、時計回りか反時計回りかに回す
    # @targetを回すので、一通り全部動かす
    #
    #  1  2  3   Clockwise    4  1  2
    #  4  5  6  ==========>   7  5  3  (6, 3, 2, ... って動かす)
    #  7  8                   8     6
    #
    # 実装自体は素直にやらなくてもいいかもだけど
    # 戻り値： self
    def rotate(direction)
      # @targetからperiphery(外周)を取り出す
      periphery = Array.new
      ## まず上、→方向
      @target[1].each do |x|
        periphery << [@target[0].min, x]
      end
      ## 次に右、↓方向
      @target[0].each do |y|
        periphery << [y, @target[1].max]
      end
      ## さらに下、←方向
      @target[1].reverse_each do |x|
        periphery << [@target[0].max, x]
      end
      ## そして左、↑方向
      @target[0].reverse_each do |y|
        periphery << [y, @target[1].min]
      end
      ## 最後に重複を除きます
      periphery.uniq!
      # periphery完成！

      # peripheryにnilが含まれるか確認
      raise NoSuchElementError, "nil" unless periphery.include?(@nil_xy)  # TODO: ここもnil一つにしか対応してない
      nil_pos = periphery.find_index(@nil_xy)

      # 回す
      pos_order_arr = (nil_pos+1 .. periphery.length-1).to_a + (0 .. nil_pos-1).to_a
      case direction
      when CLOCKWISE
        pos_order_arr.reverse!
      when COUNTER_CLOCKWISE
        pos_order_arr
      else
        raise(UnknownOptionError, direction.nil? ? "nil" : direction)
      end
      pos_order_arr.each do |index|
        move_by_coordinates(periphery[index])
      end

      return self
    end

    # rotateの拡張。一時的にtargetを指定する便利な奴
    # 戻り値： self
    def rotate_target(target, direction)
      def_target = @target      # とっておいて
      self.target = target
      rotate(direction)
      self.target = def_target  # 差し戻す

      return self
    end

    def arrange_side(other_puzzle, side, max_trials = 50000, stack_size = 1, print_every = nil)
      target_array = []
      case side
      when LEFT
        @target[0].to_a.each do |y|
          target_array << [y, @target[1].first]
        end
      when RIGHT
        @target[0].to_a.each do |y|
          target_array << [y, @target[1].last]
        end
      when TOP
        @target[1].to_a.each do |x|
          target_array << [@target[0].first, x]
        end
      when BOTTOM
        @target[1].to_a.each do |x|
          target_array << [@target[0].last, x]
        end
      else
        raise UnknownOptionError, "#{side}  Use either of these: LEFT RIGHT TOP BOTTOM"
      end

      # Check if there are any nils in target_side
      raise "No nil tiles are allowed." unless target_array.all? do |tar|
        other_puzzle.body[tar[0]][tar[1]] != nil
      end

      # Stackを用いてランダム試行。力押しとはこのことよ
      stack = Array.new(stack_size, nil)
      nth = nil
      succeeded = false

      max_trials.times do |trial|
        # moveする
        begin
          ind = Random.rand(100)%4
          if stack.include?([ABOVE, BELOW, RIGHT, LEFT][ind])
            redo
          else
            position = [ABOVE, BELOW, RIGHT, LEFT][ind]
          end
          self.move(from: position)
        rescue NoElementInPositionError
          retry  # こ れ は ひ ど い
        else
          stack.shift
          stack.push([BELOW, ABOVE, LEFT, RIGHT][ind])
        end

        #答え合わせ
        if check_with(other_puzzle, side)
          nth = trial + 1
          succeeded = true
          break
        end

        # printオプション
        if print_every && print_every != 0   # numerics will be true
          if (trial+1) % print_every == 0
            puts "↓#{trial + 1}回目"
            print self
          end
        end
      end

      # 結果発表
      if succeeded
        #puts "Completed in #{nth} times of trial!!"
        return nth
      else
        puts "Wasn't able to complete mission after #{max_trials} times of trial."
        return false
      end
    end

    # arrange_sideした後に残りの部分の範囲をセットしてくれます。失敗した場合は元の範囲のままにします。
    # 返り値は self か 範囲{x:Range, y:Range} かで迷っています
    # 失敗時は false を返すのでご活用ください
    def arrange_side_and_set_target(other_puzzle, side, max_trials = 50000, stack_size = 1, print_every = 0)
      bool = arrange_side(other_puzzle, side, max_trials, stack_size, print_every)
      if bool
        case side
        when LEFT
          set_target(x:@target[1].first+1..@target[1].last, y:@target[0])
        when RIGHT
          set_target(x:@target[1].first..@target[1].last-1, y:@target[0])
        when TOP
          set_target(x:@target[1],                          y:@target[0].first+1..@target[0].last)
        when BOTTOM
          set_target(x:@target[1],                          y:@target[0].first..@target[0].last-1)
        else
          raise "This error should not have happened... side #{side} handled after arrange_side"
        end
        return bool
      else
        return false
      end
    end


    private ########################################################################################################################

    # TODO: ココらへんのメソッド、nilマス１つの時にしか対応してないから後で拡張する いまはいらないや

    def move_element(element)
      case @body.flatten.count(element)
      when 0
        raise(NoSuchElementError, element)
      when 2..Float::INFINITY
        raise(ElementNotUniqueError, element)
      else
        element_xy = find_element_in_2d(@body, element)
        p arr = element_xy.calc_with(@nil_xy) {|a, b| a - b}
        case arr
        when [-1, 0]  # 上
          p "ABOVE"
          move_from_position(ABOVE)
        when [1, 0]  # 下
          p "BELOW"
          move_from_position(BELOW)
        when [0, -1]  # 左
          p "LEFT"
          move_from_position(LEFT)
        when [0, 1]  # 右
          p "RIGHT!"
          move_from_position(RIGHT)
        else
          raise(ElementNotSideBySideError, element)
        end
      end
    end

    def move_from_position(position)
      case position
      when ABOVE
        assist_array = [-1, 0]
      when BELOW
        assist_array = [1, 0]
      when LEFT
        assist_array = [0, -1]
      when RIGHT
        assist_array = [0, 1]
      else
        raise(UnknownOptionError, position)
      end

      if @nil_xy.length != assist_array.length
        raise "Array sizes aren't same"
      end

      # 計算します
      element_position = @nil_xy.calc_with(assist_array) { |x,y| x + y }
      # チェックします
      #unless (0..@y_size-1).include?(element_position[0]) && (0..@x_size-1).include?(element_position[1])
      unless @target[0].include?(element_position[0]) && @target[1].include?(element_position[1])
        raise(NoElementInPositionError, "Direction #{position}")
      end
      # 入れ替えします
      @body[@nil_xy[0]][@nil_xy[1]] = @body[element_position[0]][element_position[1]]   # nilだった枠に値を移動
      @body[element_position[0]][element_position[1]] = nil                             # 値があった枠にnilを上書き
      @nil_xy = element_position                                                        # nilの場所情報を更新
    end

    def move_to_direction(direction)
      case direction
      when UP
        move_from_position(BELOW)
      when DOWN
        move_from_position(ABOVE)
      when LEFT
        move_from_position(RIGHT)
      when RIGHT
        move_from_position(LEFT)
      else
        raise(UnknownOptionError, direction)
      end
    end

    # Coordinatesは[x,y]で渡したいんだけど[y,x]になるから一行目でreverse!してます
    # こうすると方向がinitializeと揃う。人間的には気持ち悪くなくなる
    def move_by_coordinates(coordinates)
      orig_coordinates = coordinates
      if caller_locations(3).first.label == "rotate"
        # use original coordinates
      elsif coordinates.class != Hash
        raise TypeError, "Coordinate value must be Hash: {x:, y:}"
      else
        coordinates = [coordinates[:y], coordinates[:x]]
      end

      # チェックします
      unless @target[0].include?(coordinates[0]) && @target[1].include?(coordinates[1])
        raise(NoElementInPositionError, "Coordinate #{orig_coordinates}")
      end
      diff = @nil_xy.calc_with(coordinates) {|x,y| x - y }
      unless [[1,0], [-1,0], [0,1], [0,-1]].include?(diff)
        raise(ElementNotSideBySideError, @body[coordinates[0]][coordinates[1]])
      end

      # 入れ替えします
      @body[@nil_xy[0]][@nil_xy[1]] = @body[coordinates[0]][coordinates[1]]   # nilだった枠に値を移動
      @body[coordinates[0]][coordinates[1]] = nil                             # 値があった枠にnilを上書き
      @nil_xy = coordinates                                                   # nilの場所情報を更新
    end

    def find_element_in_2d(array, element)
      positions = Array.new
      array.each_index do |ind|
        dex = array[ind].find_index(element)
        positions << [ind, dex] unless dex == nil
      end
      raise("Error defining positions: element none") if positions.length == 0
      return positions.length == 1 ? positions.first : positions
    end

    # Errors ################################ Errors ##################################### Errors #####################

    class UnknownOptionError < StandardError
      def initialize(arg)
        super(arg)
      end
    end

    class NoSuchElementError < StandardError
      def initialize(arg)
        super("Element \"#{arg}\" does not appear to be there")
      end
    end

    class ElementNotUniqueError < StandardError
      def initialize(arg)
        super("There are several element named #{arg}. Use :positions or :coordinates instead.")
      end
    end

    class NoElementInPositionError < StandardError
      def initialize(arg)
        super("#{arg} is out of bounds!")
      end
    end

    class ElementNotSideBySideError < StandardError
      def initialize(arg)
        super("Element #{arg} is not at side of the space")
      end
    end
  end


  # SlidingPuzzleオブジェクト作成を呼び出しやすくするためだけの特異メソッド。行儀悪いかも
  class << self
    def new(arg1, arg2, arg3, *args)
      self::SlidingPuzzle.new(arg1, arg2, arg3)#, args)
    end
  end


  module_function

  # Kernel.printの拡張。includeすればね。SlidingPuzzleオブジェクトを描画できるようになります。
  def print(target)
    # p target.class  #=> SlidingPuzzle::SlidingPuzzle
    # p target.class == SlidingPuzzle  #=> true  もしかしてmoduleの中にあるとこうなるのかな？
    if target.class == SlidingPuzzle || target.class.superclass == SlidingPuzzle
      x, y = target.y_size, target.x_size
      (x*2+1).times do |row|
        (y*2+1).times do |col|
          if row % 2 == 0
            if col % 2 == 0
              Kernel.print "+"
            else
              Kernel.print "---"
            end
          else
            if col % 2 == 0
              Kernel.print "|"
            else
              num = target.body[(row+1)/2-1][(col+1)/2-1]
              if num == nil
                Kernel.print("   ")
              else
                Kernel.print(
                    case num.to_s.length
                    when 1
                      " #{num} "
                    when 2
                      " #{num}"
                    else
                      num
                    end
                )
              end
            end
          end
          if col == y*2
            Kernel.puts ""
          end
        end
      end
      return nil
    # 通常のオブジェクトはKernel.printする
    else
      Kernel.print(target)
    end
  end
end

# Arrayクラスの拡張。include SlidingPuzzle すると使われるようになります。
# 意味不明だけど Array < Array にすると拡張ができる… moduleに入れてるからかなぁ…もっど深くに入れたらどうするんだ
class Array

  # 数値のみで出来ているArray同士の計算ができるようになります。
  # TODO: 数字以外があったらどうするか
  def calc_with(arrays)
    length = [arrays.length, self.length].min
    return_arr = Array.new
    length.times do |i|
      return_arr << yield([self, arrays].map {|array| array[i]})
    end
    return return_arr
  end

  # 要素が同じかどうかを確認します。同じならtrue、ひとつでも違えばfalse。
  # このメソッドはデフォルトの Array.=== の挙動を書き換えます！！
  #  => case文の挙動がかわります！！！
  # ので封印中。使ってるところ無いし
  ###def === (other_ary)
  ###  self.flatten.all?{|me| other_ary.include?(me)} && other_ary.all?{|her| self.flatten.include?(her)}
  ###end
end



=begin ### おまけ
#これ、何故か判定不良を起こす…
####
p element_xy = find_element_in_2d(@body, element)
p @nil_xy
case element_xy
when [@nil_xy[0]-1, @nil_xy[1]]  # 上
  p [@nil_xy[0]-1, @nil_xy[1]]
  p "ABOVE"
  move_from_position(ABOVE)
when [@nil_xy[0]+1, @nil_xy[1]]  # 下
  p [@nil_xy[0]+1, @nil_xy[1]]
  p "BELOW"
  move_from_position(BELOW)
when [@nil_xy[0], @nil_xy[1]-1]  # 左
  p [@nil_xy[0], @nil_xy[1]-1]
  p "LEFT"
  move_from_position(LEFT)
when [@nil_xy[0], @nil_xy[1]+1]  # 右
  p [@nil_xy[0], @nil_xy[1]+1]
  p "RIGHT!"
  move_from_position(RIGHT)
else
  raise(ElementNotSideBySideError, element)
end
####
# element = [1, 2]
# nil = [1, 1]
# つまり動かしたいものが右側にあるときに何故か「BELOW」判定を出される
=end