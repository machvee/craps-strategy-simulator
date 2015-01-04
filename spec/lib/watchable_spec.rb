require 'rails_helper'

class Counter
  attr_reader :val
  
  def initialize(start=0)
    @val = start
  end

  def inc(incr=1)
    @val += incr
  end

  def reset(start=0)
    @val = start
  end
end

class Life
  attr_reader :time
  attr_reader :name
  attr_reader :status

  class Time
    include Watchable

    attr_reader :counter

    SCHOOL_AGE=5..18
    TEENAGER=13..19
    ADULTHOOD=21
    OLD_FART=64
    CENTURY=100

    def initialize
      @counter = Counter.new

      watcher(:school_age) { |time| SCHOOL_AGE.include?(time.current) }
      watcher(:teenager)   { |time| TEENAGER.include?(time.current) }
      watcher(:adulthood)  { |time| time.current == ADULTHOOD }
      watcher(:old)        { |time| time.current > OLD_FART }
      watcher(:centurion)  { |time| time.current == CENTURY }
    end

    def current
      counter.val
    end

    def birthday
      counter.inc
      check_watchers
    end

    def reborn
      counter.reset
      clear_watchers
    end
  end

  def initialize(name)
    @name = name
    @time = Time.new

    time.watch_for(:always, :birthday) do
      bake_a_cake("Happy Birthday, #{name}")
    end
  
    time.watch_for(:school_age, :bus_reminder) do
      milestone "Catch the Bus!"
    end

    time.watch_for_once(:school_age, :take_picture_at_bus) do
      milestone "First Day at School!"
    end

    time.watch_for(:teenager, :just_say_no) do
      milestone "Don't do drugs"
    end

    time.watch_for(:adulthood, :kick_em_out) do
      milestone "Grown-up"
    end

    time.watch_for(:old, :diet_change) do
      milestone "start buying oatmeal"
    end

    time.watch_for(:centurion, :call_willard) do
      milestone "get on Today Show"
    end
  end

  def birthday
    time.birthday
  end

  def drop_out
    time.stop_watching(:school_age, :bus_reminder)
  end

  def milestone(str)
    @status = str
  end

  def bake_a_cake(writing)
  end

  def reborn
    time.reborn
  end
end

class School
  attr_reader :attendees

  def initialize
    @attendees = []
  end

  def enroll(student)
    @attendees << student.name
    student.time.watch_for(:school_age, :truancy) do
      raise "call parents" if truant?(student.name)
    end
  end

  def truant?(student_name)
    !attendees.include?(student_name)
  end
end

describe Watchable do
  before(:each) do
    @dave = Life.new("dave")
    @school = School.new
    @school.enroll(@dave)
  end

  it "should be not school age before age 5" do
    expect(@dave).not_to receive(:milestone)
    expect(@school).not_to receive(:truant?)
    expect(@dave).to receive(:bake_a_cake).exactly(4).times
    4.times {@dave.birthday}
  end

  it "should be school age after age 5 up to 18 and keep calling milestone" do
    cnt = 11
    expect(@dave).to receive(:milestone).with(/Bus/).exactly((cnt-5)+1).times
    expect(@dave).to receive(:milestone).with(/First Day/).once
    expect(@school).to receive(:truant?).with(@dave.name).exactly((cnt-5)+1).times
    expect(@dave).to receive(:bake_a_cake).exactly(cnt).times
    cnt.times {@dave.birthday}
  end

  it "should be school age and teen age from 13 to 16" do
    cnt = 16
    expect(@dave).to receive(:milestone).with(/Bus/).at_least :once
    expect(@dave).to receive(:milestone).with(/First Day/).once
    expect(@school).to receive(:truant?).with(@dave.name).at_least :once
    expect(@dave).to receive(:milestone).with(/drugs/).exactly((cnt-13)+1).times
    expect(@dave).to receive(:bake_a_cake).exactly(cnt).times
    cnt.times {@dave.birthday}
  end

  it "should possibly be a drop-out and no longer have to catch a bus but still be not doing drugs" do
    cnt = 13
    expect(@dave).to receive(:milestone).with(/Bus/).at_least :once
    expect(@dave).to receive(:milestone).with(/First Day/).once
    expect(@school).to receive(:truant?).with(@dave.name).exactly(9).times
    expect(@dave).to receive(:milestone).with(/drugs/).once
    expect(@dave).to receive(:bake_a_cake).exactly(cnt).times
    cnt.times {@dave.birthday}

    @dave.drop_out

    new_cnt = 5
    expect(@dave).not_to receive(:milestone).with(/Bus/)
    expect(@dave).to receive(:milestone).with(/First Day/).never
    expect(@school).to receive(:truant?).with(@dave.name).exactly(5).times
    expect(@dave).to receive(:milestone).with(/drugs/).exactly(5).times
    expect(@dave).to receive(:bake_a_cake).exactly(new_cnt).times
    new_cnt.times {@dave.birthday}
  end

  it "should raise if a watcher name is invalid" do
    bad_name = :invalid_watcher_name
    expect {@dave.time.watch_for(bad_name, :my_watcher)}.to raise_error(RuntimeError, "invalid watcher #{bad_name}")
  end

  it "should grow-up get old" do
    cnt = 67
    expect(@dave).to receive(:milestone).with(/Bus/).at_least :once
    expect(@dave).to receive(:milestone).with(/First Day/).once
    expect(@school).to receive(:truant?).with(@dave.name).at_least :once
    expect(@dave).to receive(:milestone).with(/drugs/).at_least :once
    expect(@dave).to receive(:milestone).with(/Grown-up/).once
    expect(@dave).to receive(:milestone).with(/start buying/).exactly(cnt-64).times
    expect(@dave).to receive(:bake_a_cake).exactly(cnt).times
    cnt.times {@dave.birthday}
  end

  it "should get old and be reborn with no milestones" do
    cnt = 105
    expect(@dave).to receive(:milestone).with(/Bus/).at_least :once
    expect(@dave).to receive(:milestone).with(/First Day/).once
    expect(@school).to receive(:truant?).with(@dave.name).at_least :once
    expect(@dave).to receive(:milestone).with(/drugs/).at_least :once
    expect(@dave).to receive(:milestone).with(/Grown-up/).once
    expect(@dave).to receive(:milestone).with(/start buying/).at_least :once
    expect(@dave).to receive(:milestone).with(/Today Show/).once
    expect(@dave).to receive(:bake_a_cake).exactly(cnt).times
    cnt.times {@dave.birthday}
    @dave.reborn
    expect(@dave).not_to receive(:milestone)
    expect(@dave).not_to receive(:bake_a_cake)
    cnt.times {@dave.birthday}
  end

  it "should handle custom watcher/callback combo" do
    @years_of_college = 0
    @dave.time.watch_it(:college, Proc.new {|time| (18..21).include?(time.current) }) do 
      @years_of_college += 1
    end
    17.times {
      @dave.birthday
      expect(@years_of_college).to be(0)
    }
    4.times { |i|
      @dave.birthday
      expect(@years_of_college).to be(i+1)
    }
    @dave.birthday
    @dave.birthday
    @dave.birthday
    expect(@years_of_college).to be(4)
  end
end

