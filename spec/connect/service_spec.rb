require 'spec_helper'

describe SUSE::Connect::Service do

  subject { SUSE::Connect::Service }

  describe '.new' do

    let :sources_mock do
      { 'a' => 'foo', 'b' => 'bar' }
    end

    it 'assigns sources' do
      subject.new(sources_mock).sources.should eq(sources_mock)
    end

    it 'assigns norefresh' do
      subject.new(sources_mock, [], %w{ 1 2 3 }).norefresh.should eq(%w{1 2 3})
    end

    it 'assigns enabled' do
      subject.new(sources_mock, %w{ 1 2 3 }).enabled.should eq(%w{1 2 3})
    end

    it 'set enabled to empty array if not passed' do
      subject.new(sources_mock).enabled.should eq([])
    end

    it 'set norefresh to empty array if not passed' do
      subject.new(sources_mock).norefresh.should eq([])
    end

    # TODO: part of ruby 2.1
    xit 'raise if no sources passed' do
      expect { subject.new }.to raise_error ArgumentError, 'missing keyword: sources'
    end

  end
end
