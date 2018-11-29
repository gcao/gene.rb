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
      5
      6
    )
  INPUT
end

describe Gene::Path do
  it "property key should work" do
    path = Gene::Path.new("k01")
    path.find_in(test_data).should == test_data.get("k01")
  end

  it "array index should work" do
    path = Gene::Path.new(0)
    path.find_in(test_data).should == test_data.get(0)
  end

  it "type should work" do
    path = Gene::Path.new(Gene::Path::TYPE)
    path.find_in(test_data).should == test_data.type
  end

  it "key+index should work" do
    path = Gene::Path.new(0, "k11")
    path.find_in(test_data).should == test_data.get(0).get("k11")
  end

  it "index+index should work" do
    path = Gene::Path.new(0, 0)
    path.find_in(test_data).should == test_data.get(0).get(0)
  end
end
