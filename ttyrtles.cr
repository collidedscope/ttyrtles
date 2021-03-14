Width  = `tput cols`.to_i16
Height = `tput lines`.to_i16 * 2

def rgb(color)
  color.digits(256).reverse.join ';'
end

class Ttyrtle
  property? dead
  property! game : Game

  def initialize(@x : Int16, @y : Int16, @dir : UInt8, @color : UInt32)
  end

  def tick
    return if dead?

    change_direction if about_to_collide? || rand < 0.05
    travel
    render

    game.history << {@x, @y}
    game.occupied[{@y // 2, @x}] = {@color, @y.even?}
  end

  def render
    print "\e[#{@y // 2 + 1};#{@x + 1}H" # move cursor

    if occupied = game.occupied[{@y // 2, @x}]?
      other, top = occupied
      a, b = @color, other
      a, b = b, a if top
      print "\e[38;2;#{rgb a};48;2;#{rgb b}m▀\e[m"
    else
      print "\e[38;2;#{rgb @color}m#{"▀▄"[@y % 2]}\e[m"
    end
  end

  def travel
    case @dir
    when 0; @x += 1
    when 1; @y += 1
    when 2; @x -= 1
    when 3; @y -= 1
    end
  end

  def untravel
    case @dir
    when 0; @x -= 1
    when 1; @y -= 1
    when 2; @x += 1
    when 3; @y += 1
    end
  end

  def about_to_collide?
    return true if @dir == 0 && @x == Width - 1 ||
                   @dir == 1 && @y == Height - 1 ||
                   @dir == 2 && @x == 0 ||
                   @dir == 3 && @y == 0

    travel
    status = collided?
    untravel
    status
  end

  def collided?
    game.history.includes?({@x, @y})
  end

  def change_direction
    options = [[1u8, 3u8], [0u8, 2u8]][@dir % 2].reject { |option|
      @dir = option
      about_to_collide?
    }

    return @dead = true if options.empty?
    @dir = options.sample
  end
end

class Game
  property history = Set({Int16, Int16}).new
  property occupied = Hash(Tuple(Int16, Int16), Tuple(UInt32, Bool)).new

  def initialize(@ttyrtles : Array(Ttyrtle))
    @ttyrtles.each &.game = self
  end

  def loop
    until @ttyrtles.all? &.dead?
      @ttyrtles.each &.tick
      sleep 1/60
    end

    print "\e[#{Height - 1};#{Width}H"
  end
end

viridis = [
  0x440154, 0x471164, 0x481f70, 0x472d7b, 0x443a83,
  0x404688, 0x3b528b, 0x365d8d, 0x31688e, 0x2c728e,
  0x287c8e, 0x24868e, 0x21908c, 0x1f9a8a, 0x20a486,
  0x27ad81, 0x35b779, 0x47c16e, 0x5dc863, 0x75d054,
  0x8fd744, 0xaadc32, 0xc7e020, 0xe3e418, 0xfde725,
]

ttyrtles = viridis.map { |color|
  x = rand Width
  y = rand Height
  dir = rand 4u8
  Ttyrtle.new x, y, dir, color.to_u32
}

print `clear`
Game.new(ttyrtles).loop
