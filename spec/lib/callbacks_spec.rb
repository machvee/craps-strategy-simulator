require 'rails_helper'

class MoodSetter

  attr_reader :callbacks

  delegate :on, to: :callbacks

  def initialize(wild, thing)
    @wild = wild
    @thing = thing
    @callbacks = Callbacks.new([:freaked, :chilled])
  end

  def freak_out
    callbacks.invoke(:freaked, @wild)
  end

  def chillax
    callbacks.invoke(:chilled, @thing)
  end
end


describe Callbacks do
  before(:each) do
    @something = double("something", chilled: true, freaked: true, else_chilled: true)
    @wild = '42wild'
    @thing = '99thing'

    @mood = MoodSetter.new(@wild, @thing)

    @mood.on(:freaked) do |wild|
      expect(wild).to eq(@wild)
      @something.freaked
    end
    @mood.on(:chilled) do |thing|
      expect(thing).to eq(@thing)
      @something.chilled
    end
    @mood.on(:chilled) do |thing|
      expect(thing).to eq(@thing)
      @something.else_chilled
    end
  end

  it 'should freak' do
    expect(@something).to receive(:freaked)
    @mood.freak_out
  end

  it 'should chillax twice' do
    expect(@something).to receive(:chilled)
    expect(@something).to receive(:else_chilled)
    @mood.chillax
  end
end

