require 'rails_helper'

describe Measure do
  before(:all) do
    @name = "laughs"
    @min = 0
    @max = 9
    @one = 1
    @last_3 = [1,7,5]
    @nums = [2,2,2,2,2,2,@max,@min,1] + @last_3
    @all = @nums + [@one]
    @sum = @all.inject(0) {|n,t| t += n}
    @avg = (@sum*1.0)/@all.length
  end

  before(:each) do
    @m = Measure.new(@name, history_length: 18)
    @m.add(@one).add(@nums)
  end

  it 'should have total' do
    expect(@m.total).to equal(@sum)
  end

  it 'should have a name' do
    expect(@m.name).to equal(@name)
  end

  it 'should have count' do
    expect(@m.count).to equal(@all.length)
  end

  it 'should have min' do
    expect(@m.min).to equal(@min)
    expect(@m.min).to equal(@all.min)
  end

  it 'should have max' do
    expect(@m.max).to equal(@max)
    expect(@m.max).to equal(@all.max)
  end

  it 'should have average' do
    expect(@m.average.to_f).to be_within(0.005).of(@avg)
  end

  it 'should have last' do
    expect(@m.last).to equal(@last_3.last)
  end

  it 'should have last 3' do
    expect(@m.last(3)).to eq(@last_3)
  end

  it 'should reset' do
    @m.reset
    expect(@m.count).to equal(0)
    expect(@m.min).to be(nil)
    expect(@m.max).to be(nil)
    expect(@m.total).to equal(0)
  end

  it "should tally and commit" do
    @m2 = Measure.new("bumps_in_the_night")
    t = [3,2,1,7]
    t.each do |n|
      n.times { @m2.incr }
      @m2.commit
    end
    expect(@m2.min).to equal(1)
    expect(@m2.max).to equal(7)
    expect(@m2.count).to equal(t.length)
  end

end

