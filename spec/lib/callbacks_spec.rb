require 'rails_helper'

class MoodSetter

  attr_reader :callbacks

  delegate :on, to: :callbacks

  def initialize(something, wild)
    @callbacks = Callbacks.new([:freaked, :chilled], something, wild)
  end

  def freak_out
    callbacks.invoke(:freaked)
  end

  def chillax
    callbacks.invoke(:chilled)
  end
end


describe Callbacks do
  before(:each) do
    @something = double("something", chilled: true, freaked: true, else_chilled: true)
    @wild = 'wild'
    @mood = MoodSetter.new(@something, @wild)
    @mood.on(:freaked) do |something, wild|
      expect(wild).to eq(@wild)
      something.freaked
    end
    @mood.on(:chilled) do |something, wild|
      expect(wild).to eq(@wild)
      something.chilled
    end
    @mood.on(:chilled) do |something, wild|
      expect(wild).to eq(@wild)
      something.else_chilled
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

