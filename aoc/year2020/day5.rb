module AoC::Year2020::Day5
  RSpec.shared_context "sample input" do
    let(:input) {
      <<~INPUT
      INPUT
    }
  end

  class BoardingPass
    def initialize(partition)
      @row_steps = partition.chars[0..6]
      @col_steps = partition.chars[7..9]
    end

    def row
      arr = (0..127).to_a

      @row_steps.each do |step|
        if step == "F"
          arr = arr[0..arr.length/2-1]
        else
          arr = arr[arr.length/2..-1]
        end
      end

      arr.first
    end

    def column
      arr = (0..7).to_a

      @col_steps.each do |step|
        if step == "L"
          arr = arr[0..arr.length/2-1]
        else
          arr = arr[arr.length/2..-1]
        end
      end

      arr.first
    end

    def id
      row * 8 + column
    end
  end

  RSpec.describe BoardingPass do
    let(:pass1) { described_class.new("BFFFBBFRRR") }
    let(:pass2) { described_class.new("FFFBBBFRRR") }
    let(:pass3) { described_class.new("BBFFBBFRLL") }

    it "computes rows" do
      expect(pass1.row).to eq 70
      expect(pass2.row).to eq 14
      expect(pass3.row).to eq 102
    end

    it "computes columns" do
      expect(pass1.column).to eq 7
      expect(pass2.column).to eq 7
      expect(pass3.column).to eq 4
    end

    it "computes ids" do
      expect(pass1.id).to eq 567
      expect(pass2.id).to eq 119
      expect(pass3.id).to eq 820
    end
  end

  class Part1
    def initialize(input = real_input)
      @input = input
    end

    def solution
      boarding_passes.map(&:id).max
    end

    private

    attr_reader :input

    def boarding_passes
      input.split("\n").map {|x| BoardingPass.new(x) }
    end

    def real_input
      @input ||= File.read("aoc/year2020/day5.txt")
    end
  end

  RSpec.describe Part1 do
    let(:instance) { described_class.new }

    describe "#solution" do
      subject { instance.solution }

      include_context "sample input"

      it { is_expected.to eq 955 }
    end
  end

  class Part2 < Part1
    def solution
      h = boarding_passes.group_by(&:id)
      ((0..127*8+7).to_a - h.keys).each do |id|
        return id if h[id + 1] && h[id - 1]
      end
    end
  end

  RSpec.describe Part2 do
    let(:instance) { described_class.new(input) }

    describe "#solution" do
      subject { instance.solution }

      include_context "sample input"
    end
  end
end

