require 'spec_helper'
require 'suse/toolkit/system_calls'

describe SUSE::Toolkit::SystemCalls do

  subject { Zypper }

  before do
    subject.send(:include, SUSE::Toolkit::SystemCalls)
  end

  describe '.call' do

    it 'should make a system call' do
      Object.should_receive(:system).with('date').and_return(true)
      subject.send(:call, 'date').should be_true
    end

    it 'should produce log output if call failed' do
      Object.should_receive(:system).with('date').and_return(false)
      Logger.should_receive(:error)
      subject.send(:call, 'date')
    end

    it 'doesn\'t actually change anything on the system if OPTIONS[:drymode] is set'

  end

  describe '.call_with_output' do
    it 'should make a system call and return output from system' do
      Object.should_receive(:'`').with('date').and_return("Thu Mar 13 12:22:51 CET 2014\n")
      subject.send(:call_with_output, 'date')
    end

    it 'doesn\'t actually change anything on the system if OPTIONS[:drymode] is set'

  end

end
