module AoC::Year2020::Day20
  class Parser
    def initialize(input)
      @tiles = input.split("\n\n").map do |tile|
        lines = tile.split("\n")
        Tile.new(
          lines.first.split(" ").last.to_i,
          lines[1..-1].map { |line|
            line.chars.map { |c| c == "#" }
          }
        )
      end
    end

    attr_reader :tiles
  end

  class ParserTest < Minitest::Test
    def test_parse_example
      parser = Parser.new(<<~INPUT)
        Tile 2311:
        ..##.#..#.
        ##..#.....
        #...##..#.
        ####.#...#
        ##.##.###.
        ##...#.###
        .#.#.#..##
        ..#....#..
        ###...#.#.
        ..###..###

        Tile 1951:
        #.##...##.
        #.####...#
        .....#..##
        #...######
        .##.#....#
        .###.#####
        ###.##.##.
        .###....#.
        ..#.#..#.#
        #...##.#..
      INPUT

      assert_equal 2311, parser.tiles.first.id
      assert_equal 1951, parser.tiles.last.id

      expected = Tile.new(1951, [
        [true,  false, true,  true,  false, false, false, true,  true,  false],
        [true,  false, true,  true,  true,  true,  false, false, false, true],
        [false, false, false, false, false, true,  false, false, true,  true],
        [true,  false, false, false, true,  true,  true,  true,  true,  true],
        [false, true,  true,  false, true,  false, false, false, false, true],
        [false, true,  true,  true,  false, true,  true,  true,  true,  true],
        [true,  true,  true,  false, true,  true,  false, true,  true,  false],
        [false, true,  true,  true,  false, false, false, false, true,  false],
        [false, false, true,  false, true,  false, false, true,  false, true],
        [true,  false, false, false, true,  true,  false, true,  false, false]
      ])
      assert_equal(expected, parser.tiles.last)
    end
  end

  Tile = Struct.new(:id, :data) do
    def to_s
      [
        "Tile #{id}:",
        data.map { |line| line.map { |c| c ? "#" : "." }.join }.join("\n")
      ].join("\n")
    end

    def h_flip
      Tile.new(id, data.map(&:reverse))
    end

    def v_flip
      Tile.new(id, data.reverse)
    end

    def rotate(n)
      tile = self
      n.times {
        tile = Tile.new(tile.id, tile.data.first.zip(*tile.data[1..-1])).h_flip
      }
      tile
    end

    def possible_edges
      @possible_edges ||=
        begin
          r = rotate(1)
          Set.new([
            data.first,
            data.first.reverse,
            data.last,
            data.last.reverse,
            r.data.first,
            r.data.first.reverse,
            r.data.last,
            r.data.last.reverse
          ])
        end
    end

    def left_edge
      rotate(1).top_edge.reverse
    end

    def right_edge
      rotate(1).bottom_edge.reverse
    end

    def top_edge
      data.first
    end

    def bottom_edge
      data.last
    end

    def meets?(constraints)
      top, right, bottom, left = *constraints

      (top.nil? || top == top_edge) &&
        (right.nil? || right == right_edge) &&
        (bottom.nil? || bottom == bottom_edge) &&
        (left.nil? || left == left_edge)
    end

    def variations
      f = self.h_flip
      Set.new([
        self,
        rotate(1),
        rotate(2),
        rotate(3),
        f,
        f.rotate(1),
        f.rotate(2),
        f.rotate(3),
      ])
    end

    def trim
      Tile.new(
        id,
        data[1..-2].map { |row| row[1..-2] }
      )
    end
  end

  class TileTest < Minitest::Test
    def test_to_s
      assert_equal <<~OUTPUT.strip, new_tile.to_s
        Tile 1951:
        #.##...##.
        #.####...#
        .....#..##
        #...######
        .##.#....#
        .###.#####
        ###.##.##.
        .###....#.
        ..#.#..#.#
        #...##.#..
      OUTPUT
    end

    def test_trim
      tile = Tile.new(33, [
        [false, false, true,  true],
        [false, false, true,  false],
        [false, false, false, true],
        [false, false, false, true],
      ])

      expected = Tile.new(33, [
        [false, true],
        [false, false]
      ])

      assert(
        expected,
        tile.trim
      )
    end

    def test_variations
      tile = Tile.new(33, [
        [false, false, true],
        [false, false, true],
        [false, false, false]
      ])

      expected = Set.new([
        Tile.new(33, [[false, false, true],
                      [false, false, true],
                      [false, false, false]]),
        Tile.new(33, [[false, false, false],
                      [false, false, false],
                      [false, true,  true]]),
        Tile.new(33, [[false, false, false],
                      [true,  false, false],
                      [true,  false, false]]),
        Tile.new(33, [[true,  true,  false],
                      [false, false, false],
                      [false, false, false]]),
        Tile.new(33, [[false, false, false],
                      [false, false, true],
                      [false, false, true]]),
        Tile.new(33, [[false, false, false],
                      [false, false, false],
                      [true,  true,  false]]),
        Tile.new(33, [[true,  false, false],
                      [true,  false, false],
                      [false, false, false]]),
        Tile.new(33, [[false, true,  true],
                      [false, false, false],
                      [false, false, false]]),
      ])

      assert_equal(expected, tile.variations)
    end

    def test_meets
      tile = Tile.new(33, [
        [true, false, true],
        [false, false, true],
        [false, false, false]
      ])

      assert tile.meets?([
        [true, false, true],
        nil,
        nil,
        nil
      ])

      assert tile.meets?([
        [true, false, true],
        [true, true, false],
        nil,
        nil
      ])
    end

    def test_edges
      tile = new_tile

      assert_equal(
        [true, false, true, true, false, false, false, true, true, false],
        tile.top_edge
      )

      assert_equal(
        [true, false, false, false, true, true, false, true, false, false],
        tile.bottom_edge
      )

      assert_equal(
        [false, true, true, true, true, true, false, false, true, false],
        tile.right_edge
      )

      assert_equal(
        [true, true, false, true, false, false, true, false, false, true],
        tile.left_edge
      )
    end

    def test_possible_edges
      tile = Tile.new(33, [
        [true, false, true],
        [false, false, true],
        [false, false, false]
      ])
      assert_equal Set.new([
        [true, false, true],
        [false, false, false],
        [true, false, false],
        [false, false, true],
        [true, true, false],
        [false, true, true]
      ]), tile.possible_edges
    end

    def test_to_s
      tile = Tile.new(33, [
        [true, false, true],
        [false, false, true],
        [false, false, false]
      ])

      assert_equal <<~OUTPUT.strip, tile.rotate(1).to_s
        Tile 33:
        ..#
        ...
        .##
      OUTPUT

      assert_equal <<~OUTPUT.strip, tile.rotate(2).to_s
        Tile 33:
        ...
        #..
        #.#
      OUTPUT
    end

    def test_vertical_flip
      assert_equal <<~OUTPUT.strip, new_tile.v_flip.to_s
        Tile 1951:
        #...##.#..
        ..#.#..#.#
        .###....#.
        ###.##.##.
        .###.#####
        .##.#....#
        #...######
        .....#..##
        #.####...#
        #.##...##.
      OUTPUT
    end

    def test_horizontal_flip
      assert_equal <<~OUTPUT.strip, new_tile.h_flip.to_s
        Tile 1951:
        .##...##.#
        #...####.#
        ##..#.....
        ######...#
        #....#.##.
        #####.###.
        .##.##.###
        .#....###.
        #.#..#.#..
        ..#.##...#
      OUTPUT
    end

    def new_tile
      Tile.new(1951, [
        [true,  false, true,  true,  false, false, false, true,  true,  false],
        [true,  false, true,  true,  true,  true,  false, false, false, true],
        [false, false, false, false, false, true,  false, false, true,  true],
        [true,  false, false, false, true,  true,  true,  true,  true,  true],
        [false, true,  true,  false, true,  false, false, false, false, true],
        [false, true,  true,  true,  false, true,  true,  true,  true,  true],
        [true,  true,  true,  false, true,  true,  false, true,  true,  false],
        [false, true,  true,  true,  false, false, false, false, true,  false],
        [false, false, true,  false, true,  false, false, true,  false, true],
        [true,  false, false, false, true,  true,  false, true,  false, false]
      ])
    end
  end

  Image = Struct.new(:map, :size) do
    def set(index, tile)
      Image.new(
        {}.merge(map, {index => tile}),
        size
      )
    end

    def tile_at(x, y)
      return :out_of_bounds if x < 0 || x >= size || y < 0 || y >= size

      map[y * size + x] || :unknown
    end

    def filter_tiles(index, tiles)
      x = index % size
      y = (index - x) / size
      constraints = [
        tile_at(x, y + 1)&.top_edge,
        tile_at(x - 1, y)&.right_edge,
        tile_at(x, y - 1)&.bottom_edge,
        tile_at(x + 1, y)&.left_edge
      ]
      tiles.map(&:variations).flat_map(&:to_a).select { |tile| tile.meets?(constraints) }
    end

    def full?
      map.keys.count == size**2
    end
  end

  class ImageTest < Minitest::Test
    def test_example
      tile1 = Tile.new(33, [
        [true, false, true],
        [false, false, true],
        [false, false, false]
      ])

      image = Image.new({}, 3)

      assert_equal Image.new({}, 3), image

      image = image.set(0, tile1)

      assert_equal Image.new({0 => tile1}, 3), image

      tile2 = Tile.new(33, [
        [true, false, true],
        [false, false, true],
        [false, false, false]
      ])
      image = image.set(1, tile2)

      tile3 = Tile.new(33, [
        [true, false, true],
        [true, false, true],
        [false, false, false]
      ])
      image = image.set(1, tile3)
    end
  end

  class Part1
    def initialize(input = real_input)
      @input = Parser.new(input).tiles
    end

    def solution
      corner_tiles.map(&:id).inject(&:*)
    end

    private

    attr_reader :input

    def corner_tiles
      i = solved_image

      [i.tile_at(0, 0), i.tile_at(0, size - 1), i.tile_at(size - 1, 0), i.tile_at(size - 1, size - 1)]
    end

    def solved_image
      image = Image.new({}, size)

      (size ** 2).times.each do |n|
        tile = find_match!(image, n)
        image = image.set(n, tile)
      end

      image
    end

    def find_match!(image, n)
      constraint = build_constraint(image, n)

      match = input.find { |tile|
        tile.variations.any? { |t|
          matches_constraint?(t, constraint)
        }
      }
      binding.pry unless match

      input.delete(match)

      match.variations.find { |t|
        matches_constraint?(t, constraint)
      }
    end

    def matches_constraint?(tile, constraint)
      constraint.zip([tile.top_edge, tile.right_edge, tile.bottom_edge, tile.left_edge]).all? do |c, e|
        if c.is_a?(Array)
          c == e
        elsif c == :out_of_bounds
          x[e] == 1
        elsif c == :unknown
          x[e] == 2
        end
      end
    end

    def build_constraint(image, n)
      x = n % size
      y = (n - x) / size

      [
        top_constraint(image, x, y),
        right_constraint(image, x, y),
        bottom_constraint(image, x, y),
        left_constraint(image, x, y),
      ]
    end

    def top_constraint(image, x, y)
      z = image.tile_at(x, y - 1)
      if z.is_a?(Tile)
        z.bottom_edge
      else
        z
      end
    end

    def right_constraint(image, x, y)
      z = image.tile_at(x + 1, y)
      if z.is_a?(Tile)
        z.left_edge
      else
        z
      end
    end

    def bottom_constraint(image, x, y)
      z = image.tile_at(x, y + 1)
      if z.is_a?(Tile)
        z.top_edge
      else
        z
      end
    end

    def left_constraint(image, x, y)
      z = image.tile_at(x - 1, y)
      if z.is_a?(Tile)
        z.right_edge
      else
        z
      end
    end

    def x
      @x ||= input.map(&:possible_edges).flat_map(&:to_a).group_by(&:itself).transform_values(&:length)
    end

    def real_input
      @input ||= File.read("aoc/year2020/day20.txt")
    end

    def size
      @size ||= Math.sqrt(input.length).to_i
    end
  end

  class Part1Test < Minitest::Test
    def test_sample_input
      assert_equal 20899048083289, Part1.new(<<~INPUT).solution
        Tile 2311:
        ..##.#..#.
        ##..#.....
        #...##..#.
        ####.#...#
        ##.##.###.
        ##...#.###
        .#.#.#..##
        ..#....#..
        ###...#.#.
        ..###..###

        Tile 1951:
        #.##...##.
        #.####...#
        .....#..##
        #...######
        .##.#....#
        .###.#####
        ###.##.##.
        .###....#.
        ..#.#..#.#
        #...##.#..

        Tile 1171:
        ####...##.
        #..##.#..#
        ##.#..#.#.
        .###.####.
        ..###.####
        .##....##.
        .#...####.
        #.##.####.
        ####..#...
        .....##...

        Tile 1427:
        ###.##.#..
        .#..#.##..
        .#.##.#..#
        #.#.#.##.#
        ....#...##
        ...##..##.
        ...#.#####
        .#.####.#.
        ..#..###.#
        ..##.#..#.

        Tile 1489:
        ##.#.#....
        ..##...#..
        .##..##...
        ..#...#...
        #####...#.
        #..#.#.#.#
        ...#.#.#..
        ##.#...##.
        ..##.##.##
        ###.##.#..

        Tile 2473:
        #....####.
        #..#.##...
        #.##..#...
        ######.#.#
        .#...#.#.#
        .#########
        .###.#..#.
        ########.#
        ##...##.#.
        ..###.#.#.

        Tile 2971:
        ..#.#....#
        #...###...
        #.#.###...
        ##.##..#..
        .#####..##
        .#..####.#
        #..#.#..#.
        ..####.###
        ..#.#.###.
        ...#.#.#.#

        Tile 2729:
        ...#.#.#.#
        ####.#....
        ..#.#.....
        ....#..#.#
        .##..##.#.
        .#.####...
        ####.#.#..
        ##.####...
        ##..#.##..
        #.##...##.

        Tile 3079:
        #.#.#####.
        .#..######
        ..#.......
        ######....
        ####.#..#.
        .#...#.##.
        #.#####.##
        ..#.###...
        ..#.......
        ..#.###...
      INPUT
    end
  end

  class Part2 < Part1
    MONSTER = <<-MONSTER
                  # 
#    ##    ##    ###
 #  #  #  #  #  #   
MONSTER

    def monster
      @monster ||= MONSTER.split("\n").each_with_index.flat_map do |row, y|
        row.chars.each_with_index.select { |c, x| c == "#" }.map { |_, x| [x, y] }
      end
    end

    def solution
      rx = real_image

      r = [
        rx,
        rotate(rx),
        rotate(rotate(rx)),
        rotate(rotate(rotate(rx))),
        flip(rx),
        rotate(flip(rx)),
        rotate(rotate(flip(rx))),
        rotate(rotate(rotate(flip(rx))))
      ].find { |r| monsters(r).any? }
      binding.pry unless r

      monsters(r).each do |x, y|
        monster.each do |mx, my|
          r[y + my][x + mx] = false
        end
      end

      r.flatten.count(&:itself)
    end

    def rotate(r)
      r.first.zip(*r[1..-1]).map(&:reverse)
    end

    def flip(r)
      r.map(&:reverse)
    end

    def monsters(r)
      m = []
      (0..r.length - 21).each do |x|
        (0..r.length - 4).each do |y|
          if monster.all? { |mx, my| r[my + y][mx + x] }
            m << [x, y]
          end
        end
      end
      m
    end

    def real_image
      i = solved_image
      tiles = i.map.map do |index, tile|
        tile.trim.data
      end
      tiles.each_slice(size).flat_map { |slice|
        slice[0].zip(*slice[1..-1]).map(&:flatten)
      }
    end

    def px(r)
      puts(
        r.map do |row|
          row.map {|x| x ? "#" : "." }.join
        end.join("\n")
      )
    end
  end

  class Part2Test < Minitest::Test
    def test_sample_input
      assert_equal 273, Part2.new(<<~INPUT).solution
        Tile 2311:
        ..##.#..#.
        ##..#.....
        #...##..#.
        ####.#...#
        ##.##.###.
        ##...#.###
        .#.#.#..##
        ..#....#..
        ###...#.#.
        ..###..###

        Tile 1951:
        #.##...##.
        #.####...#
        .....#..##
        #...######
        .##.#....#
        .###.#####
        ###.##.##.
        .###....#.
        ..#.#..#.#
        #...##.#..

        Tile 1171:
        ####...##.
        #..##.#..#
        ##.#..#.#.
        .###.####.
        ..###.####
        .##....##.
        .#...####.
        #.##.####.
        ####..#...
        .....##...

        Tile 1427:
        ###.##.#..
        .#..#.##..
        .#.##.#..#
        #.#.#.##.#
        ....#...##
        ...##..##.
        ...#.#####
        .#.####.#.
        ..#..###.#
        ..##.#..#.

        Tile 1489:
        ##.#.#....
        ..##...#..
        .##..##...
        ..#...#...
        #####...#.
        #..#.#.#.#
        ...#.#.#..
        ##.#...##.
        ..##.##.##
        ###.##.#..

        Tile 2473:
        #....####.
        #..#.##...
        #.##..#...
        ######.#.#
        .#...#.#.#
        .#########
        .###.#..#.
        ########.#
        ##...##.#.
        ..###.#.#.

        Tile 2971:
        ..#.#....#
        #...###...
        #.#.###...
        ##.##..#..
        .#####..##
        .#..####.#
        #..#.#..#.
        ..####.###
        ..#.#.###.
        ...#.#.#.#

        Tile 2729:
        ...#.#.#.#
        ####.#....
        ..#.#.....
        ....#..#.#
        .##..##.#.
        .#.####...
        ####.#.#..
        ##.####...
        ##..#.##..
        #.##...##.

        Tile 3079:
        #.#.#####.
        .#..######
        ..#.......
        ######....
        ####.#..#.
        .#...#.##.
        #.#####.##
        ..#.###...
        ..#.......
        ..#.###...
      INPUT
    end
  end
end

