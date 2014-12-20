require 'rails_helper'

describe Measure do
  before(:each) do
    @m = Measure.new("laughs", history_length: 18)
    @min = 0
    @max = 9
    @one = 1
    @last_3 = [1,7,5]
    @nums = [2,2,2,2,2,2,@max,@min,1] + @last_3
    @m.add(@one).add(@nums)
    @all = @nums + [@one]
  end

  it 'should have total' do
    expect(@m.total).to equal(@all.inject(0) {|n,t| t += n})
  end

  it 'should have count' do
    expect(@m.count).to equal(@all.length)
  end

  it 'should have min' do
    expect(@m.min).to equal(@min)
  end

  it 'should have max' do
    expect(@m.max).to equal(@max)
  end

  it 'should have last' do
    expect(@m.last).to equal(@last_3.last)
  end

  it 'should have last 3' do
    expect(@m.last(3)).to eq(@last_3)
  end

  it 'should inspect accurately' do
    expect(@m.inspect).to match(//)
  end

end

