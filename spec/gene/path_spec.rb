require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def test_data
  @test_data ||= Gene::Parser.parse <<-INPUT
    (root
      ^k01 'k01 value'
      ^k02 'k02 value'

      (child
        ^k11 'child1 k11 value'
        ^k12 'child1 k12 value'

        (grand_child
          ^k21 'child1 k11 value'
          ^k22 'child1 k12 value'
          'test 1'
          'test 2'
        )
      )

      (child
        ^k11 'child2 k11 value'
        ^k12 'child2 k12 value'

        (grand_child
          ^k21 'grand child2 k21 value'
          ^k22 'grand child2 k22 value'
          'test 3'
          'test 4'
        )

        (grand_child
          ^k21 'grand child3 k21 value'
          ^k22 'grand child3 k22 value'
          'test 5'
          'test 6'
        )
      )

      "third"
      "fourth"
    )
  INPUT
end

describe Gene::Path do
  tests = [
    ["", ["k01"], test_data.get("k01")],
    ["", [2], test_data.get(2)],
  ]

  tests.each do |description, path, result|
    if description.empty?
      description = path.inspect
    end

    it "#{description} should work" do
      path = Gene::Path.new("k01")
      path.find_in(test_data).should == test_data.get("k01")
    end
  end
end
